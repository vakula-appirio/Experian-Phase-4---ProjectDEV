/**=====================================================================
 * Appirio, Inc
 * Name: OLI_BillingNSaleTypeUpdateController
 * Description: 
 * Created Date: Nov 13th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014                    Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 * Mar 03rd, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Apr 08th, 2014               Arpita Bose                  T-269372: Added addError()in try-catch block
 * May 01st, 2014               Arpita Bose                  Updated catch(Exception) to catch(DMLException)
 =====================================================================*/
public class OLI_BillingNSaleTypeUpdateController {
    
    public List<record> OLIsToUpdate {get;set;}
    public Map<Id,Product2> mapProductBilling {get;set;}
    public String retURL {get;set;}
    
    //Constructor 
    public OLI_BillingNSaleTypeUpdateController(ApexPages.StandardController stdController) {
        //Retrive OLI Ids from query string.
        String[] oliIds = ApexPages.currentPage().getParameters().get('oli').split(',');
        
        //Retrive Return URL from query string. If nothing defaul to Opportunity Landing page.
        retURL = ApexPages.currentPage().getParameters().get(Constants.PARAM_NAME_RETURL);
        retURL = (retURL!=null)?retURL:'/006/o';
        
        
        system.debug('##########oliIds###########'+oliIds);
        OLIsToUpdate = new List<record>();
        Set<Id> setProductIds = new set<Id>();
        
        //Query OpportunityLineItem records with few Product details.
        for(OpportunityLineItem oliRec: [Select PricebookEntry.Name,
            PricebookEntry.Product2Id,PricebookEntry.Product2.Types_of_Sale__c,UnitPrice, Type_of_Sale__c, TotalPrice, 
            SystemModstamp, SortOrder, ServiceDate, 
            Revenue_Schedule_Period_Type__c, Revenue_Schedule_Num_of_Periods__c, 
            Revenue_Schedule_Amt_Per_Period__c, Quantity, PricebookEntryId, OpportunityId, 
            ListPrice, LastModifiedDate, LastModifiedById, IsDeleted, Id, HasSchedule, 
            HasRevenueSchedule, HasQuantitySchedule, Description, DE_Product_Name__c, 
            CurrencyIsoCode, CreatedDate, CreatedById, Billing_Product__c 
            From OpportunityLineItem where Id=:oliIds])
            {
                //Fill the List of InnerClass Record.
                OLIsToUpdate.add(new Record(oliRec));
                
                //Hold ProductIds, to later retrieve more details.
                setProductIds.add(oliRec.PricebookEntry.Product2Id);
            }//END: FOR oliRec
            
            system.debug('##########OLIsToUpdate###########'+OLIsToUpdate);
            
            mapProductBilling = new Map<Id,Product2>();
            
            //Retrieve BillingProducts related to Products
            try{
                mapProductBilling = new Map<Id,Product2>([select Id,(Select Id,Name FROM Billing_Products__r) from Product2 where Id=:setProductIds]);
            }catch(Exception ex){
            	 system.debug('##########ex#######'+ex);
               apexLogHandler.createLogAndSave('OLI_BillingNSaleTypeUpdateController','OLI_BillingNSaleTypeUpdateController', ex.getStackTraceString(), ex);
               mapProductBilling.values().get(0).addError(ex.getMessage());
            }
            system.debug('##########mapProductBilling###########'+mapProductBilling);
            
            //Iterate throgh List of innerClass Records, to populate the Billing Product Property.
            for(Record rec: OLIsToUpdate)
            {
                List<SelectOption> lstBillingProducts = new List<SelectOption>();
                
                //If OLI has Product and If there are any Billing Products related to it.
                if(rec.oliRec.PricebookEntry.Product2!=null && 
                   mapProductBilling.containsKey(rec.oliRec.PricebookEntry.Product2Id) &&
                   mapProductBilling.get(rec.oliRec.PricebookEntry.Product2Id).Billing_Products__r!=null)
                {
                	system.debug('CCC: There are billing products');  // Shane Khublall
                	system.debug('ccc : ' + mapProductBilling);
                    lstBillingProducts.add(new SelectOption('',Label.OLI_Option_Value_None));
                    
                    //Iterate through all Related Billing Products and generate SelectOptions list.
                    for(Billing_Product__c billProdRec: mapProductBilling.get(rec.oliRec.PricebookEntry.Product2Id).Billing_Products__r)
                    {
                    	system.debug('DDD: There are billing productsFOR LOOP');  // Shane Khublall
                        lstBillingProducts.add(new SelectOption(billProdRec.Id,billProdRec.Name));
                    }//END: FOR
                }//END: IF
                
                //Map the Record's proptery with SelectOptions list built above.
                rec.BillingProducts = lstBillingProducts;
            }//END: FOR rec
            
            system.debug('##########OLIsToUpdate###########'+OLIsToUpdate);
    }//END: Constructor
    
