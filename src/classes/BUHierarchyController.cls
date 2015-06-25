/**=====================================================================
 * Appirio, Inc
 * Name: BUHierarchyController
 * Description: 
 * Created Date: 
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 
 =====================================================================*/
public with sharing class BUHierarchyController{

    //Declare variables
    public String accId;
    public Set<Id> setAccRelBUIds;
    public List<ObjectStructureMap> asm ;
    public Map<String, ObjectStructureMap> masm;
    public List<Integer> maxLevel;
    
    public Map<ID, Opportunity> opptyMap;
    //public List<BusinessGroup> BusinessGroupList; //To replace asm;
    public Map<String, BusinessGroup> gblBU_BusinessGroupMap; //To replace masm: nojha
    
    private BusinessGroup buGroup;
    //added by JG
    private List<BusinessGroup> lstBGs  = new List<BusinessGroup>{};
    //=====================================================================
    // Contructor
    //=====================================================================
    public BUHierarchyController() {
        this.asm = new List<ObjectStructureMap>{};
        this.masm = new Map<String, ObjectStructureMap>{};
        this.maxLevel = new List<Integer>{};
        opptyMap = new Map<ID, Opportunity>();
        gblBU_BusinessGroupMap = new Map<String, BusinessGroup>();
    }
    
    //=====================================================================
    // Allow page to set the current ID
    //=====================================================================
    public void setaccId( String cid ){
        accId = cid;
    }

    //=====================================================================
    // Return ObjectStructureMap to page
    // @return asm
    //=====================================================================
    public List<ObjectStructureMap> getObjectStructure(){
        asm.clear();
        //setAccRelBUIds = new Set<Id>();
        if ( accId == null ) {
            //accId = System.currentPageReference().getParameters().get( 'id' );
            try{
                accId = System.currentPageReference().getParameters().get( 'id' );
                //setAccRelBUIds = (new Map<Id, BU_Relationship__c>([select id from BU_Relationship__c where Account__c=:accId])).keyset();
            }catch(Exception ex){
              system.debug('#############Exception#############'+ex);
              ApexLogHandler.createLogAndSave('BUStructure','getObjectStructure', ex.getStackTraceString(), ex);
            }
        }
        system.debug('+++++++++++++++++testing accId '+accId);
        //calls to methods to populate data
        calculateOpenPipelineRetrieval();
        calculateClosedWonRetrieval();
        system.debug('+++++++++++++++++testing gblBU_BusinessGroupMap '+gblBU_BusinessGroupMap);
        //asm = formatObjectStructure( setAccRelBUIds );
        asm = formatObjectStructure( gblBU_BusinessGroupMap );
        system.debug('#############asm#############'+asm);
        return asm;
    }

    //====================================================================
    // Query Account from top down to build the ObjectStructureMap
    // @param accId
    // @return asm
    //====================================================================
    //public ObjectStructureMap[] formatObjectStructure( String accId ){
    //public ObjectStructureMap[] formatObjectStructure( Set<Id> setAccRelBUIds){
    public ObjectStructureMap[] formatObjectStructure( Map<String, BusinessGroup> mapBusinessGroup){
        List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
        masm.clear();

        //Change below
        //List<BU_Relationship__c> lstBUs            = new List<BU_Relationship__c>{};
        List<BusinessGroup> lstBGs  = new List<BusinessGroup>{};
        //List<ID> currentParent      = new List<ID>{}; //not being used in new design
        //Map<ID, String> nodeList    = new Map<ID, String>{};
        Map<String, String> nodeList    = new Map<String, String>{};
        List<String> nodeSortList   = new List<String>{};
        List<Boolean> levelFlag     = new List<Boolean>{};
        List<Boolean> closeFlag     = new List<Boolean>{};
        String nodeId               = '0';
        String nodeType             = Constants.NODE_TYPE_CHILD ;
        Integer count               = 0;
        Integer level               = 0;
        Boolean endOfStructure      = false;
        Set<String> setKeysUsedInFirstLevel = new Set<String> ();//added by JG
        //Find highest level obejct in the structure
        /*currentParent.add( GetTopElement( accId ) );
        for(Id buRecId: setAccRelBUIds)
            currentParent.add( GetTopElement( buRecId) );
        
        system.debug('##############CurrentParent###############'+CurrentParent);*/
        
        //Loop though all children
        //this while-loop runs only twice assuming we have only two-levels in tree
        while ( !endOfStructure ){

            if( level == 0 ){
                //Change below     
                //lstBUs = [select id,Account__c,Parent__c,Opportunity_Amount__c,Global_Line_of_Business_or_BU__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c from BU_Relationship__c WHERE id IN : CurrentParent ORDER BY Name];
                //[ SELECT a.Type, a.Site, a.Parent__c, a.OwnerId, a.Name, a.Industry, a.Id FROM Account a WHERE a.id IN : CurrentParent ORDER BY a.Name ];
                  for(Schema.PicklistEntry pe: User.sObjectType.getDescribe().fields.getMap().get('Global_Business_Line__c').getDescribe().getPicklistValues())
                  {
                    for (String key : gblBU_BusinessGroupMap.keySet()) {
                  if(pe.getLabel().equalsIgnoreCase(key)) {
                    lstBGs.add(gblBU_BusinessGroupMap.get(key));
                    setKeysUsedInFirstLevel.add(key);
                  }
                } 
                  }
                  system.debug('++++++++++level 0+++++ '+lstBGs);
            } 
            else {
                system.debug('++++++++++level 1 before+++++ '+gblBU_BusinessGroupMap.keySet());
                //Change below      
                //lstBus = [select id,Account__c,Parent__c,Opportunity_Amount__c,Global_Line_of_Business_or_BU__c,Name,Total_Won__c,Total_Open_Pipeline__c,Relationship_Type__c from BU_Relationship__c WHERE Parent__c IN : CurrentParent ORDER BY Name];
                //[ SELECT a.Type, a.Site, a.Parent__c, a.OwnerId, a.Name, a.Industry, a.Id FROM Account a WHERE a.Parent__c IN : CurrentParent ORDER BY a.Name ];
              /*for(Schema.PicklistEntry pe: User.sObjectType.getDescribe().fields.getMap().get('Business_Unit__c').getDescribe().getPicklistValues())
              {
                for (String key : gblBU_BusinessGroupMap.keySet()) {
                  if(pe.getLabel().equalsIgnoreCase(key)) {
                    lstBGs.add(gblBU_BusinessGroupMap.get(key));
                  }
                } 
              }*/
              for (String key : gblBU_BusinessGroupMap.keySet()) {
                  if(!setKeysUsedInFirstLevel.contains(key)) {
                    lstBGs.add(gblBU_BusinessGroupMap.get(key));
                  }
              } 
            }
            //System.debug('[*****CurrentParent****]'+CurrentParent);//not being used in new design
            //if( lstBUs.size() == 0 ){
            if( lstBGs.size() == 0 ){
                endOfStructure = true;
            }
            else{
                system.debug('++++++++++++++testing listBGs '+ lstBGs);
                //currentParent.clear();
                //for ( Integer i = 0 ; i < lstBUs.size(); i++ ){
                for ( Integer i = 0 ; i < lstBGs.size(); i++ ){
                    //Change below
                    //BU_Relationship__c buRec = lstBUs[i];
                    BusinessGroup bgRec = lstBGs[i];
                    system.debug('+++++++++++ each bgRec at 140 '+bgRec);
                    //nodeId = ( level > 0 ) ? NodeList.get( buRec.Parent__c )+'.'+String.valueOf( i ) : String.valueOf( i );
                    nodeId = ( level > 0 ) ? NodeList.get( bgRec.parent )+'.'+String.valueOf( i ) : String.valueOf( i );
                    //masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, buRec ) );
                    masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, bgRec ) );
                    //currentParent.add( buRec.id );
                    //nodeList.put( buRec.id, nodeId);
                    nodeList.put( bgRec.nodeName, nodeId);
                    System.debug('[**nodeId**]'+nodeId);
                    nodeSortList.add( nodeId );
                }
                system.debug('+++++++++++nodeList '+NodeList);
                system.debug('+++++++++++nodeSortList '+nodeSortList);
                maxLevel.add( level ); 
                //to clear list after first level (level=0) has been executed
                lstBGs.clear(); //added by Jinesh
                //added by Jinesh (Assumption : the tree will have only two levels - Parent(0) and Child(1))
                if (level == 1) {
                  break;
                }               
                level++;
            }
            // Naresh Added as per T-267045
            if (checkQueryLimits()) {
              break;
            }
        }//end of WHILE loop
        
        system.debug('+++++++++ masm testing line 164 '+masm);
        
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
            //if ( tasm.buRec.id == accId ) {
            //if ( tasm.bgRec.id == accId ) {
            //    tasm.currentNode = true;
            //}
            asm.add( tasm );
        }
        
        //MIrfan, 281013
        //if( lstBUs.size()> 0 ) {
        if( lstBGs.size()> 0 ) {
            asm[0].nodeType             = Constants.NODE_TYPE_START;
            asm[asm.size()-1].nodeType  = Constants.NODE_TYPE_END;
        }
        return asm;
    }
    
    //====================================================================
    // Determin parent elements relationship to current element
    // @return flagList
    //====================================================================
    public List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType ){
        
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode   = '';
        String workNode     = '';
        Integer cn          = 0;
        
        for( Integer i = 0; i < nodeElements.size() - 1; i++ ){
	        if(nodeElements[i] != null && nodeElements[i] != 'null') {
	          system.debug('++++++++++nodeElements[i] '+nodeElements[i]);
	          cn = Integer.valueOf(nodeElements[i]);
	        }
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
    
    //=====================================================================
    // Determin if the element is a closing element
    // @return flagList
    //=====================================================================
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
    
    //====================================================================
    // Determin if Element is the bottom node  
    // @return Boolean
    //====================================================================
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
    
  public static Map<String, Integer> clientTypeToLevel = new Map<String, Integer>{
                                   Constants.BU_RELATIONSHIP_TYPE_PROSPECT => 0,
                                   Constants.BU_RELATIONSHIP_TYPE_FORMER_CLIENT => 1,
                                   Constants.BU_RELATIONSHIP_TYPE_CLIENT => 2
  };
    //===================================================================
    // Find the tom most element in Heirarchy  
    // @return objId
    //===================================================================
    /*public String GetTopElement( String objId ){
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
    }*/
    
   
    //===================================================================
    // Wrapper class
    //===================================================================
    public with sharing class ObjectStructureMap{

        public String nodeId;
        public Boolean[] levelFlag = new Boolean[]{};
        public Boolean[] closeFlag = new Boolean[]{};
        public String nodeType;
        public Boolean currentNode;
        
        /*public BU_Relationship__c buRec {
            
            //If Open or Won are Null then populate 0 value.
            get {
                if(buRec.Total_Won__c==null)
                    buRec.Total_Won__c=0;
                if(buRec.Total_Open_Pipeline__c==null)
                    buRec.Total_Open_Pipeline__c=0; 
                return buRec;       
            }
            
            set;}*/
        public BusinessGroup bgRec {get;set;}
            
        public String getnodeId() { return nodeId; }
        public Boolean[] getlevelFlag() { return levelFlag; }
        public Boolean[] getcloseFlag() { return closeFlag; }
        public String getnodeType() { return nodeType; }
        public Boolean getcurrentNode() { return currentNode;}
        
        public Integer childCount { set;get; }

        //public BU_Relationship__c getBURec() { return buRec; }
        public BusinessGroup getBGRec() { return bgRec; }
        
        public void setnodeId( String n ) { this.nodeId = n; }
        public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
        public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
        public void setnodeType( String nt ) { this.nodeType = nt; }
        public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }

        //public void setBU( BU_Relationship__c buRec ) { this.buRec = buRec; }
        public void setBG( BusinessGroup bgRec ) { this.bgRec = bgRec; }

        //public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, BU_Relationship__c buRec ){
        public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, 
                                    Boolean lastNode, Boolean currentNode, BusinessGroup bgRec ){
            
            this.nodeId         = nodeId;
            this.levelFlag      = levelFlag; 
            this.closeFlag      = closeFlag;
            this.nodeType       = nodeType;
            this.currentNode    = currentNode;
            //this.buRec = buRec;
            this.bgRec = bgRec;
        }
    }
    
    //=======================================================================
    // T-267045 : to remove BU_Relationship__c 
    //=======================================================================
    
    // Naresh as per T-267045
    private static Boolean checkQueryLimits() {
       if (Integer.valueOf(Limits.getQueries()) >= 80) {
        return true;
      }
      return false;
    }

    //Inner class to hold information of BURelationship
    public with sharing class BusinessGroup {
        public String nodeName {get;set;} //Same as BU/GBL on related record.
        public String clientType {get;set;} //Relationship type on BURelationship__c
        public Double closedWonAmount {get;set;} //Total Won on BUR
        public Double closedWonAmountPCU {get;set;} // Total Won amount, converted to User's Personal Currency
        public Double pipeLineAmount {get;set;} //Total Open Pipeline on BUR
        public Double pipeLineAmountPCU {get;set;} //Total Open Pipeline, converted to User's Personal Currency
        public String parent {get;set;} //name of the Parent GLB
        
        
        //Construct
        public BusinessGroup(String ndName,
                             String clntType,
                             String clsWonAmt,
                             String clsWonAmtPCU,
                             String pipeLnAmt,
                             String pipeLnAmtPCU,
                             String parentName) {
            this.nodeName = ndName;
            this.clientType = clntType;
            this.closedWonAmount = clsWonAmt != null ? Double.valueOf(clsWonAmt) : 0;
            this.closedWonAmountPCU = clsWonAmtPCU != null ? Double.valueOf(clsWonAmtPCU) : 0;
            this.pipeLineAmount = pipeLnAmt != null ? Double.valueOf(pipeLnAmt) : 0;
            this.pipeLineAmountPCU = pipeLnAmtPCU != null ? Double.valueOf(pipeLnAmtPCU) : 0;
            this.parent = parentName;
        }
    }
    
    //Gets client status of the given criteria   
    public String knowClientType(Boolean hasOrder, Date contractEndDate){
      System.debug('\n[BUHierarchyController : knowClientType] : contractEndDate: '+ contractEndDate);
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
        Date contractEndDate = null;
        Boolean hasOrders;
        Decimal amount;
        Decimal amountPCU;
        for (Opportunity opp : [SELECT OwnerId, CloseDate, Amount, AccountId, Owner.Global_Business_Line__c,
                                   Owner.Business_Unit__c,  Contract_End_Date__c, isClosed,
                                   Amount_Corp__c, Amount_PCU__c,
                                   (SELECT Id, Name, Contract_End_Date__c, Contract_Start_Date__c, 
                                           Opportunity__c, Total__c FROM Orders__r) 
                                FROM Opportunity WHERE AccountId =: accId AND isClosed = false]) {
            opptyMap.put(opp.ID, opp);
            hasOrders = false;
            if (opp.Orders__r.size() > 0) {
                hasOrders = true;
            }
            contractEndDate = opp.Contract_End_Date__c;
            System.debug ('+++++++++++ '+opp) ;

            amount = (opp.Amount_Corp__c != null) ? opp.Amount_Corp__c : 0.00;
            amountPCU = (opp.Amount_PCU__c != null) ? opp.Amount_PCU__c : 0.00;

            //GBL Structure
            if (String.isNotEmpty(opp.Owner.Global_Business_Line__c) && 
                 !gblBU_BusinessGroupMap.containsKey(opp.Owner.Global_Business_Line__c)) {
                
                buGroup = new BusinessGroup(opp.Owner.Global_Business_Line__c, knowClientType(hasOrders, null), 
                                             null, null, String.valueOf(amount), String.valueOf(amountPCU), null/*knowParentName(opp.Owner.Business_Unit__c)*/);
                gblBU_BusinessGroupMap.put(opp.Owner.Global_Business_Line__c, buGroup);
            } else if (String.isNotEmpty(opp.Owner.Global_Business_Line__c) && gblBU_BusinessGroupMap.containsKey(opp.Owner.Global_Business_Line__c)) {
                gblBU_BusinessGroupMap.get(opp.Owner.Global_Business_Line__c).pipeLineAmount += amount;
                gblBU_BusinessGroupMap.get(opp.Owner.Global_Business_Line__c).pipeLineAmountPCU += amountPCU;
            }
            
            //BU Structure
            if (String.isNotEmpty(opp.Owner.Business_Unit__c) && 
                 !gblBU_BusinessGroupMap.containsKey(opp.Owner.Business_Unit__c)) {
                buGroup = new BusinessGroup(opp.Owner.Business_Unit__c, knowClientType(hasOrders, null), null, null,
                                   String.valueOf(amount), String.valueOf(amountPCU), knowParentName(opp.Owner.Business_Unit__c));
                //gblBU_BusinessGroupMap.put(opp.Owner.Global_Business_Line__c, buGroup);
                gblBU_BusinessGroupMap.put(opp.Owner.Business_Unit__c, buGroup);
            } else if (String.isNotEmpty(opp.Owner.Business_Unit__c) 
                       && gblBU_BusinessGroupMap.containsKey(opp.Owner.Business_Unit__c)) {
                if (gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmount == null){
                    gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmount = 0;
                }
                gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmount += amount;

                if (gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmountPCU == null){
                  gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmountPCU = 0;
                }
                gblBU_BusinessGroupMap.get(opp.Owner.Business_Unit__c).pipeLineAmountPCU += amountPCU;
            }
        }
    }
    
    //Calculate Closed Won Retrieval
    public void calculateClosedWonRetrieval () {
        Date contractEndDate = null;
        Decimal amount;
        Decimal amountPCU;
        List<Order_Split__c> orderSplits = new List<Order_Split__c>();
        Set<ID> ownerIDs = new Set<ID>();
        Set<String> currencyIsoCodes = new Set<String>{'USD'};
        Map<ID, User> ownerUserMap = new Map<ID, User>();
        system.debug('++++++++++++account id++++++++++++ '+accId);
        for (Order_Split__c ordSplit : [SELECT ID, Split_Total__c, Split_Percentage__c, OwnerId, CurrencyIsoCode,
                                               Order__c, 
                                               Order__r.Contract_End_Date__c, 
                                               Order__r.Account__c,
                                               Order__r.OwnerId,
                                               Order__r.Amount_Corp__c,
                                               Order__r.Amount_PCU__c
                                        FROM Order_Split__c 
                                        WHERE Order__r.Account__c =: accId]) {
          orderSplits.add(ordSplit);
          ownerIDs.add(ordSplit.OwnerId);
          currencyIsoCodes.add(ordSplit.CurrencyIsoCode);
      }
      
      for (User u : [SELECT ID, Business_Unit__c, Global_Business_Line__c 
                     FROM User WHERE ID IN : ownerIDs]) {
        ownerUserMap.put(u.ID, u);
      }
      CurrencyUtility currencyUtil = new CurrencyUtility(currencyIsoCodes);

      for (Order_Split__c ordSplit : orderSplits) {
        contractEndDate = ordSplit.Order__r.Contract_End_Date__c;
        System.debug('---recordordSplit--->'+ordSplit);
        if (!ownerUserMap.containsKey(ordSplit.OwnerId) || ordSplit.Order__c == null) {
            continue;
        }
        User splitOwner = ownerUserMap.get(ordSplit.OwnerId);
        System.debug('[**splitOwner.Global_Business_Line__c**]'+splitOwner.Global_Business_Line__c);
        System.debug('[****!gblBU_BusinessGroupMap.containsKey(splitOwner.Global_Business_Line__c)]'+!gblBU_BusinessGroupMap.containsKey(splitOwner.Global_Business_Line__c));
        System.debug('[***gblBU_BusinessGroupMap***]'+gblBU_BusinessGroupMap);
        
        
        System.debug('\nDefault currency: '+ UserInfo.getDefaultCurrency());
        system.debug('\nordSplit.Order__r.Amount_PCU__c: '+ ordSplit.Order__r.Amount_PCU__c + ' for order ' + ordSplit.Order__c);
        amount = (ordSplit.Split_Total__c != null && ordSplit.Order__r.Amount_Corp__c != null) ? ordSplit.Split_Percentage__c * ordSplit.Order__r.Amount_Corp__c / 100 : 0.00;
        /*amountPCU = (ordSplit.Split_Total__c != null && ordSplit.Order__r.Amount_PCU__c != null) ?
                        currencyUtil.convertCurrency(ordSplit.CurrencyIsoCode,
                                                        ordSplit.Split_Total__c,
                                                        UserInfo.getDefaultCurrency(),
                                                        ordSplit.Order__r.Contract_End_Date__c)
                        : 0.00;*/
        amountPCU = (ordSplit.Split_Total__c != null && ordSplit.Order__r.Amount_PCU__c != null) ?
                    ordSplit.Split_Percentage__c/100 * ordSplit.Order__r.Amount_PCU__c : 0.00;
        System.debug('\nConverted currency. FROM '+ ordSplit.Split_Total__c + ' to : ' + amountPCU);
        if (String.isNotEmpty(splitOwner.Global_Business_Line__c) && 
             !gblBU_BusinessGroupMap.containsKey(splitOwner.Global_Business_Line__c)) {
                
                buGroup = new BusinessGroup(splitOwner.Global_Business_Line__c, 
                           knowClientType(true, contractEndDate), 
                            String.valueOf(amount), String.valueOf(amountPCU), null, 
                            null, null/*knowParentName(splitOwner.Business_Unit__c)*/);
                                                     
           gblBU_BusinessGroupMap.put(splitOwner.Global_Business_Line__c, buGroup);
            
         } else if (String.isNotEmpty(splitOwner.Global_Business_Line__c) 
                         && gblBU_BusinessGroupMap.containsKey(splitOwner.Global_Business_Line__c)
                         && ordSplit.Split_Total__c != null) {
           System.debug('[**ordSplit.Split_Total__c*]'+ordSplit.Split_Total__c);
           System.debug('[***gblBU_BusinessGroupMap**]'+gblBU_BusinessGroupMap);
           System.debug('[#######gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmount#]'+gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmount);
                            
           if (gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmount < 1) {
             System.debug('[***inside***]');
             gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmount = 0;
           }
           gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmount += amount;
           
           if (gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmountPCU < 1) {
             gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmountPCU = 0;
           }
           gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).closedWonAmountPCU += amountPCU;
           
           String clientTypeString = knowClientType(true, contractEndDate);
           System.debug('\n[BUHierarchyController : calculateClosedWonRetrieval] clientType returned: '+ clientTypeString);
           if (clientTypeToLevel.get(clientTypeString) > clientTypeToLevel.get(gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).clientType)) {
             gblBU_BusinessGroupMap.get(splitOwner.Global_Business_Line__c).clientType = clientTypeString;
           }
         }
        System.debug('[***splitOwner.Business_Unit__c***]'+splitOwner.Business_Unit__c);
        System.debug('[###gblBU_BusinessGroupMap.###]'+gblBU_BusinessGroupMap);
        //System.debug('[**debug bu**]'+gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmount);
        
        if (String.isNotEmpty(splitOwner.Business_Unit__c) && 
             !gblBU_BusinessGroupMap.containsKey(splitOwner.Business_Unit__c)) {
           System.debug('----in if--');     
                buGroup = new BusinessGroup(splitOwner.Business_Unit__c, 
                           knowClientType(true, contractEndDate), 
                            String.valueOf(amount), String.valueOf(amountPCU),
                            null, null, knowParentName(splitOwner.Business_Unit__c));

           gblBU_BusinessGroupMap.put(splitOwner.Business_Unit__c, buGroup);
            
         } else if (String.isNotEmpty(splitOwner.Business_Unit__c)
                         && gblBU_BusinessGroupMap.containsKey(splitOwner.Business_Unit__c)) {
           System.debug('----in else--');
           if (gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmount == null) {
             gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmount = 0;
           }
           System.debug('[~~~ordSplit.Split_Total__c~~]'+ordSplit.Split_Total__c);
           System.debug('[~~~~debug closedwon ~~~]'+gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmount);
           gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmount += amount;
           
           if (gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmountPCU == null) {
             gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmountPCU = 0;
           }
           gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).closedWonAmountPCU += amountPCU;
           
           String clientTypeString = knowClientType(true, contractEndDate);
           system.debug('\n[BUHierarchyController : calculateClosedWonRetrieval] : comparing ' + clientTypeString 
           + ' with existing ' + gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).clientType + ' for ');
           if (clientTypeToLevel.get(clientTypeString) > clientTypeToLevel.get(gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).clientType)) {
             gblBU_BusinessGroupMap.get(splitOwner.Business_Unit__c).clientType = clientTypeString;
           }
         }
      }
    }
      //method to return the parentName on basis of User.Business_Unit__c
     //method to return the parentName on basis of User.Business_Unit__c
      private String knowParentName (String businessUnit) {
        if (businessUnit == null) {
          return null;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_CREDIT_SERVICES)
                    || businessUnit.containsIgnoreCase(' CS ')
                    || businessUnit.containsIgnoreCase('CS ')
                    || businessUnit.containsIgnoreCase(' CS')) {
          return Constants.USER_GBL_CREDIT_SERVICES;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_DECISION_ANALYTICS)
                    || businessUnit.containsIgnoreCase(' DA ')
                    || businessUnit.containsIgnoreCase('DA ')
                    || businessUnit.containsIgnoreCase(' DA')) {
          return Constants.USER_GBL_DECISION_ANALYTICS;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_MARKETING_SERVICES)
                    || businessUnit.containsIgnoreCase(' MS ')
                    || businessUnit.containsIgnoreCase('MS ')
                    || businessUnit.containsIgnoreCase(' MS')) {
          return Constants.USER_GBL_MARKETING_SERVICES;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_INTERACTIVE)) {
          return Constants.USER_GBL_INTERACTIVE;
        } else if (businessUnit.containsIgnoreCase(Constants.USER_GBL_LATAM_SERASA_SALES)) {
          return Constants.USER_GBL_LATAM_SERASA_SALES;
        } else if (businessUnit.containsIgnoreCase('CI&T')) {
          return Constants.USER_GBL_MARKETING_SERVICES;
        }
        return null;
      }//end of method 'knowParentName'
    
}