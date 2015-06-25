/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentTreeController
 * Description: T-373690: Account Segmentation: Hierarchy Page.
 *
 * Created Date: March 30th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * 10th April, 2015         Naresh Kr Ojha              T-377399: Updated class to use Opp.Amount_Corp__c instead of opp.Amount
 * 19th June,2015           Noopur                      Modified the class to remove unused methods
 ======================================================================*/
public class AccountSegmentTreeController {
    
      public String currentAccountId {get;set;}

    //Declare variables
    public String accId;
    public Set<Id> setAccRelBUIds;
    public List<ObjectStructureMap> asm ;
    public Map<String, ObjectStructureMap> masm;
    public List<Integer> maxLevel;
    
   // public List<BusinessGroup> BusinessGroupList; //To replace asm;
   // public Map<String, BusinessGroup> gblBU_BusinessGroupMap; //To replace masm: nojha
    
   // private BusinessGroup buGroup;
    public static boolean isCalled; 
    
    public String currentUserCurrency {get;set;}
       
    public static CurrencyUtility currencyUtil;
    /**
    * Contructor 
    */
    public AccountSegmentTreeController() {
        this.asm = new List<ObjectStructureMap>{};
        this.masm = new Map<String, ObjectStructureMap>{};
        this.maxLevel = new List<Integer>{};
      //  gblBU_BusinessGroupMap = new Map<String, BusinessGroup>();
        isCalled = false;
        currentUserCurrency = userinfo.getDefaultCurrency();
    }
    
    /**
    * Allow page to set the current ID
    */
    public void setaccId( String cid ){
        accId = cid;
    }

    /**
    * Return ObjectStructureMap to page
    * @return asm
    */
    public List<ObjectStructureMap> getObjectStructure(){
        asm.clear();
        setAccRelBUIds = new Set<Id>();
        currencyUtil = new CurrencyUtility();
        if ( accId == null  ) {
            
            //accId = System.currentPageReference().getParameters().get( 'id' );
            try{
                accId = System.currentPageReference().getParameters().get( 'id' );
                setAccRelBUIds = (new Map<Id, Account_Segment__c>([select id from Account_Segment__c where Account__c=:accId])).keyset();
                
            }catch(Exception ex){
              system.debug('#############Exception#############'+ex);
              ApexLogHandler.createLogAndSave('AccountSegmentTreeController','getObjectStructure', ex.getStackTraceString(), ex);
              
            }
        }
        
        if( !isCalled) {
            asm = formatObjectStructure( setAccRelBUIds );
            isCalled = true;
        }
        system.debug('#############asm#############'+asm);
        return asm;
    }

    /**
    * Query Account from top down to build the ObjectStructureMap
    * @param accId
    * @return asm
    */
    //public ObjectStructureMap[] formatObjectStructure( String accId ){
    public ObjectStructureMap[] formatObjectStructure( Set<Id> setAccRelBUIds){
         
        
        List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
        masm.clear();

        //Change below
        List<Account_Segment__c> lstBUs            = new List<Account_Segment__c>{};
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
                lstBUs = [select id,Account__c,Parent_Account_Segment__c,CurrencyIsoCode,Segment__c,Segment__r.Value__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c from Account_Segment__c WHERE id IN : CurrentParent ORDER BY Name];
            } 
            else {
                //Change below      
                lstBus = [select id,Account__c,Parent_Account_Segment__c,Segment__c,CurrencyIsoCode,Segment__r.Value__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c from Account_Segment__c WHERE Parent_Account_Segment__c IN : CurrentParent ORDER BY Name];
            }
            System.debug('[*****CurrentParent****]'+CurrentParent);
            if( lstBUs.size() == 0 ){
                endOfStructure = true;
            }
            else{
                currentParent.clear();
                for ( Integer i = 0 ; i < lstBUs.size(); i++ ){
                    //Change below
                    Account_Segment__c buRec = lstBUs[i];
                    
                    if ( level > 0 ) {
                        String nodeIdFromMap = NodeList.get( buRec.Parent_Account_Segment__c );
                        String lastValue = nodeIdFromMap.lastIndexOf('.') != -1 ? nodeIdFromMap.subString(nodeIdFromMap.lastIndexOf('.')+1,nodeIdFromMap.length() -1) : '';
                        nodeId = lastValue != '' ? NodeList.get( buRec.Parent_Account_Segment__c ) +'.'+lastValue : NodeList.get( buRec.Parent_Account_Segment__c )+'.' +  String.valueOf( i );
                    }
                    else {
                        nodeId = String.valueOf( i );
                    }
                    masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, buRec ) );
                    currentParent.add( buRec.id );
                    nodeList.put( buRec.id, nodeId);
                    
