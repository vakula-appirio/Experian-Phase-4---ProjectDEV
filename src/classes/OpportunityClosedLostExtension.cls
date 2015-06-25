/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityClosedLostExtension
 * Description: 
 * Created Date: Oct 23rd, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Jan 30th, 2014       Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 9th, 2014        Nathalie Le Guay (Appirio)   Adding Competitor__c fields and making compRec a controller variable
 * Feb 13th, 2014       Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Feb 17th, 2014       Jinesh Goyal(Appirio)        T-248998, T-249059: Added No Decision Logic and updated picklist logic
 *                      Ceri Jones (Appirio)
 * Feb 24th, 2014       Nathalie Le Guay (Appirio)   Moved code to set isNoDecisionType at the beginning of constructor
 * Mar 04th, 2014       Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Apr 08th, 2014       Arpita Bose                  T-269372: Added addError()in try-catch block
 * Aug 07th, 2014		Naresh kr Ojha				 T-289258: Added try catch to show DMLExceptions for methods createComp() and saveRecord( )
 =====================================================================*/

public class OpportunityClosedLostExtension {
    
    public Opportunity opp {set;get;}
    public ApexPages.StandardController sController {get;set;}
    public String selectedPrimaryReason             {get;set;}
    public String selectedCompetitor                {get;set;}
    public Global_Settings__c custSetting           {get;set;}
    public Competitor__c compRec                    {get;set;}
    private String typeOpp;
    public Boolean isNoDecisionType                 {get;set;}
    public Boolean isOtherSelectAsPRC               {get;set;}
    public String selectedNoDecisionReason          {get;set;}
    public Map<id,Competitor__c> mapComp            {get;set;}

    //Constructor
    public OpportunityClosedLostExtension (ApexPages.StandardController stdController) {
        sController = stdController;
        isNoDecisionType = false;

        custSetting = Global_Settings__c.getValues (Constants.GLOBAL_SETTING);
        Id oppId = (Id)( (Opportunity)stdController.getRecord ()).id;
        this.opp = [select Name,StageName,Primary_Reason_W_L__c,isClosed, isWon, Other_Closed_Reason__c, Lost_To__c, Win_Back_Date__c, Primary_Winning_Competitor__c from Opportunity where id=:oppId];

        //Check if the Opportunity is already Closed/Lost
        if (opp.StageName.equalsIgnoreCase (custSetting.Opp_Closed_Lost_Stagename__c) || opp.isClosed)
        {
            ApexPages.addMessage (new ApexPages.Message (ApexPages.Severity.ERROR, Label.OCL_Message_Closed_Opportunity));
        }  

        typeOpp = ApexPages.currentPage().getParameters().get('type'); 
        if (typeOpp != null && typeOpp.equalsIgnoreCase ('nodecision')) {
          isNoDecisionType = true;
          if (opp != null) opp.StageName = Constants.OPPTY_STAGE_NO_DECISION;
        }
        /*else if (typeOpp == null){
          if (opp != null) opp.StageName = custSetting.Opp_Closed_Lost_Stagename__c;
        }*/

        this.compRec = new Competitor__c();
        isOtherSelectAsPRC = false;
        selectedNoDecisionReason = '';           
    }

    //Retrieve Opportunity Competitors and generate SelectOption list.
    public List<SelectOption> getCompetitors() {
        List<SelectOption> options = new List<SelectOption>();
        options.add (new SelectOption ('','--'+Label.OCL_Option_Select+'--'));
        mapComp = new Map<id, Competitor__c>([SELECT id,Opportunity__c,Account__r.Name FROM Competitor__c WHERE Opportunity__c=:opp.id]);

        for (Competitor__c compRec: mapComp.values())
        {
          if (!String.isEmpty(compRec.Account__r.Name)) {
            options.add (new SelectOption (compRec.Id,compRec.Account__r.Name));
          }
        }
        
        if (options.size() < 2)
        {
            options.clear();
            options.add (new SelectOption ('','--'+Label.OCL_Option_None+'--'));
        }
        return options;
    }

    //Associate new Competitor with Opportunity
    public pagereference createComp(){
      System.Debug('###'+compRec);
      compRec.Opportunity__c = opp.Id;
      try {
        insert compRec;
      } catch (DMLException e) {
		ApexLogHandler.createLogAndSave ('OpportunityClosedLostExtension', 'createComp', e.getStackTraceString(), e);
		for (Integer i = 0; i < e.getNumDml(); i++) {
		  compRec.addError(e.getDmlMessage(i));
		}
      }
      compRec = new Competitor__c();

      return null;
    }
    
