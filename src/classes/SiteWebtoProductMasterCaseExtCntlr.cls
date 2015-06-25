/**=====================================================================
 *  Name: SiteWebtoProductMasterCaseExtCntlr 
 * Description: Controler for page  SiteWebtoProductMasterCasePage
 * Created Date: Dec 15th 2014
 * Created By: Richard Joseph
 *
 * Date Modified      Modified By                Description of the update
 * 
 =====================================================================*/
public class SiteWebtoProductMasterCaseExtCntlr {

public Product_Master__c productMasterUpdate {get; set;}
public String productMasterStringUpdate {get; set;}
public boolean showTypeSelection {get; set;}
Public boolean showNewProductReq {get; set;}
Public boolean showProductUpdateReq {get; set;}
Public String productMasterId {get;set;}
private Id caseRecId {get; set;}

Private Product_Master__c productMasterRecord;

    public SiteWebtoProductMasterCaseExtCntlr(ApexPages.StandardController controller) {
            
                this.productMasterRecord= (Product_Master__c ) controller.getRecord();
                showTypeSelection =true;
                showNewProductReq =false;
                showProductUpdateReq =false;
                try{
                caseRecId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Request').getRecordTypeId();
                }
                catch(exception ex)
                {
                
                }

    }

    public Pagereference ReqNewProduct(){
    
    showTypeSelection =false;
                showNewProductReq =True;
                showProductUpdateReq =false;
    return null;
    }
    
        public Pagereference ReqUpdateProduct(){
    
    showTypeSelection =False;
                showNewProductReq =False;
                showProductUpdateReq =True;
               
    //return pageRef ;
    return null;
    }

    Public Pagereference CreateCase()
    {
        
        String requestString = '';
        SObjectType sobjType = Schema.getGlobalDescribe().get('Product_Master__c');

        DescribeSObjectResult sobjDef = sobjType.getDescribe();

        Map<String, SObjectField> fields = sobjDef.fields.getMap();

         

        Set<String> fieldSet = fields.keySet();

        for(String s:fieldSet)

        {

            SObjectField fieldToken = fields.get(s);

            requestString   = requestString   +fieldToken.getDescribe().getLabel() + ': ';
            requestString   =requestString   +(productMasterRecord.get(s)!= null ? productMasterRecord.get(s):'') + '\n';

            

        }
        
        
        case newCase = new Case();
           // newCase.Description= String.Valueof('Name: '+productMasterRecord.Name+ '\n Product Master Name: '+ productMasterRecord.Product_master_name__c + '\n Product Description: '+ productMasterRecord.Product_Description__c + '\n Type Of Sale: '+ productMasterRecord.Type_Of_Sale__c  );
            newCase.Description= requestString  ; 
            newCase.Origin='Web';
            newCase.Subject='New Product Master Request';
            newCase.RecordTypeId = caseRecId ;
            newcase.Reason = 'New Product';
            
            //Fetching the assignment rules on case
AssignmentRule asgnRule = new AssignmentRule();
asgnRule = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

//Creating the DMLOptions for "Assign using active assignment rules" checkbox
Database.DMLOptions dmlOpts = new Database.DMLOptions();
dmlOpts.assignmentRuleHeader.assignmentRuleId= asgnRule.id;


//Setting the DMLOption on Case instance
newCase.setOptions(dmlOpts);

                        Insert newCase; 
                        
         PageReference pageRef = new PageReference('http://zoom');               
        return pageRef ;
    }
    
     Public Pagereference CreateUpdateCase()
    {
        
        case newCase = new Case();
            newCase.Description= String.Valueof('Name: '+productMasterRecord.Name+ '\n Update Description: '+ productMasterStringUpdate   );
            newCase.Origin='Web';
            newCase.Subject='Update Product Master Request';
            newcase.Reason = 'New Product';
                        //Fetching the assignment rules on case
AssignmentRule asgnRule = new AssignmentRule();
asgnRule = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

//Creating the DMLOptions for "Assign using active assignment rules" checkbox
Database.DMLOptions dmlOpts = new Database.DMLOptions();
dmlOpts.assignmentRuleHeader.assignmentRuleId= asgnRule.id;


//Setting the DMLOption on Case instance
newCase.setOptions(dmlOpts);
                        Insert newCase; 
                        
         PageReference pageRef = new PageReference('http://zoom');               
        return pageRef ;
    }
}