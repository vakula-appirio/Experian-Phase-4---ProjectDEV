/**=====================================================================
 * Appirio, Inc
 * Name: AccountPlanPenetration
 * Description: Controller for AccountPlanPenetration.page
 * Created Date: 
 * Created By: 
 * 
 * Date Modified        Modified By            Description of the update
 * Oct 21st, 2014       Pratibha Chhimpa       T-327479: call initData() on save()
 * Jun 11th, 2015       Paul Kissick           Case #932739 : Fix for GBL duplicating.
 =====================================================================*/
public class AccountPlanPenetration {
 
  public Account_Plan__c ap {get;set;}
  public Map<String,List<AccountPlanPenetrationWrapper>> mapApp {get;set;}
  public Map<String,String> mapCapToTotal {get;set;}
  public List<String> listAccBuTotal {get;set;}
  //public List<Account_Plan_Penetration__c> listApp {get;set;}

  public List<Schema.PicklistEntry> BUs {get;set;}
  public List<String> listBUs {get;set;}
  
  // public List<Opportunity> openOpps {get;set;} // PK: Case #932739 - Remove this and replace with new wrapper class below.
  public class customOpp {
    public Opportunity opp {get;set;}
    public List<String> getOppGBL() {
      List<String> listGbls = new List<String>();
      listGbls.addAll(oppGbls);
      listGbls.sort();
      return listGbls;
    }
    public Set<String> oppGbls {get;set;}
    public customOpp(Opportunity o, Set<String> gbls) {
      opp = o;
      oppGbls = gbls;
    }
  }
  public List<customOpp> openOpps {get;set;}  // PK Case #932739 - Changed this to return customOpp list
  
  
  public List<customOpp> wonOpps {get;set;}  // PK Case #932739 - Changed this to return customOpp list
  public Integer wonOppssize {get;set;}
  public Integer openOppssize {get;set;}
  //public List<String> ExperianBUs = new List<String>{'Customer Insight','Cross Channel Marketing','Credit Risk','Application Processing','Identity Solutions','Fraud Detection'};
  public static Map<String, Account_Plan_Penetration__c> mapBuExBU_Pen {get;set;}
  public static Set<String> mapContainsSet {get;set;}
  public List<AggregateResult> revenueAggregateResult {get;set;}
  public List<String> listAllAccountBU {get;set;}
  public Map<String, String> mapOldToNewAccBU {get;set;}
  public List<Contact> listAPPTemp {get;set;}
  private Double conversionRateGBP;

  public AccountPlanPenetration(ApexPages.StandardController stdController) {
    initData();
  }

