/*===================================================================== 
 * Experian Ltd.
 * Name: SavoOpportunityExt
 * Description: Extension to the SAVO_Opportunity.page to create 
 				links to the FUSE Templates 
 * Created Date: Mar 11th, 2014
 * Created By: James Weatherall
 * 
 * Date Modified                Modified By                  Description of the update
 * April 13th, 2015				James Weatherall			 Prevent duplicate Products being returned in the link to Fuse Product tile. 
 * 															 Change the link to the Product Master FUSE URL as oppose to the SAVO URL and Product Tag.
 * April 24th, 2015 			James Weatherall			 Created new method getEMEAOrderURL() to build the URL params for the MS Netherlands Order Template
=====================================================================*/
public with sharing class SavoOpportunityExt {

	private final Opportunity oppty;
	private String clientFullName;
	private String contactFirstName;
	private String contactLastName;
	private String clientAddress; // Address 1-3
	private String clientCity;
	private String clientState;
	private String clientPostalCode;
	private String companyRegNo;
	private String contactPhone;
	private String contactFax;
	private String contactEmail;
	private String clientVMarket;
	private String contractStart;
	private String contractEnd;
	private String contractTerm;
	private String totalContractCost; // Total Contract Revenue
	private String contactJobTitle;
	private String contractSignDate;
	private String expectedLiveDate;
	private String commencementDate;
	private String URL;
    	
	public SavoOpportunityExt(ApexPages.StandardController stdController) {
        this.oppty = (Opportunity)stdController.getRecord();
    }

	public String listTags {
        get { return listTags; }
        set { listTags = value; }
    }
    
    public String getAssetTypes()
    {
        return 'xls,pdf,doc,ppt,cp';
    }
    
    public List<Competitor__c> getCompetitors()
	{
		// Id accId;
		List<Competitor__c> competitors = new List<Competitor__c>();		
		
		for(Competitor__c c : [select Account__r.Name, Account__r.FUSE_Tag_Id__c from Competitor__c where Opportunity__c =: oppty.Id and Account__r.FUSE_Tag_Id__c <> ''])
		{
			competitors.add(c);		
		}
		
		return competitors;
	}
    
    public List<OpportunityLineItem> getProducts()
	{
		Map<Id, OpportunityLineItem> lineItems = new Map<Id, OpportunityLineItem>();		
		Set<String> setTagIds = new Set<String>();
        listTags = '';
        
		for(OpportunityLineItem oli : [select  PricebookEntry.Product2.Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.FUSE_Tag_Id__c, PricebookEntry.Product2.Product_Master__r.FUSE_product_Page_URL__c 
                                       from OpportunityLineItem where OpportunityId =: oppty.Id])
                                       //and PricebookEntry.Product2.FUSE_Tag_Id__c <> 
		{
          // Check that a FUSE Page URL exists against the Product Master and add to line items Map 
          if(oli.PricebookEntry.Product2.Product_Master__r.FUSE_product_Page_URL__c <> '' && oli.PricebookEntry.Product2.Product_Master__r.FUSE_product_Page_URL__c <> null 
               && !lineItems.containsKey(oli.PricebookEntry.Product2.Id)) {
            lineItems.put(oli.PricebookEntry.Product2.Id, oli);
          }
          // Check that a Tag Id exists against the Product for the Document tile 
          if(oli.PricebookEntry.Product2.FUSE_Tag_Id__c <> '' && oli.PricebookEntry.Product2.FUSE_Tag_Id__c <> null) {
            if(!setTagIds.contains(oli.PricebookEntry.Product2.FUSE_Tag_Id__c)) {
              setTagIds.add(oli.PricebookEntry.Product2.FUSE_Tag_Id__c);      
            }
          }
		}	
        
        for(String tags : setTagIds) {
          listTags = listTags + tags;
          listTags = listTags + ',';
        }
        
        // Get Region field from Opp Owner to identify relevant Content
        String ownerRegion; 
        for(Opportunity o : [select Id, Owner.Region__c from Opportunity where Id =: oppty.Id])        
        {
            ownerRegion = o.Owner.Region__c;    
        }
            
        for(Savo_Tags__c ss : Savo_Tags__c.getAll().values())
        {
          if(ss.Name == ownerRegion) {
              listTags = listTags + ss.FUSE_Tag_Id__c;
              listTags = listTags + ',';
          }
        }
        
        // Add Push to CRM FUSE tag Id
        listTags = listTags + Savo_Tags__c.getInstance('Push to CRM').FUSE_Tag_Id__c;
		System.debug('listTags = ' + listTags);
		
        // Remove the final comma
        listTags = listTags.removeEnd(',');
        
        return lineItems.values();
	}
    
    // Case #550423 : 24th April, James Weatherall
    public String getEMEAOrderURL() {
        String URL = 'https://www.gosavo.com/ExperianFUSE/Document/Customize.aspx?id=34977323&';
        String URLparams = '';
        SAVO_URL_Parameters__c params;
        params = SAVO_URL_Parameters__c.getOrgDefaults();
        
        if(oppty.Id != null) {
           Opportunity opp = [select Id, Amount, AccountId, Account.Name, (Select Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Role from OpportunityContactRoles where Role = 'Decider'), 
                            (select Id, PricebookEntry.Product2.Name from OpportunityLineItems)
    						from Opportunity where Id =: oppty.Id];
		   // Start to build the URL parameters
           URLparams = URLparams + params.Account_Name__c + '=' + opp.Account.Name + '&';           
           URLparams = URLparams + params.Contact_First_Name__c + '=' + opp.OpportunityContactRoles[0].Contact.FirstName + '&';  
           URLparams = URLparams + params.Contact_Last_Name__c + '=' + opp.OpportunityContactRoles[0].Contact.LastName + '&';
           URLparams = URLparams + params.Contact_Email__c + '=' + opp.OpportunityContactRoles[0].Contact.Email + '&';
           URLparams = URLparams + params.Contact_Phone__c + '=' + opp.OpportunityContactRoles[0].Contact.Phone + '&';
           URLparams = URLparams + params.Opportunity_TCV__c + '=' + opp.Amount + '&';
           URLparams = URLparams + params.Opportunity_Product__c + '=';
           for(OpportunityLineItem oli : opp.OpportunityLineItems) {
             URLparams = URLparams + oli.PricebookEntry.Product2.Name + '&'; 
           }
            
           for(Account_Address__c address : [select Address1__c, Address__r.Address_2__c, Address_City__c, Address_Postal_Code__c from Account_Address__c where Account__c =: opp.AccountId and Address_Type__c = 'Registered' limit 1])
           {
             URLparams = URLparams + params.Account_Address__c + '=' + address.Address1__c;
             URLparams = (address.Address__r.Address_2__c != '') ? URLparams + ', ' + address.Address__r.Address_2__c : '';
             URLparams = URLparams + '&';
             URLparams = URLparams + params.Account_Post_Code__c + '=' + address.Address_Postal_Code__c + '&';
             URLparams = URLparams + params.Account_City__c + '=' + address.Address_City__c + '&';
           }
        }

        URLparams = EncodingUtil.urlEncode(URLparams, 'UTF-8');
        
        URL = URL + URLparams;
        URL = URL.removeEnd('&');
        
        return URL;
    }
}