    //Retrieve Opportunity Primary Reason Picklist values and generate SelectOption list.
    public List<SelectOption> getPrimaryReasons() {
      system.debug ('\n[OpportunityClosedLostExtension : getPrimaryReasons]: ' + Opportunity.sObjectType.getDescribe().fields.getMap());
      List<SelectOption> options = new List<SelectOption>();
      options.add (new SelectOption('','--'+Label.OCL_Option_Select+'--'));
      for (Schema.PicklistEntry pe:
           Opportunity.sObjectType.getDescribe().fields.getMap().get('Primary_Reason_W_L__c').getDescribe().getPicklistValues()) {
        if (isNoDecisionType) {
          if (pe.getLabel().equalsIgnoreCase (Constants.OPPTY_PRIMARY_CLOSED_REASON_ASPROJECT)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_EXPERION_NO_GO_DECISION)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_CUSTOMER_UNDECIDED)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_NO_BUDGET)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_OTHER)){
            options.add (new SelectOption(pe.getLabel(),pe.getValue()));
          }
        } else {
          if (pe.getLabel().equalsIgnoreCase (Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_DATA_QUALITY)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_DATA_RANGE)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_DEL_CAP)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_LEGAL_REST)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_PRICE_TOO_HIGH)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_FUNCTIONALITY)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_TERMS)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_CLI_REL)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_OTHER)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_COMP_CAP)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_EXP_STRATEGIC_DECISION)
              || pe.getLabel().equalsIgnoreCase(Constants.OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_SERVICE_REC)) {
            options.add (new SelectOption (pe.getLabel(),pe.getValue()));
          }
        }
      }

      if (options.size() < 1) {
        options.clear();
        options.add (new SelectOption ('','--'+Label.OCL_Option_None+'--'));
      }

      return options;
    }

    //PrimaryReason Onchange handler
    public pagereference primaryReasonChanged() {
        opp.Primary_Reason_W_L__c = selectedPrimaryReason;
        if (selectedPrimaryReason != null && selectedPrimaryReason.equalsIgnoreCase (Constants.OPPTY_PRIMARY_CLOSED_REASON_OTHER)) isOtherSelectAsPRC = true;
        else isOtherSelectAsPRC = false;
        return null;
    }
    
    //Save button handler
    public pagereference saveRecord() {
        //Primary Reason is required.
        if (opp.Primary_Reason_W_L__c==null || opp.Primary_Reason_W_L__c.equals(''))
        {
            ApexPages.addMessage (new ApexPages.Message (ApexPages.Severity.ERROR, Label.OCL_Message_Primary_Reason_required));
            return null;
        }
        
        //If Primary Closed Reason is 'Other'
        //Then Other_Closed_Reason is required 
        if (opp.Primary_Reason_W_L__c.equalsIgnoreCase('Other') && (opp.Other_Closed_Reason__c == null || opp.Other_Closed_Reason__c.equals ('')))
        {
            ApexPages.addMessage (new ApexPages.Message (ApexPages.Severity.ERROR, Label.OCL_Message_Other_Closed_Reason_required));
            return null;
        }

        system.debug ('#######################'+opp.Primary_Winning_Competitor__c);
        system.debug ('#######################'+mapComp);
        //Competitor is required in order to Save.       
        if (opp.Primary_Winning_Competitor__c == null && isNoDecisionType == false)
        {
          ApexPages.addMessage (new ApexPages.Message(ApexPages.Severity.ERROR, Label.OCL_Message_Competitor_Name_required));
          return null;
        }
        else if(isNoDecisionType == false){
          CompRec = mapComp.get(opp.Primary_Winning_Competitor__c);
          if(opp.Win_Back_Date__c != null)CompRec.Win_back_date__c = opp.Win_back_Date__c;
          CompRec.lost_to__c = true;
          opp.Primary_Winning_Competitor__c = compRec.Account__r.Name;
          try {
            update CompRec;
          } 
          catch (DMLException e) {
            ApexLogHandler.createLogAndSave ('OpportunityClosedLostExtension','saveRecord', e.getStackTraceString(), e);
            for (Integer i = 0; i < e.getNumDml(); i++) {
              CompRec.addError(e.getDmlMessage(i));
            }
            // Please add Apex Log error creation here
          }
        }

        //Update Opportunity.
        if (isNoDecisionType == true) {
       	  opp.StageName = Constants.OPPTY_STAGE_NO_DECISION;
        }else {
          opp.StageName = custSetting.Opp_Closed_Lost_Stagename__c; //'Closed Lost';
          //opp.Requested_Stage__c = custSetting.Opp_Closed_Lost_Stagename__c;
        }
        try {
          update opp;    
        } catch (Dmlexception ex) {
            ApexLogHandler.createLogAndSave ('OpportunityClosedLostExtension','saveRecord', ex.getStackTraceString(), ex);
            for (Integer i = 0; i < ex.getNumDml(); i++) {
              opp.addError(ex.getDmlMessage(i));
            }
        }
        
           //Opp_Closed_Lost_Stagename 
        system.debug ('#######################'+opp); 
        system.debug ('#######################'+CompRec);       
        return new PageReference ('/'+opp.id);
    }

}