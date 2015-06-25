/**=====================================================================
 * Appirio, Inc
 * Name: SwotAnalysisController.cls/(For use with SwotAnalysis.page)
 * Description: This class works with the above VF page to display a SWOT analysis page to the end user,
 *              a 2 x 2 grid with Account Plan SWOT records displayed in the appropriate section.
 *              This page will also allow the creation of new Account Plan SWOT records, and can have a
 *              maximum of 6 records per "Type," for each "Who" selected. 
 * Created Date: 05/07/14
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * 07 May 2014                  Shane Khublall               Creation of class for S-210209 specification (T-276840)
 * 12 May 2014                  Shane Khublall               Update(as per T-278175) to only allow 8 records per 
 *                                                           section, auto popup new record creation box if no
 *                                                           existing records present
 * 20 May 2014                  Shane Khublall               Addition of deleteAccPlanSWOTRecord method
 * 23 May 2014                  Shane Khublall               Removal of JavaScript, redid some of the page with VF tags
 * 27 May 2014                  Shane Khublall               Rewriting with VF tags, modal rendering corrections
 * 16 Jul 2014                  Arpita Bose (Appirio)        I-120497: Fixed the code for SWOT analysis to create records
 =====================================================================*/

public with sharing class SwotAnalysisController
{
  public Account_Plan__c myAccPlan; // used
  public boolean displayWhoPopUp {get;set;} // used to control the display of the 'Who' PopUp box //not used
  public boolean displayNewAccPlanSWOTPopUp {get;set;} // used

  public String currentRecId {get;set;} // used

  private String prevType{get;set;} // used, do not use transient
  private String prevDesc{get;set;} // used, do not use transient
  private String prevImpact{get;set;} // used, do not use transient
  private String prevImportance{get;set;} // used, do not use transient

  public String parentAccountName{get;set;} // used

  public Account_Plan_SWOT__c currentRec {get;set;} // used

  private String accPlanWho {get;set;} // used
  public Account_Plan_SWOT__c newAccPlanSWOT {get;set;} // used

  public List<Account_Plan_SWOT__c> allRelAccPlanSWOTs{get;set;} // used
  // Account Plan SWOTs of type Strength
  public List<Account_Plan_SWOT__c> strengthAccPlanSWOTs{get;set;} // used
  // Account Plan SWOTs of type Weakness
  public List<Account_Plan_SWOT__c> weaknessAccPlanSWOTs{get;set;} // used
  // Account Plan SWOTs of type Opportunity
  public List<Account_Plan_SWOT__c> opportunityAccPlanSWOTs{get;set;} // used
  // Account Plan SWOTs of type Threat
  public List<Account_Plan_SWOT__c> threatAccPlanSWOTs{get;set;} // used

  // Map to replace above lists
  public Map<String, List<Account_Plan_SWOT__c>> typeToAccPlanSWOTs{get;set;} // not used

  public boolean newAccPlanSWOTCreationPopUp {get;set;} // not used

  public boolean displayPopUp {get;set;} // used
  public boolean displayCurrentRecordPopup{get;set;} // used

  public boolean experianActive{get;set;} // used
  public boolean clientActive{get;set;} // used

  public SwotAnalysisController(ApexPages.StandardController stdController)
  {
    // same as selecting the fields we need, but not using a SELECT statement
    this.myAccPlan = (Account_Plan__c)stdController.getRecord();
    newAccPlanSWOT = new Account_Plan_SWOT__c();
    strengthAccPlanSWOTs = new List<Account_Plan_SWOT__c>();
    weaknessAccPlanSWOTs = new List<Account_Plan_SWOT__c>();
    opportunityAccPlanSWOTs = new List<Account_Plan_SWOT__c>();
    threatAccPlanSWOTs = new List<Account_Plan_SWOT__c>();
    typeToAccPlanSWOTs = new Map<String, List<Account_Plan_SWOT__c>>(); // not used
    currentRec = new Account_Plan_SWOT__c();
    experianActive=true;
    clientActive=false;

    parentAccountName = [SELECT name FROM Account WHERE id =:myAccPlan.account__c LIMIT 1].name;
    setAccPlanRecs();
  }

  // This method will save a new Account Plan SWOT record, and add it to the relevent list of records. The panel will then be reRendered,this newly added Acc SWOT plan will display also

  /*
  Purpose:      Will save a new Account Plan SWOT record, and add it to the relevent list of records.
  Arguments:    None. Input on VF page will provide information and populate it into 'newAccPlanSWOT' when the
                'Create' button is clicked
  Return:       None, new account plan swot record will be saved to Salesforce, VF page will display the new record.
  */
  public void saveNewAccPlanSWOTRecord()
  { 
    displayNewAccPlanSWOTPopUp = false;

    Account_Plan_SWOT__c newsingleAccPlanSWOT = new Account_Plan_SWOT__c(); //brand new record
    newsingleAccPlanSWOT.Account_plan__c = myAccPlan.id;
    newsingleAccPlanSWOT.Who__c = accPlanWho;
    newsingleAccPlanSWOT.Type__c = newAccPlanSWOT.Type__c;
    newsingleAccPlanSWOT.Importance__c = newAccPlanSWOT.Importance__c;
    newsingleAccPlanSWOT.Description__c = newAccPlanSWOT.Description__c;
    newsingleAccPlanSWOT.Impact__c = newAccPlanSWOT.Impact__c;

    system.debug('llllll opportunityAccPlanSWOTs' + opportunityAccPlanSWOTs);
    string tooManyRecordsError ='';
    system.debug('zzzzzz' + newAccPlanSWOT);

    // Add an error message if this is null!
    if(newAccPlanSWOT.Type__c != null && (newAccPlanSWOT.Description__c != null || newAccPlanSWOT.Impact__c != null) )
    {
      try
      {
        if(newAccPlanSWOT.Type__c == 'Strength')
        {
          if(strengthAccPlanSWOTs.size()<6)
          {
            strengthAccPlanSWOTs.add(newsingleAccPlanSWOT);
          }
          else
          {
            tooManyRecordsError = 'Strength';
          }
        }
        else if(newAccPlanSWOT.Type__c == 'Weakness')
        {
          if(weaknessAccPlanSWOTs.size()<6)
          {
            weaknessAccPlanSWOTs.add(newsingleAccPlanSWOT);
          }
          else
          {
            tooManyRecordsError = 'Weakness';
          }
        }
        else if(newAccPlanSWOT.Type__c == 'Opportunity')
        {
          if(opportunityAccPlanSWOTs.size()<6)
          {
            opportunityAccPlanSWOTs.add(newsingleAccPlanSWOT);
          }
          else
          {
            tooManyRecordsError = 'Opportunity';
            system.debug('mmmmmm add the opp');
          }
        }
        else if(newAccPlanSWOT.Type__c == 'Threat')
        {
          if(threatAccPlanSWOTs.size()<6)
          {
            threatAccPlanSWOTs.add(newsingleAccPlanSWOT);
            
          }
          else
          {
            tooManyRecordsError = 'Threat';
          }
        }
        if(tooManyRecordsError == '')
        {
          insert newsingleAccPlanSWOT; // if no error was reported, then insert the new Account Plan SWOT record
           // Inserts new record at correct location based on Importance
          insertBasedOnImportance(allRelAccPlanSWOTs, newsingleAccPlanSWOT);
        }
        else
        {
          ApexPages.Message tooManyRecords = new ApexPages.Message(ApexPages.Severity.Error,'At least 8 ' +accPlanWho + ' records of type ' + tooManyRecordsError + ' already exist on this Account Plan');
          ApexPages.addMessage(tooManyRecords);
        }
      }
      catch(Exception e)
      {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'An error occurred when creating the record:' + e.getMessage());
        ApexPages.addMessage(myMsg);
      }
    }
    else
    {
      ApexPages.Message someFieldsNull = new ApexPages.Message(ApexPages.Severity.Warning,'Record not saved, please populate Type and any one of Description or Impact fields on Account Plan SWOT before clicking \'Save.\'');
      ApexPages.addMessage(someFieldsNull);
    }
    closeNewItemPopup();
    setAccPlanRecs();
  } 

  /*
  Purpose:   Will retrieve all account plan SWOT records related to the account plan, sorts them into 4 separate lists
  Arguments: None. Id of the account plan being viewed is used to get its child account plan SWOT records
  Return:    None, 4 lists will be populated, each containing strength, weakness, opportunity or threat records
  */
  private void setAccPlanRecs() // This method is called in class constructor. Works correctly.
  {
    if(allRelAccPlanSWOTs == null) // This ensures that the query runs only once
    {
      allRelAccPlanSWOTs = [SELECT Id, Description__c, Impact__c, Who__c, Type__c, Importance__c 
                            FROM Account_Plan_SWOT__c
                            Where Account_Plan__c =: myAccPlan.id
                            ORDER BY Importance__c DESC]; // order by importance from highest to lowest
      system.debug('bbbbbb Select Statement Executed');
    }

    if(accPlanWho == null) 
    {
      accPlanWho='Experian';
    }
    strengthAccPlanSWOTs.clear(); 
    weaknessAccPlanSWOTs.clear();
    opportunityAccPlanSWOTs.clear();
    threatAccPlanSWOTs.clear();

    for(Account_Plan_SWOT__c singleAccPlanSWOT : allRelAccPlanSWOTs) // put all
    {
      if(singleAccPlanSWOT.Who__c == accPlanWho)
      {
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
      }
    }
  }

  /*
  Purpose:   When user clicks on 'Client' tab(Name of the client) , set the relevant tab to active, and set the
             account plan records that are displayed
  Arguments: None, called from the VF page when user clicks the 'Client' tab
  Return:    Nothing, Client tab is set to active by booleans below, and account plan records to display are updated
  */
  public void selectClientSWOTRecords()
  {
    accPlanWho ='Client';
    experianActive=false;
    clientActive=true;
    setAccPlanRecs();

  }

  /*
  Purpose:   When user clicks on 'Experian' tab, set the relevant tab to active, and set the
             account plan records that are displayed
  Arguments: None, called from the VF page when user clicks the 'Experian' tab
  Return:    Nothing, Experian tab is set to active by booleans below, and account plan records to display are updated
  */
  public void selectExperianSWOTRecords()
  {
    accPlanWho ='Experian';
    experianActive=true;
    clientActive=false;
    setAccPlanRecs();
  }

  /*
  Purpose:   When user clicks on 'Delete' link on a record, delete it from Salesforce
  Arguments: None, link on VF page gets the correct Account Plan SWOT id
  Return:    Nothing, record in question is deleted from Salesforce
  */
  public void deleteAccPlanSWOTRecord()
  {
    system.debug('yyyyyy' + currentRecId);
    Id testId= Id.valueOf(currentRecId.substring(0, 15));
    Account_Plan_SWOT__c recToDelete = new Account_Plan_SWOT__c(Id=testId);

    try
    {
      delete recToDelete;
      system.debug('XXXXXX' + allRelAccPlanSWOTs.size());
      for(integer i=0;i<allRelAccPlanSWOTs.size(); i++)
      {
        if(allRelAccPlanSWOTs[i].Id == recToDelete.Id)
        {
          system.debug('xxxxxx we have a match' );
          allRelAccPlanSWOTs.remove(i);
        }       
      }
      system.debug('XXXXXX' + allRelAccPlanSWOTs.size());
      system.debug('YYYYYY' + strengthAccPlanSWOTs);
      setAccPlanRecs();
    }
    catch(Exception e)
    {
      // need to add a condition here
    }
  }

  /*
  Purpose:   When user clicks the 'Close' button on the current record popup displayed on screen, popup will disappear
  Arguments: None
  Return:    Nothing, popup box will no longer be displayed when user clicks 'Close'
  */
  public void closeCurrentAccPlanSWOTRecordPopup()
  {
    // Here we're reverting values if the user clicks cancel.
    currentRec.Type__c = prevType;
    currentRec.Description__c = prevDesc;
    currentRec.Impact__c = prevImpact;
    currentRec.Importance__c = prevImportance;
    displayCurrentRecordPopup=false;
  }

  /*
  Purpose:   Displays the selected account plan SWOT record's details in a popup box on screen
  Arguments: None
  Return:    Nothing, popup box will be displayed
  */
  public void showCurrentAccPlanSWOTRecordPopup()
  {
    // bring up the relevant information for the record in question.
    Id testId= Id.valueOf(currentRecId.substring(0, 15));
    for(Account_Plan_SWOT__c singleRec : allRelAccPlanSWOTs)
    {
      if(singleRec.id == testId)
      {
        prevType = singleRec.Type__c;
        prevDesc = singleRec.Description__c;
        prevImpact = singleRec.Impact__c;
        prevImportance = singleRec.Importance__c;
        currentRec = singleRec; // this appears to work, can remove the bit above this
        system.debug('matched rec ID: ' + currentRec);
        break;
      }
    }
    displayCurrentRecordPopup=true; // before this, set up the SWOT record from the ID.
  }

  /*
  Purpose:   When user clicks 'Save' on currently selected account plan SWOT popup, will update the record
  Arguments: None, information is passed from VF page to controller when user clicks 'Save'
  Return:    Nothing, record in Salesforce will be updated
  */
  public void updateCurrentAccPlanSWOTRecord()
  {
    update currentRec; // may want to put this into a try catch block
    system.debug('mathced rec Updating:' + currentRec);
    displayCurrentRecordPopup=false;
  }

  /*
  Purpose:   When user clicks 'Cancel' on 'Add Item' popup when creating a new record, popup will disappear
  Arguments: None
  Return:    Nothing, 'Add Item' popup will disappear
  */
  public void closeNewItemPopup()
  {        
    displayPopup = false;
    newAccPlanSWOT.clear(); // Clear the account plan SWOT so that on adding another record, user has a clean slate
  }

  /*
  Purpose:   When user clicks 'Add Item' on SWOT analysis page, 'Add Item' popup will be displayed
  Arguments: None
  Return:    Nothing, 'Add Item' popup will display on screen
  */
  public void showNewItemPopup()
  {        
    displayPopup = true;
  }

  /*
  Purpose:   When user creates a new Account Plan SWOT record, this will order it into the correct list based on
             it's importance, in descending order
  Arguments: None
  Return:    Nothing, list of account plan SWOT records will be sorted by Importance, in descending order.
  */
  private void insertBasedOnImportance(List <Account_Plan_SWOT__c> accPlanSWOTList, Account_Plan_SWOT__c singleAccPlanSWOT)
  {
    for(integer i=0;i<accPlanSWOTList.size(); i++)
    {
      if(singleAccPlanSWOT.Importance__c == null)
      {
        accPlanSWOTList.add(accPlanSWOTList.size()-1, singleAccPlanSWOT);
        //break;
        return;
      }
      else if(accPlanSWOTList[i].Importance__c == null)
      {
        accPlanSWOTList.add(i, singleAccPlanSWOT);
        //break;
        return;
      }
      else if(Integer.valueOf(accPlanSWOTList[i].Importance__c) <= Integer.valueOf(singleAccPlanSWOT.Importance__c))
      {
        accPlanSWOTList.add(i,singleAccPlanSWOT); // add the item at this index
        //break;
        return;
      }
    }
    accPlanSWOTList.add(singleAccPlanSWOT);
  }
}