    //Cancel button handler to redirect back
    public Pagereference performCancel()
    {
        return new PageReference(retURL);
    }//END: Method performCancel
    
    //Save button handler to save Modified OLI records and return back.
    public Pagereference performSave()
    {
        List<OpportunityLineItem> lstToUpdate = new List<OpportunityLineItem>();
        
        //Identify the OLI records being modified by user.
        for(record rec:OLIsToUpdate)
        {
            if(rec.oliRec.Type_of_Sale__c !=rec.initialTypesOfSale  || 
                rec.oliRec.Billing_Product__c !=rec.initialBillingProduct )
                lstToUpdate.add(rec.oliRec);
        }//END: FOR rec
        
        try {
	        //If there are any OLI Records to update.
	        if(lstToUpdate.size() > 0) {
	            update lstToUpdate;
	        }
        } catch(DMLException ex) {
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage())); 
	        apexLogHandler.createLogAndSave('OLI_BillingNSaleTypeUpdateController','performSave', ex.getStackTraceString(), ex);
	        for (Integer i = 0; i < ex.getNumDml(); i++) {
	          lstToUpdate.get(0).addError(ex.getDmlMessage(i));
	        }
	        return null;
        }//END: catch
        
        //After successfull saving return back.
        return new PageReference(retURL);
    }
    
    //Inner Class to maintain OLI Record data and few properties to allow editing OLI Fields.
    public class Record
    {
        public OpportunityLineItem oliRec {get;set;}
        
        //As only these two fields are editable, so maintain initiate state/value for these fields.
        public String initialTypesOfSale {get;set;}
        public String initialBillingProduct {get;set;}
        
        //Property, which convert's Multipselect picklist values to SelectOption List.
        public List<SelectOption> TypesOfSale {
            get{
                List<SelectOption> lstToReturn = new List<SelectOption>();
                system.debug('############### oliRec.PricebookEntry.Product2.Types_of_Sale__c#########'+ oliRec.PricebookEntry.Product2.Types_of_Sale__c);
                
                //If ToS of Product is not blank
                if( oliRec.PricebookEntry.Product2.Types_of_Sale__c!=null)
                {
                    lstToReturn.add(new SelectOption('',Label.OLI_Option_Value_None));
                    
                    //Break each item from multi-select picklist and convert to single picklist
                    for(String tos: oliRec.PricebookEntry.Product2.Types_of_Sale__c.split(';'))
                    {
                        lstToReturn.add(new SelectOption(tos.trim(),tos.trim()));
                    }//END: FOR tos
                }//END: IF
                return lstToReturn;
            }//END: Get
        }//END: Property TypesOfSale
        
        public List<SelectOption> BillingProducts {get;set;}
        
        //Class Constructor
        public record(OpportunityLineItem oliRec)
            {
                this.oliRec=oliRec;
                
                //Populate properties with initial values.
                initialTypesOfSale = oliRec.Type_of_Sale__c;
                initialBillingProduct = oliRec.Billing_Product__c;
            }//END: CONSTRUCTOR
    }//END: InnerClass Record
}//END: Controller