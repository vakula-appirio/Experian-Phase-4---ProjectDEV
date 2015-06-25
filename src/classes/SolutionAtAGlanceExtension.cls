/**=====================================================================
 * Appirio, Inc
 * Name: SolutionAtAGlanceExtension
 * Description: Extension for SolutionAtAGlance.page
 * Created Date: June 14th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified      Modified By               Description of the update
 * Feb 02nd, 2015     Naresh Kr Ojha            T-356445: Updated constructor to use Label and SaveAttachment method to use Test.isRunning.
 * Feb 04th, 2015     Arpita Bose               Updated attachment Name to 'Opportunity_SolutionGlance.pdf' and used custom label
  =====================================================================*/
  public with sharing class SolutionAtAGlanceExtension {
    private ApexPages.StandardController stdController {get;set;}
    public Opportunity_Plan__c oppPlan {get;set;}
    
    //constructor
    public SolutionAtAGlanceExtension(ApexPages.StandardController controller){
        stdController = controller;
        Id oppId = (Id)( (Opportunity_Plan__c)stdController.getRecord ()).id;

      if(oppId == null){
        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.SOLUTIONATGLANC_ERR_PLEASE_SELECT_PLAN)); 
      } else {                                           
        oppPlan = [SELECT Id, Objectives_and_Requirements__c, Solution__c, Benefits__c,Strengths__c,
                   Account_Name__r.Name, Opportunity_Name__c, CreatedBy.Name, CreatedDate, Opportunity_Name__r.Name
                     FROM Opportunity_Plan__c WHERE Id = :oppId ];
      }
    }
    
    // Method that is called when Save button is clicked
    public Pagereference Save(){
      update oppPlan;
      return null;
    }  
    
    // Method that is called when Cancle button is clicked     
    public PageReference Cancel(){
      return new Pagereference('/' +oppPlan.Id); // Navigates back to the Opportunity Plan record.
    }
    
    // Method that generates the PDF Document when Generate PDF button is clicked
    public PageReference generatePDF(){    
      PageReference pdf =  Page.SolutionAtAGlancePDF;
      pdf.getParameters().put('id',(String)oppPlan.id); 
      pdf.setRedirect(true);
      return pdf;

    }
    
    
    private Id getOpptyConfidentialInfoId() {
      List<Confidential_Information__c> ciList = [Select Id from Confidential_Information__c Where Opportunity__c =: oppPlan.Opportunity_Name__c Limit 1];
      if(ciList.size() > 0) {
        return ciList[0].Id;
      }
      else if(ciList.size() == 0){
        return oppPlan.Id; 
      }
      return null;
    }
    
   /*Save pdf as an attachment to oppty confidential information*/
    public void saveAttachment(){
      if(ApexPages.currentPage().getParameters().get('mode') == null){
        PageReference pdfPage =  Page.SolutionAtAGlancePDF;
        pdfPage.getParameters().put('id',(String)oppPlan.id);       
        pdfPage.getParameters().put('mode','pdf'); 
        Attachment attachment = new Attachment();
        if (Test.isRunningTest()) {
          attachment.Body = Blob.valueOf('Test data');
        } else {
          attachment.Body = pdfPage.getContentAsPDF();
        }
        attachment.Name = String.valueOf(System.Label.ACCOUNTPLANNING_OpportunitySolutionGlance) ;
        attachment.ParentId = getOpptyConfidentialInfoId();
        insert attachment;
      }
    }
 }