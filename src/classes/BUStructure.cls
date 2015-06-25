/**  Copyright (c) 2008, Matthew Friend, Sales Engineering, Salesforce.com Inc.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
*  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
*  Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
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
*/

/**=====================================================================
 * Appirio, Inc
 * Name: BUStructure
 * Description: [Task# with multi-line description here]
 * Created Date: [MM/DD/YYYY]
 * Created By: [FirstName LastName] (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]               [FirstName LastName]     [Short description for changes]
 =====================================================================*/
public with sharing class BUStructure{

    /*//Declare variables
    public String accId;
    public Set<Id> setAccRelBUIds;
    public List<ObjectStructureMap> asm ;
    public Map<String, ObjectStructureMap> masm;
    public List<Integer> maxLevel;
    
    public Map<ID, Opportunity> opptyMap;
    public List<BusinessGroup> BusinessGroupList; //To replace asm;
    public Map<String, BusinessGroup> gblBU_BusinessGroupMap; //To replace masm: nojha
    
    private BusinessGroup buGroup;*/
    
    /**
    * Contructor
    
    public BUStructure() {
        this.asm = new List<ObjectStructureMap>{};
        this.masm = new Map<String, ObjectStructureMap>{};
        this.maxLevel = new List<Integer>{};
        opptyMap = new Map<ID, Opportunity>();
        gblBU_BusinessGroupMap = new Map<String, BusinessGroup>();
    }
    
    /**
    * Allow page to set the current ID
    
    public void setaccId( String cid ){
        accId = cid;
    }

    /**
    * Return ObjectStructureMap to page
    * @return asm
    
    public List<ObjectStructureMap> getObjectStructure(){
        asm.clear();
        setAccRelBUIds = new Set<Id>();
        if ( accId == null ) {
            //accId = System.currentPageReference().getParameters().get( 'id' );
            try{
                accId = System.currentPageReference().getParameters().get( 'id' );
                setAccRelBUIds = (new Map<Id, BU_Relationship__c>([select id from BU_Relationship__c where Account__c=:accId])).keyset();
            }catch(Exception ex){
              system.debug('#############Exception#############'+ex);
              ApexLogHandler.createLogAndSave('BUStructure','getObjectStructure', ex.getStackTraceString(), ex);
              
            }
        }
        

        asm = formatObjectStructure( setAccRelBUIds );
        system.debug('#############asm#############'+asm);
        return asm;
    }

    /**
    * Query Account from top down to build the ObjectStructureMap
    * @param accId
    * @return asm
    *
    //public ObjectStructureMap[] formatObjectStructure( String accId ){
    public ObjectStructureMap[] formatObjectStructure( Set<Id> setAccRelBUIds){
    
        List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
        masm.clear();

        //Change below
        List<BU_Relationship__c> lstBUs            = new List<BU_Relationship__c>{};
        List<ID> currentParent      = new List<ID>{};
        Map<ID, String> nodeList    = new Map<ID, String>{};
        List<String> nodeSortList   = new List<String>{};
        List<Boolean> levelFlag     = new List<Boolean>{};
        List<Boolean> closeFlag     = new List<Boolean>{};
        String nodeId               = '0';
        String nodeType             = Constants.NODE_TYPE_CHILD ;
        Integer count               = 0;
        Integer level               = 0;
        Boolean endOfStructure      = false;
        
        //Find highest level obejct in the structure
        //currentParent.add( GetTopElement( accId ) );
        for(Id buRecId: setAccRelBUIds)
            currentParent.add( GetTopElement( buRecId) );
        
        system.debug('##############CurrentParent###############'+CurrentParent);
        //Loop though all children
        while ( !endOfStructure ){

            if( level == 0 ){
                //Change below     
                lstBUs = [select id,Account__c,Parent__c,Opportunity_Amount__c,Global_Line_of_Business_or_BU__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c from BU_Relationship__c WHERE id IN : CurrentParent ORDER BY Name];
                //[ SELECT a.Type, a.Site, a.Parent__c, a.OwnerId, a.Name, a.Industry, a.Id FROM Account a WHERE a.id IN : CurrentParent ORDER BY a.Name ];
            } 
            else {
                //Change below      
                lstBus = [select id,Account__c,Parent__c,Opportunity_Amount__c,Global_Line_of_Business_or_BU__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c from BU_Relationship__c WHERE Parent__c IN : CurrentParent ORDER BY Name];
                //[ SELECT a.Type, a.Site, a.Parent__c, a.OwnerId, a.Name, a.Industry, a.Id FROM Account a WHERE a.Parent__c IN : CurrentParent ORDER BY a.Name ];
            }
            System.debug('[*****CurrentParent****]'+CurrentParent);
            if( lstBUs.size() == 0 ){
                endOfStructure = true;
            }
            else{
                currentParent.clear();
                for ( Integer i = 0 ; i < lstBUs.size(); i++ ){
                    //Change below
                    BU_Relationship__c buRec = lstBUs[i];
                    nodeId = ( level > 0 ) ? NodeList.get( buRec.Parent__c )+'.'+String.valueOf( i ) : String.valueOf( i );
                    masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, buRec ) );
                    currentParent.add( buRec.id );
                    nodeList.put( buRec.id, nodeId);
                    System.debug('[**nodeId**]'+nodeId);
                    nodeSortList.add( nodeId );
                }
                
                maxLevel.add( level );                
                level++;
            }
            // Naresh Added as per T-267045
            if (checkQueryLimits()) {
              break;
            }
        }
        
        
        
        //Account structure must now be formatted
        NodeSortList.sort();
        for( Integer i = 0; i < NodeSortList.size(); i++ ){
            List<String> pnl = new List<String> {};
            List<String> cnl = new List<String> {};
            List<String> nnl = new List<String> {};
            
            if ( i > 0 ){
                String pn   = NodeSortList[i-1];
                pnl         = pn.split( '\\.', -1 );
            }

            String cn   = NodeSortList[i];
            cnl         = cn.split( '\\.', -1 );

            if( i < NodeSortList.size()-1 ){
                String nn = NodeSortList[i+1];
                nnl = nn.split( '\\.', -1 );
            }
            
            ObjectStructureMap tasm = masm.get( cn );
            if ( cnl.size() < nnl.size() ){
                //Parent
                tasm.nodeType = ( isLastNode( cnl ) ) ? Constants.NODE_TYPE_PARENT_END : Constants.NODE_TYPE_PARENT;
            }
            else if( cnl.size() > nnl.size() ){
                tasm.nodeType   = Constants.NODE_TYPE_CHILD_END;
                tasm.closeFlag  = setcloseFlag( cnl, nnl, tasm.nodeType );
            }
            else{
                tasm.nodeType = Constants.NODE_TYPE_CHILD;
            }
            
            tasm.levelFlag = setlevelFlag( cnl, tasm.nodeType ); 
            
            //Change below
            if ( tasm.buRec.id == accId ) {
                tasm.currentNode = true;
            }
            asm.add( tasm );
        }
        
        //MIrfan, 281013
        if( lstBUs.size()> 0 ) {
            asm[0].nodeType             = Constants.NODE_TYPE_START;
            asm[asm.size()-1].nodeType  = Constants.NODE_TYPE_END;
        }
        return asm;
    }
    
    /**
    * Determin parent elements relationship to current element
    * @return flagList
    *
    public List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType ){
        
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode   = '';
        String workNode     = '';
        Integer cn          = 0;
        
        for( Integer i = 0; i < nodeElements.size() - 1; i++ ){
            cn = Integer.valueOf( nodeElements[i] );
            cn++;
            searchNode  = workNode + String.valueOf( cn );
            workNode    = workNode + nodeElements[i] + '.';
            if ( masm.containsKey( searchNode ) ){
                flagList.add( true );
            }
            else {
                flagList.add( false );
            }
        }
        
        return flagList;
    }
    
    /**
    * Determin if the element is a closing element
    * @return flagList
    *
    public List<Boolean> setcloseFlag( List<String> cnl, List<String> nnl, String nodeType ){
        
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode   = '';
        String workNode     = '';
        Integer cn          = 0;
        
        for( Integer i = nnl.size(); i < cnl.size(); i++ ){
            flagList.add( true );
        }
        
        return flagList;
    }
    
    /**
    * Determin if Element is the bottom node  
    * @return Boolean
    *
    public Boolean isLastNode( List<String> nodeElements ){
        
        String searchNode   = '';
        Integer cn          = 0;
        
        for( Integer i = 0; i < nodeElements.size(); i++ ){
            if ( i == nodeElements.size()-1 ){
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
    
    /**
    * Find the tom most element in Heirarchy  
    * @return objId
    *
    public String GetTopElement( String objId ){
        system.debug('###########objId##############'+objId);
        Boolean top = false;
        try
        {
            while ( !top ) {
                //Change below
                BU_Relationship__c buRec = [select id,Account__c,Parent__c,Opportunity_Amount__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c
                                            from BU_Relationship__c
                                            where Id =: objId limit 1];
                //[ Select a.Id, a.Parent__c From Account a where a.Id =: objId limit 1 ];
                
                if ( buRec.Parent__c != null ) {
                    objId = buRec.Parent__c;
                }
                else {
                    top = true;
                }
              // Naresh As per T-267045
              if (checkQueryLimits()) {
                break;
              }
            }
        }catch(Exception ex){
          System.debug('######################Exception###############'+ex);
          ApexLogHandler.createLogAndSave('BUStructure','GetTopElement', ex.getStackTraceString(), ex);
          
        }
        return objId ;
    }
    
   
    /**
    * Wrapper class
    *
    public with sharing class ObjectStructureMap{

        public String nodeId;
        public Boolean[] levelFlag = new Boolean[]{};
        public Boolean[] closeFlag = new Boolean[]{};
        public String nodeType;
        public Boolean currentNode;
        
        /**
        * @Change this to your sObject
        *
        public BU_Relationship__c buRec {
            
            //If Open or Won are Null then populate 0 value.
            get {
                if(buRec.Total_Won__c==null)
                    buRec.Total_Won__c=0;
                if(buRec.Total_Open_Pipeline__c==null)
                    buRec.Total_Open_Pipeline__c=0; 
                return buRec;       
            }
            
            set;}
        
        public String getnodeId() { return nodeId; }
        public Boolean[] getlevelFlag() { return levelFlag; }
        public Boolean[] getcloseFlag() { return closeFlag; }
        public String getnodeType() { return nodeType; }
        public Boolean getcurrentNode() { return currentNode; }
        
        public Integer childCount { set;get; }


        /**
        * @Change this to your sObject
        *
        public BU_Relationship__c getBURec() { return buRec; }
        
        public void setnodeId( String n ) { this.nodeId = n; }
        public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
        public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
        public void setnodeType( String nt ) { this.nodeType = nt; }
        public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }

        /**
        * @Change this to your sObject
        *
        public void setBU( BU_Relationship__c buRec ) { this.buRec = buRec; }

        /**
        * @Change the parameters to your sObject
        *
        public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, BU_Relationship__c buRec ){
            
            this.nodeId         = nodeId;
            this.levelFlag      = levelFlag; 
            this.closeFlag      = closeFlag;
            this.nodeType       = nodeType;
            this.currentNode    = currentNode;

            //Change this to your sObject  
            this.buRec = buRec;
        }
    }
    
    /*************************************************************************
    * T-267045 : to remove BU_Relationship__c 
    *************************************************************************
    
    // Naresh as per T-267045
    private static Boolean checkQueryLimits() {
       if (Integer.valueOf(Limits.getQueries()) >= 80) {
        return true;
      }
      return false;
    }

    //Inner class to hold information of BURelationship
    public with sharing class BusinessGroup {
      public String nodeName; //Same as BU/GBL on related record.
      public String clientType;//Relationship type on BURelationship__c
      public Double closedWonAmount; //Total Won on BUR
      public Double pipeLineAmount; //Total Open Pipeline on BUR
      public String parent; //name of the Parent GLB
      
      
      //Construct
      public BusinessGroup(String ndName, String clntType, String clsWonAmt, String pipeLnAmt, String parentName) {
        this.nodeName = ndName;
        this.clientType = clntType;
        this.closedWonAmount = Double.valueOf(closedWonAmount);
        this.pipeLineAmount = Double.valueOf(pipeLnAmt);
        this.parent = parentName;
      }
    }
    
    //Gets client status of the given criteria   
    public String getClientType(Boolean hasOrder, Date contractEndDate){
    
      if(contractEndDate == NULL) {
        return Constants.BU_RELATIONSHIP_TYPE_PROSPECT;
      }

      if(contractEndDate != null && contractEndDate > System.today().addYears(-1) && hasOrder) {
        return Constants.BU_RELATIONSHIP_TYPE_CLIENT;
      }
    
      if(contractEndDate != null && contractEndDate < System.today().addYears(-1) && hasOrder) {
        return Constants.BU_RELATIONSHIP_TYPE_FORMER_CLIENT;
      }
      return Constants.BU_RELATIONSHIP_TYPE_PROSPECT;
    }
  
    //Calculate open pipline retrieval
    public void calculateOpenPipelineRetrieval () {
      List<Opportunity> allOpppties = new List<Opportunity>();
      Boolean hasOrders;
      for (Opportunity opp : [SELECT OwnerId, CloseDate, Amount, AccountId, Owner.Global_Business_Line__c,
                                 Owner.Business_Unit__c,  
                                 (SELECT Id, Name, Contract_End_Date__c, Contract_Start_Date__c, 
                                         Opportunity__c, Total__c FROM Orders__r) 
                              FROM Opportunity WHERE AccountId =: accId AND isClosed = false]) {
        opptyMap.put(opp.ID, opp);
        hasOrders = false;
        if (opp.Orders__r.size() > 0) {
          hasOrders = true;
        }
        //GBL Structure
        if (!String.isEmpty(opp.Owner.Global_Business_Line__c) && 
                                          !gblBU_BusinessGroupMap.containsKey(opp.Owner.Global_Business_Line__c)) {
          
          buGroup = new BusinessGroup(opp.Owner.Global_Business_Line__c, getClientType(hasOrders, opp.Contract_End_Date__c), 
                                       null, String.valueOf(opp.Amount), returnParentName(opp.Owner.Business_Unit__c));
          gblBU_BusinessGroupMap.put(opp.Owner.Global_Business_Line__c, buGroup);
        } else if (!String.isEmpty(opp.Owner.Global_Business_Line__c) && gblBU_BusinessGroupMap.containsKey(opp.Owner.Global_Business_Line__c)) {
          gblBU_BusinessGroupMap.get(opp.Owner.Global_Business_Line__c).pipeLineAmount += opp.Amount;
        }
        
        //BU Structure
        if (!String.isEmpty(opp.Owner.Business_Unit__c) && 
                                          !gblBU_BusinessGroupMap.containsKey(opp.Owner.Business_Unit__c)) {
          buGroup = new BusinessGroup(opp.Owner.Business_Unit__c, getClientType(hasOrders, opp.Contract_End_Date__c), null,
                                      String.valueOf(opp.Amount), returnParentName(opp.Owner.Business_Unit__c));
        } else if (!String.isEmpty(opp.Owner.Business_Unit__c) && gblBU_BusinessGroupMap.containsKey(opp.Owner.Business_Unit__c)) {
          gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmount += opp.Amount;
        }
      }
    }
    
    //Calculate Closed Won Retrieval
    public void calculateClosedWonRetrieval () {
      List<Order_Split__c> orderSplits = new List<Order_Split__c>();
      Set<ID> ownerIDs = new Set<ID>();
      Map<ID, User> ownerUserMap = new Map<ID, User>();
      
      for (Order_Split__c ordSplit : [SELECT ID, Split_Total__c, OwnerId, Order__c, 
                                             Order__r.Contract_End_Date__c, 
                                             Order__r.Account__c 
                                      FROM Order_Split__c 
                                      WHERE Order__r.Account__c =: accId]) {
        orderSplits.add(ordSplit);
        ownerIDs.add(ordSplit.OwnerId);
      }
      
      for (User u : [SELECT ID, Business_Unit__c, Global_Business_Line__c 
                     FROM User WHERE ID IN : ownerIDs]) {
        ownerUserMap.put(u.ID, u);
      }
      
      for (Order_Split__c ordSplit : orderSplits) {
        if (!ownerUserMap.containsKey(ordSplit.OwnerId) || ordSplit.Order__c == null) {
          continue;
        }
        User splitOwner = ownerUserMap.get(ordSplit.OwnerId);
        
        if (!String.isEmpty(splitOwner.Global_Business_Line__c) && 
                                          !gblBU_BusinessGroupMap.containsKey(splitOwner.Global_Business_Line__c)) {
          
          buGroup = new BusinessGroup(splitOwner.Global_Business_Line__c, 
                     getClientType(true, ordSplit.Order__r.Contract_End_Date__c), 
                                    String.valueOf(ordSplit.Split_Total__c), null, returnParentName(splitOwner.Business_Unit__c));
                                               
          gblBU_BusinessGroupMap.put(splitOwner.Global_Business_Line__c, buGroup);
        
        } else if (!String.isEmpty(splitOwner.Global_Business_Line__c) && 
                           gblBU_BusinessGroupMap.containsKey(splitOwner.Global_Business_Line__c)) {
          gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmount += ordSplit.Split_Total__c;
        }
        
        if (!String.isEmpty(splitOwner.Business_Unit__c) && 
                                          !gblBU_BusinessGroupMap.containsKey(splitOwner.Business_Unit__c)) {
          
          buGroup = new BusinessGroup(splitOwner.Business_Unit__c, 
                     getClientType(true, ordSplit.Order__r.Contract_End_Date__c), 
                                    String.valueOf(ordSplit.Split_Total__c), null, returnParentName(splitOwner.Business_Unit__c));
                                               
          gblBU_BusinessGroupMap.put(splitOwner.Business_Unit__c, buGroup);
        
        } else if (!String.isEmpty(splitOwner.Business_Unit__c) && 
                           gblBU_BusinessGroupMap.containsKey(splitOwner.Business_Unit__c)) {
          gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmount += ordSplit.Split_Total__c;
        }         
      }
    }
      //method to return the parentName on basis of User.Business_Unit__c
      private String returnParentName (String businessUnit) {
        if (businessUnit == null) {
          return null;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_CREDIT_SERVICES)
                    || businessUnit.containsIgnoreCase(' CS ')) {
          return Constants.USER_GBL_CREDIT_SERVICES;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_DECISION_ANALYTICS)
                    || businessUnit.containsIgnoreCase(' DA ')) {
          return Constants.USER_GBL_DECISION_ANALYTICS;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_INTERACTIVE)) {
          return Constants.USER_GBL_INTERACTIVE;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_LATAM_SERASA_SALES)) {
          return Constants.USER_GBL_LATAM_SERASA_SALES;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_MARKETING_SERVICES)
                    || businessUnit.containsIgnoreCase(' MS ')) {
          return Constants.USER_GBL_MARKETING_SERVICES;
        } else if (businessUnit.equalsIgnoreCase('UK&I CI&T')) {
        	return Constants.USER_GBL_MARKETING_SERVICES;
        }
        return null;
      }
    */
}