                    nodeSortList.add( nodeId );
                }
                lstBUs.clear();
                
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
    */
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
    */
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
    */
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
    */
    public String GetTopElement( String objId ){
        system.debug('###########objId##############'+objId);
        Boolean top = false;
        try
        {
            while ( !top ) {
                //Change below
                Account_Segment__c buRec = [select id,Account__c,Parent_Account_Segment__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c
                                            from Account_Segment__c
                                            where Id =: objId limit 1];
                //[ Select a.Id, a.Parent_Account_Segment__c From Account a where a.Id =: objId limit 1 ];
                
                if ( buRec.Parent_Account_Segment__c != null ) {
                    objId = buRec.Parent_Account_Segment__c;
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
          ApexLogHandler.createLogAndSave('AccountSegmentTreeController','GetTopElement', ex.getStackTraceString(), ex);
          
        }
        return objId ;
    }
    
   
    /**
    * Wrapper class
    */
    public with sharing class ObjectStructureMap{

        public String nodeId;
        public Boolean[] levelFlag = new Boolean[]{};
        public Boolean[] closeFlag = new Boolean[]{};
        public String nodeType;
        public Boolean currentNode;
        public Double clsWonAmtPCU {get;set;}
        public Double pipeLnAmtPCU {get;set;}
        
        /**
        * @Change this to your sObject
        */
        public Account_Segment__c buRec {
            
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
        */
        public Account_Segment__c getBURec() { return buRec; }
        
        public void setnodeId( String n ) { this.nodeId = n; }
        public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
        public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
        public void setnodeType( String nt ) { this.nodeType = nt; }
        public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }

        /**
        * @Change this to your sObject
        */
        public void setBU( Account_Segment__c buRec ) { this.buRec = buRec; }

        /**
        * @Change the parameters to your sObject
        */
        public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, Account_Segment__c buRec ){
            
            this.nodeId         = nodeId;
            this.levelFlag      = levelFlag; 
            this.closeFlag      = closeFlag;
            this.nodeType       = nodeType;
            this.currentNode    = currentNode;

            //Change this to your sObject  
            this.buRec = buRec;
            this.clsWonAmtPCU = currencyUtil.convertCurrency(buRec.CurrencyIsoCode,
                                                        buRec.Total_Won__c,
                                                        UserInfo.getDefaultCurrency());
           this.pipeLnAmtPCU = currencyUtil.convertCurrency(buRec.CurrencyIsoCode,
                                                        buRec.Total_Open_Pipeline__c,
                                                        UserInfo.getDefaultCurrency());
        }
    }
    
    /*************************************************************************
    * T-267045 : to remove Account_Segment__c 
    *************************************************************************/
    
    // Naresh as per T-267045
    private static Boolean checkQueryLimits() {
       if (Integer.valueOf(Limits.getQueries()) >= 80) {
        return true;
      }
      return false;
    }

    //Inner class to hold information of BURelationship
 /*   public with sharing class BusinessGroup {
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
        this.pipeLineAmount = pipeLnAmt == null ? 0 : Double.valueOf(pipeLnAmt);
        this.parent = parentName;
      }
    }*/
    
    //Gets client status of the given criteria   
 /*  public String getClientType(Boolean hasOrder, Date contractEndDate){
    
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
  
    
      //method to return the parentName on basis of User.Business_Unit__c
   /*   private String returnParentName (String businessUnit) {
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
      }*/
    
}