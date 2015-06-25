/**  Copyright (c) 2008, Matthew Friend, Sales Engineering, Salesforce.com Inc.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
*  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
*  Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
*  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
*  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
*  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
* To adapt this to anouther Object simply search for "Change" to go to the places 
* where the sObject and query must be changed
* 
* Installed by: Nathalie Le Guay (Appirio)
* Installed Date: March 04, 2014
* 
* Date Modified         Modified By                 Description of the update
* March 07, 2014        Nathalie Le Guay            Added details about related Address
* April 23, 2014        Jinesh Goyal                T-272518
* Aug 05th, 2014        Arpita Bose(Appirio)        T-286337: Refactoring of ARIA Classes
*/
public with sharing class ARIASupplementalPlanHierarchyController {
  //Declare variables
  public String currentId;
  public Set<Id> setAccRelPlanIds;
  public List<ObjectStructureMap> asm ;
  public Map<String, ObjectStructureMap> masm;
  public List<Integer> maxLevel;
  private Map<String, ARIA_Plan_Relationship__c> mapIdToARIAPlanRelationships;
  private List<ARIA_Plan__c> listARIAPlans = new List<ARIA_Plan__c>();
  private Map <String, Set<String>> mapParentToChildren = new Map <String, Set<String>>();
  private Map <String, String> mapChildToParent = new Map <String, String>();
  private String masterPlanId;
  
  //=====================================================================
  // Contructor
  //=====================================================================
  public ARIASupplementalPlanHierarchyController () {
    this.asm = new List<ObjectStructureMap>{};
    this.masm = new Map<String, ObjectStructureMap>{};
    this.maxLevel = new List<Integer>{};
  }
    
  //======================================================================
  // Method to allow page to set the current ID
  //======================================================================
  public void setcurrentId( String cid ){
     currentId = cid;
  }
  //=======================================================================
  // Method to return ObjectStructureMap to page
  // @return asm
  //=======================================================================
  public List<ObjectStructureMap> getObjectStructure(){
    asm.clear();
    system.debug('currentid '+currentId); 
    setAccRelPlanIds = new Set<Id>(); 
    mapIdToARIAPlanRelationships = new Map<String, ARIA_Plan_Relationship__c> ();
    if ( currentId == null ) {
      try{
        currentId = System.currentPageReference().getParameters().get( 'id' );
        mapIdToARIAPlanRelationships = (new Map<String, ARIA_Plan_Relationship__c>
                                        ([Select id ,Parent_Plan__c, Parent_Plan_Name__c, Parent_Plan_Number__c,
                                          Parent_Plan__r.Supplimental_Plan_Ind__c, Child_Plan__c, Child_Plan_Name__c , Child_Plan_Number__c
                                          from ARIA_Plan_Relationship__c  
                                          where id  in ( select ARIA_Plan_Relationship__c From ARIA_Billing_Account_Supplimental_Plans__c 
                                                         where ARIA_Billing_Account__c =:currentId
                                                         AND ARIA_Plan_Relationship__c != null)]));
       }catch(Exception ex){
       system.debug('#############Exception#############'+ex);
       ApexLogHandler.createLogAndSave('ARIASupplementalPlanTreeController1','getObjectStructure', ex.getStackTraceString(), ex);      
       }
    }
    //if map is Empty (no ARIA Billing Account Supplemental Plan exists)
    if (mapIdToARIAPlanRelationships.isEmpty()) {
      for(ARIA_Billing_Account__c ariaBA : [Select Master_Plan__c
                                            From ARIA_Billing_Account__c
                                            Where Id = :currentId]){
         setAccRelPlanIds.add(ariaBA.Master_Plan__c);
         masterPlanId = ariaBA.Master_Plan__c;
       }
    }
    system.debug ('+++++++++++ mapIdToARIAPlanRelationships '+mapIdToARIAPlanRelationships);
    //find the master plan
    for (ARIA_Plan_Relationship__c ariaPlanRel : mapIdToARIAPlanRelationships.values()) {
      if (ariaPlanRel.Parent_Plan__r.Supplimental_Plan_Ind__c == false) {
          masterPlanId = ariaPlanRel.Parent_Plan__c;
      }  
      setAccRelPlanIds.add(ariaPlanRel.Parent_Plan__c);
      setAccRelPlanIds.add(ariaPlanRel.Child_Plan__c);
      if (ariaPlanRel.Child_Plan__c != null && ariaPlanRel.Parent_Plan__c != null) {
          mapChildToParent.put (ariaPlanRel.Child_Plan__c, ariaPlanRel.Parent_Plan__c);
           
          if (!mapParentToChildren.containsKey(ariaPlanRel.Parent_Plan__c)){
              mapParentToChildren.put(ariaPlanRel.Parent_Plan__c, new Set<String> ());
          }
          mapParentToChildren.get(ariaPlanRel.Parent_Plan__c).add(ariaPlanRel.Child_Plan__c);
      }
    }
    for(ARIA_Plan__c ap : [SELECT Id, Plan_Name__c, Plan_Number__c, Supplimental_Plan_Ind__c
                           FROM ARIA_Plan__c
                           WHERE Id IN :setAccRelPlanIds]) {
      listARIAPlans.add(ap);
    }
        
    system.debug ('+++++++++++ mapParentToChildren '+mapParentToChildren);
    system.debug ('+++++++++++ listARIAPlans '+listARIAPlans);
    system.debug ('+++++++++++ masterPlanId '+masterPlanId);
    //return if master plan is not found
    if (masterPlanId ==  null) { 
    	 return null;
    } 
    //form the tree structure
    asm = formatObjectStructure(setAccRelPlanIds);
    system.debug('#############asm#############'+asm);
    return asm;  
  }
  //=====================================================================
  // Method to query Account from top down to build the ObjectStructureMap
  // @param currentId
  // @return asm
  //=====================================================================
  public ObjectStructureMap[] formatObjectStructure (Set<Id> setAccRelPlanIds) {
    List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
    masm.clear();
    //Change below
    List<ARIA_Plan__c> listARIAPlansToFormTree = new List<ARIA_Plan__c>{};
    Set<String> currentParent = new Set<String>{};
    Map<ID, String> nodeList = new Map<ID, String>{};
    List<String> nodeSortList = new List<String>{};
    List<Boolean> levelFlag = new List<Boolean>{};
    List<Boolean> closeFlag = new List<Boolean>{};
    String nodeId = '0';
    String nodeType = Constants.NODE_TYPE_CHILD ;
    Integer count = 0;
    Integer level = 0;
    Boolean endOfStructure = false;
        
    //Find highest level object in the structure
    currentParent.add(masterPlanId);
    system.debug('##############CurrentParent###############' +CurrentParent);
    //Loop though all children
    while (!endOfStructure){
      listARIAPlansToFormTree.clear(); //clear the list for each iteration
      if(level == 0 ){
      //adding the master plan 
        for (ARIA_Plan__c ap : listARIAPlans) {   
          if (ap.Id == masterPlanId) {
              system.debug('++++++++++ master in first loop '+ap);
              listARIAPlansToFormTree.add(ap) ;
          }
        }
      } 
      else {
      //Change below      
      //by parent..
        listARIAPlansToFormTree = [SELECT Id, Plan_Name__c, Plan_Number__c, Supplimental_Plan_Ind__c
                                   FROM ARIA_Plan__c
                                   WHERE Id IN : CurrentParent ORDER BY Name];
      }
      System.debug('[*****CurrentParent****]'+CurrentParent);
      if(listARIAPlansToFormTree.size() == 0 ){
         endOfStructure = true;
      }
      else{
         currentParent.clear();
         system.debug('++++++++++ listARIAPlansToFormTree '+listARIAPlansToFormTree);
         for ( Integer i = 0 ; i < listARIAPlansToFormTree.size(); i++ ){
            //Change below
            ARIA_Plan__c ariaPR = listARIAPlansToFormTree[i];
            nodeId = ( level > 0 ) ? NodeList.get( mapChildToParent.get(ariaPR.Id) )+'.'+String.valueOf( i ) : String.valueOf( i );
            masm.put( nodeId, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, ariaPR ) );
            if (mapParentToChildren.containsKey(ariaPR.Id)) {
               for (String s : mapParentToChildren.get(ariaPR.Id)) {
                  currentParent.add(s);
               }
            }
            nodeList.put( ariaPR.id, nodeId);
            System.debug('[**nodeId**]'+nodeId);
            nodeSortList.add( nodeId );
          }
          system.debug('++++++++++ nodeList '+nodeList);
          maxLevel.add( level );                
          level++;
      }
      //check query limit
      if (checkQueryLimits()) {
          break;
      }
    }   
    system.debug('++++++++++++++++++++ nodeList '+nodeList);
    system.debug('++++++++++++++++++++ NodeSortList '+NodeSortList);
        
    //Account structure must now be formatted
    NodeSortList.sort();
    for( Integer i = 0; i < NodeSortList.size(); i++ ){
       List<String> pnl = new List<String> {};
       List<String> cnl = new List<String> {};
       List<String> nnl = new List<String> {};   
       if (i > 0){
         String pn = NodeSortList[i-1];
         pnl = pn.split( '\\.', -1 );
       }

       String cn = NodeSortList[i];
       cnl = cn.split( '\\.', -1 );
       
       if (i < NodeSortList.size()-1){
         String nn = NodeSortList[i+1];
         nnl = nn.split( '\\.', -1 );
       }
            
       ObjectStructureMap tasm = masm.get( cn );
       if (cnl.size() < nnl.size()){
         //Parent
         tasm.nodeType = ( isLastNode( cnl ) ) ? Constants.NODE_TYPE_PARENT_END : Constants.NODE_TYPE_PARENT;
       }
       else if(cnl.size() > nnl.size()){
         tasm.nodeType   = Constants.NODE_TYPE_CHILD_END;
         tasm.closeFlag  = setcloseFlag( cnl, nnl, tasm.nodeType );
       }
       else{
         tasm.nodeType = Constants.NODE_TYPE_CHILD;
       }          
       
       tasm.levelFlag = setlevelFlag( cnl, tasm.nodeType ); 
            
       asm.add( tasm );
     }
     return asm;
  }
  //========================================================================
  // Method to determine parent elements relationship to current element
  // @return flagList
  //========================================================================
  public List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType ){
    List<Boolean> flagList = new List<Boolean>{};
    String searchNode = '';
    String workNode = '';
    Integer cn = 0;
    system.debug('  -->setlevelFlag  ' +1); 
    system.debug('  -->nodeElements  ' +nodeElements); 
    system.debug('  -->nodeType  ' +nodeType); 
        
    for(Integer i = 0; i < nodeElements.size() - 1; i++){
      cn = Integer.valueOf( nodeElements[i] );
      cn++;
      searchNode = workNode + String.valueOf( cn );
      workNode = workNode + nodeElements[i] + '.';
      if (masm.containsKey( searchNode )){
         flagList.add( true );
      }
      else {
         flagList.add( false );
      }
    }
    return flagList;
  }
    
  //========================================================================
  // Method to determine if the element is a closing element
  // @return flagList
  //========================================================================
  public List<Boolean> setcloseFlag( List<String> cnl, List<String> nnl, String nodeType ){
    List<Boolean> flagList = new List<Boolean>{};
    String searchNode = '';
    String workNode = '';
    Integer cn = 0;
        
    for(Integer i = nnl.size(); i < cnl.size(); i++){
        flagList.add( true );
    }
    return flagList;
  }
     
  //=======================================================================
  // Method to determine if Element is the bottom node  
  // @return Boolean
  //=======================================================================
  public Boolean isLastNode( List<String> nodeElements ){    
    String searchNode = '';
    Integer cn = 0;
        
    for(Integer i = 0; i < nodeElements.size(); i++){
      if (i == nodeElements.size()-1){
          cn = Integer.valueOf( nodeElements[i] );
          cn++;
          searchNode = searchNode + String.valueOf( cn );
      }
      else {
          searchNode = searchNode + nodeElements[i] + '.';
      }
    }
    if ( masm.containsKey( searchNode ) ){
       return false;
    }
    else{
       return true;
    }
  }
    
  //======================================================================
  // Method to find the top most element in Heirarchy  
  // @return objId
  //======================================================================
  public String GetTopElement1( String objId ){
    system.debug('###########objId1##############'+objId);
    Boolean top = false;
    while (!top) {
      ARIA_Plan_Relationship__c a = [ Select a.Id,  a.Parent_Plan__c,a.Supplimental_Plan_Ind__c 
                                      From ARIA_Plan_Relationship__c a 
                                      where a.Parent_Plan__c =: objId limit 1 ];
      if ( a.Supplimental_Plan_Ind__c  ) {
        return null;
      }
      else {
        top = true;
      }
    }
    return objId ;      
        
  }
    
  public String GetTopElement( String objId ){
    system.debug('###########objId##############'+objId);
    Boolean top = false;
    while (!top) {
      ARIA_Plan_Relationship__c a = [Select a.Id,  a.Parent_Plan__c,a.Supplimental_Plan_Ind__c 
                                     From ARIA_Plan_Relationship__c a 
                                     where a.id =: objId limit 1 ];
      if ( a.Supplimental_Plan_Ind__c  ) {
         return null;
      }
      else {
         top = true;
      }
    }
    return objId ;
  }
    
  //=======================================================================
  // Wrapper class
  //=======================================================================
  public with sharing class ObjectStructureMap{
    public String nodeId;
    public Boolean[] levelFlag = new Boolean[]{};
    public Boolean[] closeFlag = new Boolean[]{};
    public String nodeType;
    public Boolean currentNode;
    
    // @Change this to your sObject
    public ARIA_Plan__c account;
    
    public String getnodeId() { return nodeId; }
    public Boolean[] getlevelFlag() { return levelFlag; }
    public Boolean[] getcloseFlag() { return closeFlag; }
    public String getnodeType() { return nodeType; }
    public Boolean getcurrentNode() { return currentNode; }
    
    // @Change this to your sObject
    public ARIA_Plan__c getaccount() { return account; }
        
    public void setnodeId( String n ) { this.nodeId = n; }
    public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
    public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
    public void setnodeType( String nt ) { this.nodeType = nt; }
    public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }
    
    //@Change this to your sObject
    public void setaccount( ARIA_Plan__c a ) { this.account = a; }

    //@Change the parameters to your sObject
    public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , 
                               String nodeType, Boolean lastNode, Boolean currentNode, ARIA_Plan__c a ){
            
      this.nodeId = nodeId;
      this.levelFlag = levelFlag; 
      this.closeFlag = closeFlag;
      this.nodeType = nodeType;
      this.currentNode = currentNode;

      //Change this to your sObject  
      this.account = a;
     }
  }
  //=======================================================================
  // Method to check query limit in a thread
  //=======================================================================
  private static Boolean checkQueryLimits() {
    if (Integer.valueOf(Limits.getQueries()) >= 80) {
       return true;
    }
    return false;
  }
}