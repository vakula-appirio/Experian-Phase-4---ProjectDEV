/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentController
 * Description: T-372669 - Controller supporting AccountSegment.page,
 *              which overrides the "View" standard behavior
 *
 * Created Date: March 22nd, 2015
 * Created By: Nathalie Le Guay (Appirio)
 *
 * Date Modified            Modified By           Description of the update
 * Apr 28th, 2015           Nathalie Le Guay      Added Histories related list
 ======================================================================*/
public with sharing class AccountSegmentController {
  public  Account_Segment__c segment          {get;set;}
  public List<Schema.FieldSetMember> fieldSet {get;set;}
  public Boolean isEdit                       {get;set;}
  public String title                         {get;set;}
  public String segmentMapEntryName           {get;set;}

  //===========================================================================
  // Controller
  // @Description: Will query the record and set the title to display as well
  // as find the correct Field Set to display, if any
  //===========================================================================
  public AccountSegmentController(ApexPages.standardController controller) {
    this.segment = (Account_Segment__c) controller.getRecord();
    // This query needs to loop through all fields dynamically

    String query = 'SELECT ';
    Integer i = 0;
    for (Schema.SObjectField key : DescribeUtility.getFieldMap(segment).values()) {
      if (i == 0) {
        query += key.getDescribe().getName();
      } else {
        query += ', ' + key.getDescribe().getName();
      }
      i++;
    }
    query += ', Segment__r.Value__c, Segment__r.Parent__r.Value__c, Segment__r.Parent__r.Parent__r.Value__c ';
    query += ', (SELECT CreatedById, CreatedBy.Name, CreatedDate, Field, OldValue, NewValue From Histories) ';
    query += ' FROM Account_Segment__c WHERE Id = \'' + segment.Id + '\'';
    this.segment = Database.query(query);

    // Setting up the title
    String firstLevel = '';
    String businessLine = '';
    String businessUnit = '';
    if (segment.Segment_Type__c != null) {
      if (segment.Segment_Type__c.equalsIgnoreCase('Region') ||
          segment.Segment_Type__c.equalsIgnoreCase('Country') ||
          segment.Segment_Type__c.equalsIgnoreCase('Global Business Line')) {
        firstLevel = segment.Segment__r.Value__c;
      }
      if (segment.Segment_Type__c.equalsIgnoreCase('Business Line')) {
        firstLevel = segment.Segment__r.Parent__r.Value__c;
        businessLine = segment.Segment__r.Value__c;
      }
      if (segment.Segment_Type__c.equalsIgnoreCase('Business Unit')) {
        firstLevel = segment.Segment__r.Parent__r.Parent__r.Value__c;
        businessLine = segment.Segment__r.Parent__r.Value__c;
        businessUnit = segment.Segment__r.Value__c;
      }
    }

    List<Account_Segmentation_Mapping__c> segmentMap = [SELECT Id, Name, Common_View_Name__c, Field_Set_API_Name__c,
                                                               Global_Business_Line__c, Business_Line__c, Business_Unit__c
                                                        FROM Account_Segmentation_Mapping__c
                                                        WHERE Name =: segment.Segment__r.Value__c];

    if (segmentMap != null && segmentMap.size() == 1) {
      String fieldSetId = segmentMap.get(0).Field_Set_API_Name__c;
      String segmentName = segmentMap.get(0).Name;
      Map<String, Schema.FieldSet> fieldSets = Schema.SObjectType.Account_Segment__c.fieldSets.getMap();
      if (!String.isEmpty(fieldSetId) && fieldSets.containsKey(fieldSetId)) {
        fieldSet = fieldSets.get(fieldSetId).getFields();
        segmentMapEntryName = segmentName;
      }
    }

    isEdit = false;


    title = firstLevel;
    if (businessLine != '') {
      title += ' > ' + businessLine;
    }
    if (businessUnit != '') {
      title += ' > ' + businessUnit;
    }
  }

  //===========================================================================
  // Sets the isEdit parameter to display the inputFields
  //===========================================================================
  public PageReference edit() {
    isEdit = true;
    return null;
  }

  //===========================================================================
  // Saves the updated record to the database
  //===========================================================================
  public PageReference save() {
    if (segment.Segment__c == null) {
       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please fill Segment before saving'));
       return null;
    }
    isEdit = false;
    update segment;
    return null;
  }

  //===========================================================================
  // Displays the read only mode
  //===========================================================================
  public PageReference cancel() {
    isEdit = false;
    return null;
  }

}