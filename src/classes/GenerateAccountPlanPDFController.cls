public with sharing class GenerateAccountPlanPDFController {
    
    /*Variable initialization*/
    public Account_Plan__c accountPlanObj {get;set;}
    public  List<Account_Plan_Opportunity__c> accPlanOppList {get;set;}
    public List<Account_Plan_Critical_Success_Factor__c> criticalSuccessFacList {get;set;}
    public List<Account_Plan_Competitor__c> competitorsList {get;set;}
    public List<Account_Plan_Team__c> accPlanTeamList {get;set;}
    public List<Task> taskList {get;set;}
    public List<Account_Plan_SWOT__c> strengthAccPlanSWOTs{get;set;}
    public List<Account_Plan_SWOT__c> weaknessAccPlanSWOTs{get;set;}
    public List<Account_Plan_SWOT__c> opportunityAccPlanSWOTs{get;set;}
    public List<Account_Plan_SWOT__c> threatAccPlanSWOTs{get;set;}    
    
    public List<Account_Plan_SWOT__c> clientstrengthAccPlanSWOTs{get;set;}
    public List<Account_Plan_SWOT__c> clientweaknessAccPlanSWOTs{get;set;}
    public List<Account_Plan_SWOT__c> clientopportunityAccPlanSWOTs{get;set;}
    public List<Account_Plan_SWOT__c> clientthreatAccPlanSWOTs{get;set;}
    public Id radarChartImageId {get;set;}
    
    /**
    This Constructor initialize/populate all the required data to generate the pdf.
    */
    public GenerateAccountPlanPDFController(ApexPages.StandardController stdController) {
        accountPlanObj = (Account_Plan__c)stdController.getRecord();
        accountPlanObj = [Select a.account__r.name,a.Value__c,a.SystemModstamp, a.Summary_Recent_History__c, 
	                          a.Strategic_Direction__c, a.Stability__c, a.Solutions__c, a.Risks__c, a.Revenue__c, 
	                          a.Reference__c, a.Recent_Successes__c, a.Primary_Contact__c, a.Payment_Issues__c, a.OwnerId,
	                          a.Opportunities__c, a.One_Experian__c, a.Objectives_Not_Achieved__c, a.Name, a.NPS__c, 
	                          a.Major_Wins__c, a.Major_Partners__c, a.Major_Competitors__c, a.Major_Changes__c, 
	                          a.Lessons_Learned__c, a.Last_Review_Date__c, a.LastModifiedDate, a.LastModifiedById, 
	                          a.LastActivityDate, a.IsDeleted, a.Internal_Account_Team__c, a.Industry_Expertise__c, a.Id, 
	                          a.Health_Status__c, a.Face_to_Face__c, a.Expiration__c, a.Experian_Vision_for_Account__c, 
	                          a.Experian_OPEX_Total__c, a.Experian_OPEX_Share__c, a.Experian_Capex_Total__c, a.Experian_CAPEX_share__c, 
	                          a.Experian_Annualised_Revenue__c, a.Executive__c, a.CreatedDate, a.CreatedById, a.Core_Business__c, 
	                          a.Contracts__c, a.Contact_Plan__c, a.Client_Plan__c, a.Business_Objectives__c, a.Annual_OPEX_in_Experian_Domain__c, 
	                          a.Annual_CAPEX_in_Experian_Domain__c, a.Account__c, a.Account_Sector__c, a.Account_Industry__c, 
					         (Select Id, IsDeleted, Name,  Account_Plan__c, Job_Title__c, User__c, User__r.name From Account_Plan_Teams__r), 
					         (Select Id, IsDeleted, Name,  Opportunity__r.name, Account_Plan__c, Account_Plan_Parent_Opportunity__c, 
						          Annualised_Revenue__c, Attr_to_Account__c, Attr_to_Experian__c, Close_Date__c, Contract_End_Date__c,
						          Contract_Start_Date__c, Current_Year_Revenue__c, Opp_Synchronisation_On__c, Opportunity_Name__c,
						          Opportunity_Owner__c, Opportunity__c, Probability__c, Sales_Stage__c, Status__c, TCV__c, Type__c, 
						          Year_1_Revenue__c, Year_2_Revenue__c 
						      From Account_Plan_Opportunity__r where Type__c = 'Potential Future Opps'), 
					         (Select Id, Owner.Name , What.Name, Subject, ActivityDate, Status, Priority, Completed_Date__c , 
						          Result__c , Investment__c  
						      From Tasks) ,
					         (Select Id, IsDeleted, Name, Account_Plan__c, Account_Plan_SWOT__c, Description__c, SWOT_1_Description__c, 
						          SWOT_1_Importance__c, SWOT_1__c, SWOT_2_Description__c, SWOT_2_Importance__c, SWOT_2__c, SWOT_3_Description__c,
						          SWOT_3_Importance__c, SWOT_3__c, SWOT_4_Description__c, SWOT_4_Importance__c, SWOT_4__c, SWOT_5_Description__c, 
						          SWOT_5_Importance__c, SWOT_5__c 
						      From Account_Plan_Critical_Success_Factors__r), 
					         (Select Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
						          SystemModstamp, LastActivityDate, Account_Plan__c, Comp_Adv_1_Str__c, Comp_Adv_1__c, Comp_Adv_2_Str__c, 
						          Comp_Adv_2__c, Comp_Adv_3_Str__c, Comp_Adv_3__c, Comp_Adv_4_Str__c, Competitor__r.name, Comp_Adv_4__c, 
						          Comp_Adv_5_Str__c, Comp_Adv_5__c, Competitor__c, Exp_Adv_1_Str__c, Exp_Adv_1__c, Exp_Adv_2_Str__c, 
						          Exp_Adv_2__c, Exp_Adv_3_Str__c, Exp_Adv_3__c, Exp_Adv_4_Str__c, Exp_Adv_4__c, Exp_Adv_5_Str__c, Exp_Adv_5__c 
						      From Account_Plan_Competitors__r) 
					        From Account_Plan__c a where id = :accountPlanObj.id limit 1];
					        
        accPlanOppList = accountPlanObj.Account_Plan_Opportunity__r;
        criticalSuccessFacList = accountPlanObj.Account_Plan_Critical_Success_Factors__r;
        competitorsList = accountPlanObj.Account_Plan_Competitors__r;
        accPlanTeamList = accountPlanObj.Account_Plan_Teams__r;
        taskList = accountPlanObj.Tasks;
        setAccPlanRecs();
        fetchRadarChartImageId();
    }
    
    public void fetchRadarChartImageId(){
        for(Attachment radarChart : [Select Id From Attachment Where ParentId = :accountPlanObj.id and Name = 'RadarChart']){
            radarChartImageId = radarChart.Id;
        } 
    }
    
    
    /*Save pdf as an attachment to oppty confidential information*/
    public void saveAttachment(){
        PageReference pdfPage =  Page.GenerateAccountPlanPDF;
        pdfPage.getParameters().put('id',(String)accountPlanObj.id);       
        pdfPage.getParameters().put('mode','pdf'); 
        Attachment attachment = new Attachment();
        Blob body;
        try {
           body = pdfPage.getContentAsPDF();
        } catch (VisualforceException e){
            body = Blob.valueOf('Test Text');
        } 
        attachment.Body = body;
        attachment.Name = String.valueOf('Account Plan.pdf');  //TODO : change the name of file.
        attachment.ParentId = accountPlanObj.id;
        insert attachment; 
   }
      
  private void setAccPlanRecs() // This method is called in class constructor. Works correctly.
  {
    strengthAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    weaknessAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    opportunityAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    threatAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    clientstrengthAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    clientweaknessAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    clientopportunityAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();
    clientthreatAccPlanSWOTs = new  List<Account_Plan_SWOT__c>();

    for(Account_Plan_SWOT__c singleAccPlanSWOT : [SELECT Id, Description__c, Impact__c, Who__c, Type__c, Importance__c 
                                                    FROM Account_Plan_SWOT__c
                                                    Where Account_Plan__c =: accountPlanObj.id
                                                    ORDER BY Importance__c DESC]){
        if(singleAccPlanSWOT.who__c == 'Experian'){         
            if(singleAccPlanSWOT.Type__c == 'Strength')
            {
              strengthAccPlanSWOTs.add(singleAccPlanSWOT);
            }
            else if(singleAccPlanSWOT.Type__c == 'Weakness')
            {
              weaknessAccPlanSWOTs.add(singleAccPlanSWOT);
            }
            else if(singleAccPlanSWOT.Type__c == 'Opportunity')
            {
              opportunityAccPlanSWOTs.add(singleAccPlanSWOT);
            }
            else if(singleAccPlanSWOT.Type__c == 'Threat')
            {
              threatAccPlanSWOTs.add(singleAccPlanSWOT);
            }
        }else if(singleAccPlanSWOT.who__c == 'Client'){            
            if(singleAccPlanSWOT.Type__c == 'Strength')
            {
              clientstrengthAccPlanSWOTs.add(singleAccPlanSWOT);
            }
            else if(singleAccPlanSWOT.Type__c == 'Weakness')
            {
              clientweaknessAccPlanSWOTs.add(singleAccPlanSWOT);
            }
            else if(singleAccPlanSWOT.Type__c == 'Opportunity')
            {
              clientopportunityAccPlanSWOTs.add(singleAccPlanSWOT);
            }
            else if(singleAccPlanSWOT.Type__c == 'Threat')
            {
              clientthreatAccPlanSWOTs.add(singleAccPlanSWOT);
            }
        }
    }
    
    for(Integer i = 1 ; i <= 6 ; i++){
        if(strengthAccPlanSWOTs.size() < i)
        {
          strengthAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(weaknessAccPlanSWOTs.size() < i)
        {
          weaknessAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(opportunityAccPlanSWOTs.size() < i)
        {
          opportunityAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(threatAccPlanSWOTs.size() < i)
        {
          threatAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(clientstrengthAccPlanSWOTs.size() < i)
        {
          clientstrengthAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(clientweaknessAccPlanSWOTs.size() < i)
        {
          clientweaknessAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(clientopportunityAccPlanSWOTs.size() < i)
        {
          clientopportunityAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
        if(clientthreatAccPlanSWOTs.size() < i)
        {
          clientthreatAccPlanSWOTs.add(new Account_Plan_SWOT__c());
        }
    }
  }
}