  public AccountPlanPenetration(){
    initData();
  }
  private void initData(){
    mapBuExBU_Pen = new Map<String, Account_Plan_Penetration__c>();
    mapContainsSet = new Set<String>();
    this.ap = [SELECT Id, Name, CurrencyIsoCode, Account__c FROM Account_Plan__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    this.mapApp = new Map<String,List<AccountPlanPenetrationWrapper>> ();
    System.Debug('###'+mapApp);

    this.openOpps = getOpenOpps(ap.Account__c);
    this.wonOpps = getWonOpps(ap.Account__c);
    this.wonOppssize = this.wonOpps.size();
    this.openOppssize = this.openOpps.size();
    System.Debug('###'+wonOppssize);

    revenueAggregateResult = new List<AggregateResult>();
    mapCapToTotal = new Map<String,String>();
    listAccBuTotal = new List<String>();
    mapOldToNewAccBU = new Map<String, String> ();
    listAPPTemp = new List<Contact>();

    //finding conversion rate
    for(CurrencyType ct : [Select ConversionRate
                 From CurrencyType
                 WHERE IsoCode = 'GBP' AND IsActive = true]){
      conversionRateGBP = ct.ConversionRate;
    }
    getBUPenetration();
  }

  

  private void getBUPenetration(){
    List<Account_Plan_Penetration__c> listApp = [Select id, Account_Plan__c, Account_Business_Unit__c, Capability__c, Annual_Revenue__c, Penetration__c,
                      LastModifiedDate , currencyISOCode From Account_Plan_Penetration__c
                      Where Account_Plan__c = :ApexPages.currentPage().getParameters().get('id')
                      ORDER BY Id ];
 

    //Map<String,List<Account_Plan_Penetration__c>> mapApp = new Map<String,List<Account_Plan_Penetration__c>>();
    Set<String> setAllAccountBU = new Set<String> ();
    //Set<String> setCapPicklist = new Set<String> ();
    listAllAccountBU = new List<String> ();
    List<String> listCapPicklist = new List<String> ();
    Map<String, Decimal> mapAccBuTotal = new Map<String, Decimal>();
    //Constant assuming no. of BUs = 6
    final Integer NO_OF_BUs = 6;
    //all Account Business Unit values in set

    for (Account_Plan_Penetration__c app : listApp) {
      //convert to GBP if active
      //if (conversionRateGBP != null && app.Annual_Revenue__c != null) {
      //  app.Annual_Revenue__c = app.Annual_Revenue__c * conversionRateGBP;
      //}

      if(app.Annual_Revenue__c != null && app.Annual_Revenue__c > 0){
        System.debug('@@@' + app.Annual_Revenue__c);
        app.Annual_Revenue__c = app.Annual_Revenue__c.setScale(0);
        System.debug('@@@' + app.Annual_Revenue__c);
      }

      if (app.Account_Business_Unit__c != null && app.Capability__c != null && !setAllAccountBU.contains(app.Account_Business_Unit__c)) {
        setAllAccountBU.add(app.Account_Business_Unit__c);
        if (listAllAccountBU.size() < NO_OF_BUs) {
           listAllAccountBU.add(app.Account_Business_Unit__c);
        }
      }
    }

    //converting to list to sort
    /*for (String accBU : setAllAccountBU) {
      listAllAccountBU.add(accBU);
      if (listAllAccountBU.size() >= NO_OF_BUs) {
        break;
      }
    }*/


    Integer counter = 1;
    for (Integer i = listAllAccountBU.size(); i < NO_OF_BUs; ++i) {
      listAllAccountBU.add('Client BU'+counter);
      ++counter;
    }

    //listAllAccountBU.sort();


    for(String s : listAllAccountBU){
      listAPPTemp.add(new Contact(FirstName = s));
    }
    system.debug('++++++ listAllAccountBU '+listAllAccountBU);
    system.debug('++++++ setAllAccountBU '+setAllAccountBU);
    system.debug('++++++ listCapPicklist '+listCapPicklist);

    //all values from Capability picklist
    for(Schema.PicklistEntry pe: Account_Plan_Penetration__c.sObjectType.getDescribe().fields.getMap().get('Capability__c').getDescribe().getPicklistValues()) {
      listCapPicklist.add(pe.getLabel());
    }
    listCapPicklist.sort();
    system.debug('++++++ listCapPicklist '+listCapPicklist);

    //only the latest modified APP is added in case of duplicates..
    for (Account_Plan_Penetration__c app : listApp) {
      if (app.Account_Business_Unit__c != null && app.Capability__c != null) {
        if(!mapBuExBU_Pen.containsKey(app.Account_Business_Unit__c+app.Capability__c)) {
        mapBuExBU_Pen.put(app.Account_Business_Unit__c+app.Capability__c, app);
        }
      }
    }
    system.debug('++++++ mapBuExBU_Pen '+mapBuExBU_Pen);

    //create mapApp
    for (String capPicklistValue : listCapPicklist) {
      for (String accBU : listAllAccountBU) {
        if (!mapApp.containsKey(capPicklistValue)) {
          mapApp.put(capPicklistValue, new List<AccountPlanPenetrationWrapper>());
          mapCapToTotal.put(capPicklistValue, '0');
        }
        //assuming no. of BUs will always be 6
        //if(mapApp.get(capPicklistValue) != null && mapApp.get(capPicklistValue).size() < NO_OF_BUs){
          if(mapBuExBU_Pen.containsKey(accBU+capPicklistValue)){
            mapApp.get(capPicklistValue).add(new AccountPlanPenetrationWrapper(mapBuExBU_Pen.get(accBU+capPicklistValue)));
            if (mapBuExBU_Pen.get(accBU+capPicklistValue) != null && mapCapToTotal.get(capPicklistValue) != null
              && mapBuExBU_Pen.get(accBU+capPicklistValue).Annual_Revenue__c != null){
              //calculations row total revenue
              System.debug('+++++++++++++++accBU '+accBU);
              System.debug('+++++++++++++++capPicklistValue '+capPicklistValue);
              System.debug('+++++++++++++++mapBuExBU_Pen.get(accBU+capPicklistValue) '+mapBuExBU_Pen.get(accBU+capPicklistValue));
              System.debug('+++++++++++++++mapCapToTotal.get(capPicklistValue) '+mapCapToTotal.get(capPicklistValue));
              mapCapToTotal.put(capPicklistValue, '' + (Decimal.valueOf(mapCapToTotal.get(capPicklistValue)) + mapBuExBU_Pen.get(accBU+capPicklistValue).Annual_Revenue__c).setScale(0));
          }
          }else {
            mapApp.get(capPicklistValue).add(new AccountPlanPenetrationWrapper(new Account_Plan_Penetration__c(Account_Plan__c=ap.Id,
                              Annual_Revenue__c=0.00, Capability__c=capPicklistValue,
                              Account_Business_Unit__c=accBU)));
          }
        //}
        //calculating column totals
        System.debug('+++++++++++accBU '+accBU);
        if(!mapAccBuTotal.containsKey(accBU)){
          mapAccBuTotal.put(accBU, 0);
        }
        if (mapBuExBU_Pen.get(accBU+capPicklistValue) != null){
          mapAccBuTotal.put(accBU, (mapAccBuTotal.get(accBU)+mapBuExBU_Pen.get(accBU+capPicklistValue).Annual_Revenue__c).setScale(0));
        }
      }
    }
    //create column totals list
    for (String accBU : listAllAccountBU) {
      System.debug('++++++++++++++ accBU '+mapAccBuTotal.get(accBU));
      listAccBuTotal.add(mapAccBuTotal.get(accBU).setScale(0).format());
    }
    //calculate Grand Total
    Decimal tempGT = 0;
    for (String key : mapCapToTotal.keySet()) {
      tempGT += decimal.valueOf(mapCapToTotal.get(key));
      mapCapToTotal.put(key,decimal.valueOf(mapCapToTotal.get(key)).format());
    }
    //tempGT = tempGT.setScale(0);
    listAccBuTotal.add(tempGT.setScale(0).format());
    system.debug('++++++ mapApp '+mapApp);
    //return mapApp;
  }//END OF METHOD getBUPenetration

  public List<AggregateResult> gerrevenueAggregateResult(){
       List<AggregateResult> revenueAggregateResult = [Select SUM(Annual_Revenue__c) total_revenue_accountBU,
                             Account_Business_Unit__c
                             FROM Account_Plan_Penetration__c
                             WHERE Account_Plan__c =:ApexPages.currentPage().getParameters().get('id')
                             GROUP BY Account_Business_Unit__c];
     return revenueAggregateResult;

  }
  public Boolean getRenderTrForBU (String key) {
    if (mapBuExBU_Pen.containsKey(key)) {
    return true;
    }
    return false;
  }

  /*public List<String> getExperianBUs(){
    return ExperianBUs;
  }*/

  public List<Schema.PicklistEntry> getlistBUs(){

    /*for(Schema.Picklistentry PLE:BUs){
      System.Debug('###'+PLE);
      listBUs.add(ple.GetLabel());
    }
    System.Debug('###'+listBUs);*/
    return BUs;
  }
  
  // PK Case #932739 - Changed this to return customOpp list
  public list<customOpp> getOpenOpps(Id AccId){
    list<customOpp> copps = new list<customOpp>();
    List<Opportunity> Opps = [Select id, Name, CloseDate, Amount, Probability, StageName, CurrencyISOCode, Contract_Term__c, Amount_Corp__c,
                 (Select Global_Business_Line__c From OpportunityLineItems),
                 (Select Attr_to_Account__c, Attr_to_Experian__c From Account_Plan_Opportunity__r)//T-295627: To add attractive ratings on PDF
                  From Opportunity Where AccountId = :AccId and IsClosed = false oRder by closeDate ASC];
    for(Opportunity o:Opps){
      if(o.Amount!=null&&o.Contract_Term__c!=null&&o.Contract_Term__c!=0) o.Amount_Corp__c = (o.Amount/o.Contract_Term__c)*12;
      // check the opp line items....
	    Set<String> oppGbls = new Set<String>();
	    if (o.OpportunityLineItems != null && o.OpportunityLineItems.size() > 0) {
	      for(OpportunityLineItem oli : o.OpportunityLineItems) {
	      oppGbls.add(oli.Global_Business_Line__c);
	      }
	    }
	    copps.add(new customOpp(o,oppGbls));
    }
    return copps;
  }
  
  // PK Case #932739 - Changed this to return customOpp list
  public list<customOpp> getWonOpps(Id AccID){
    list<customOpp> copps = new list<customOpp>(); // PK Case #932739 - Adding Opp Line Items Extract
    List<Opportunity> Opps = [Select id, Name, Owner.Name, CloseDate, Amount, CurrencyISOCode, Contract_Term__c, Capability__c, Amount_Corp__c,
                  (Select Global_Business_Line__c From OpportunityLineItems)
                   From Opportunity Where AccountId = :AccId and IsWon = true and CloseDate = LAST_N_DAYS:365 //T-294246: Only the closed won opportunities where the closed date is less or equal to 1 year from today
                   Order by CLoseDate DESC];
    for(Opportunity o:Opps){
      if(o.Amount!=null&&o.Contract_Term__c!=null&&o.Contract_Term__c!=0)o.Amount_Corp__c = (o.Amount/o.Contract_Term__c)*12;
      // PK Case #932739 - Adding Opp Line Items Extract
      Set<String> oppGbls = new Set<String>();
      if (o.OpportunityLineItems != null && o.OpportunityLineItems.size() > 0) {
        for(OpportunityLineItem oli : o.OpportunityLineItems) {
	        oppGbls.add(oli.Global_Business_Line__c);
	      }
      }
      copps.add(new customOpp(o,oppGbls));
    }
    return copps;
  }
  
  public PageReference backToPlan(){
    system.debug('chek before save');
    saveValues();
    system.debug('chek after save');
    PageReference pr = new PageReference('/' + ap.Id);
    //pr.setRedirect(true);
    return pr;
  }
  //save method to upsert APP records
  public Pagereference Save(){
    saveValues();
    initData();
    // Comment out page reference for Task T-325543, Id is return with backtoplan() therefore added 2 buttons top and buttom
    //PageReference pr = new PageReference('/'+ApexPages.currentPage().getParameters().get('id'));
    //return pr;
    return null;
  }
  //pratibha   
  public void saveValues(){
  List<Account_Plan_Penetration__c> listAPPToUpsert = new List<Account_Plan_Penetration__c> ();

    //find changes in AccoutBU values
    for (Integer i=0; i<listAllAccountBU.size(); ++i) {
    if (listAllAccountBU.get(i) != listAPPTemp.get(i).FirstName){
      mapOldToNewAccBU.put(listAllAccountBU.get(i), listAPPTemp.get(i).FirstName);
    }
    }
    System.debug('+++++++++++++mapOldToNewAccBU+++++++++ '+mapOldToNewAccBU);


    for (List<AccountPlanPenetrationWrapper> listMP : mapApp.values()) {
    for (AccountPlanPenetrationWrapper aPPWrapper : listMP) {
      //if(aPP.Id != null) {
      Account_Plan_Penetration__c  aPP = aPPWrapper.accountPlanPenet;
      if (mapOldToNewAccBU.containsKey(aPP.Account_Business_Unit__c)) {
        aPP.Account_Business_Unit__c = mapOldToNewAccBU.get(aPP.Account_Business_Unit__c);
      }
      System.debug('+++++++++++++save aPP+++++++++ '+aPP.Annual_Revenue__c);

      //convert to USD from GBP (if GBP is active)
      //if (conversionRateGBP != null && conversionRateGBP != 0 && app.Annual_Revenue__c != null) {
      //  aPP.Annual_Revenue__c = aPP.Annual_Revenue__c / conversionRateGBP;
      //}

      //}
      listAPPToUpsert.add(aPP);
    }
    }

    // Set the currency code to the same as Account Plan Currency Code :SUNIL
    for(Account_Plan_Penetration__c objAPP :listAPPToUpsert){
     objAPP.currencyISOCode = this.ap.currencyISOCode;
    }

    if (listAPPToUpsert.size() > 0) {
    try{
      //update mapAPPToUpdate.values();
      upsert listAPPToUpsert;
      System.debug('+++++++++++++save done+++++++++ '+listAPPToUpsert);
    }catch(Exception ex){
      System.debug('+++++++++++++exception occured+++++++++ '+ex.getMessage());
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                            ex.getMessage()));
    }
    }
  }


  public String getCurrencySymbolFromIso() {
    String isoCode = this.ap.currencyISOCode;
    return isoCode;
    /*
    String currencySymbol = ('USD' == isoCode ? '$' :
       ('CAD' == isoCode ? '$' :
       ('EUR' == isoCode ? '€' :
       ('GBP' == isoCode ? '£' :
       ('JPY' == isoCode ? '¥' :
       ('KRW' == isoCode ? '?' :
       ('CNY' == isoCode ? '?' :
       ('INR' == isoCode ? '?' :
       '£'))))))));
  
    return isoCode + '(' + currencySymbol + ')';*/
  }

  public class AccountPlanPenetrationWrapper{
    public Account_Plan_Penetration__c accountPlanPenet {get;set;}
    
    public AccountPlanPenetrationWrapper( Account_Plan_Penetration__c accountPlanPenet){
      this.accountPlanPenet = accountPlanPenet;
    }
    
    public String getAccRevenue(){
      return accountPlanPenet.Annual_Revenue__c.format();
    }
  }


}