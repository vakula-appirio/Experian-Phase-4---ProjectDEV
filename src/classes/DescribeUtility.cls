/**=====================================================================
 * Appirio Inc
 * Name: DescribeUtility.cls
 * Description: Utility class to avoid hitting Salesforce's describe limits
 * Created Date: 21 January 2014
 * Created By: Nathalie Le Guay (Appirio)
 *
 * Date Modified      Modified By                  Description of the update
 * Jan 30, 2014       Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 20, 2014       Nathalie Le Guay (Appirio)   Adding getPrefix() and getSObjectName()
 * Apr 01, 2014       Naresh Kr Ojha               T-266919: Added constructor and loadObjRecTypes(), getRecordTypeIdByName(), isCreateable()
 * Apr 01, 2014       Nathalie Le Guay             Created getRecordTypeIdByName(String objectName, String rtName)
 *                                                       & getRecordTypes(String objectName) & recordTypesByObjectMapMap
 * Sept 09, 2014      Naresh Kr Ojha               Added method to get picklist values of a field on object, method: getPicklistValues();
 * Sept 16th, 2014    Naresh Kr Ojha               Added method to get fields of an onject method name: getFieldMap()
 =====================================================================*/
public without sharing class DescribeUtility {
  private static Map<String, Schema.SObjectType> describeMap;
  private static Map<String, Schema.DescribeSObjectResult> objectDescribeMap = new Map<String, Schema.DescribeSObjectResult>();
  private static Schema.DescribeSObjectResult objectDescribe;
  private static Map<String, Map<String, String>> recordTypesByObjectMap = new Map<String, Map<String, String>>();

  // Holds record type by sObject+RecordType Name with recordType record
  public Map<String, String> recordTypeId_Map = new Map<String, String>();


  //==============================================================
  // Default constructor
  //==============================================================
  public DescribeUtility () {

  }

  //==============================================================
  // Constructor to load various things
  //==============================================================
  public DescribeUtility(String objName) {
    if (String.isNotEmpty(objName)) {
      loadObjRecTypes(objName);
    }
  }

  //==============================================================
  // Will retrieve the describe from the map, and initialize the value otherwise
  //==============================================================
  public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
    initDescribeMap();

    if (objectDescribeMap.get(objectName) == null) {
      System.debug('\nDescribeUtility: object describe was not in the map...Adding to map...:' + objectName);
      objectDescribe = describeMap.get(objectName).getDescribe();
      objectDescribeMap.put(objectName, objectDescribe);
    }
    return objectDescribeMap.get(objectName);
  }
  
  //==============================================================
  // Will build a string given a list of fields to concatenate
  //==============================================================
  public static String buildKey(List<String> keys, SObject obj, String objName) {
    String theKeyString = '';
    // Initialize
    getObjectDescribe(objName);

    Map<String, Schema.SObjectField> objFieldDescribe = objectDescribeMap.get(objName).fields.getMap();
    for (String key: keys) {
      Schema.SObjectField fieldDescribe = objFieldDescribe.get(key);

      String fieldValue = String.valueOf(obj.get(fieldDescribe.getDescribe().getName()));
      theKeyString += (String.isEmpty(fieldValue)) ? '' : fieldValue;
    }
    System.debug('\nDescribeUtility: Key String is: ' + theKeyString);
    return theKeyString;
  }

  //==============================================================
  // Initialize the Global Describe Map
  //==============================================================
  private static void initDescribeMap() {
    if (describeMap == null) {
      System.debug('\nDescribeUtility: global describe did not exist...Creating map.');
      describeMap = Schema.getGlobalDescribe();
    }
  }

  //==============================================================
  // Return the Name of an SObject given its Id
  //==============================================================
  public static String getSObjectName(String recordId) {
    if (String.isEmpty(recordId) || recordId.length() < 15) {
      return '';
    }
    initDescribeMap();
    String prefix = recordId.substring(0,3);
    for (Schema.SObjectType sObjectType: describeMap.values()) {
      Schema.DescribeSObjectResult result = sObjectType.getDescribe();
      String tempPrefix = result.getKeyPrefix();
      if (String.isNotEmpty(tempPrefix) && tempPrefix.equals(prefix)) {
        System.debug('\n[DescribeUtility: getSObjectName] : Found Prefix' + result.getName());
        return result.getName();
      }
    }
    return '';
  }

  //==============================================================
  // Return the prefix of an SObject given its Name
  //==============================================================
  public static String getPrefix(String objectName) {
    Schema.DescribeSObjectResult describe =  getObjectDescribe(objectName);
    if (describe == null) {
      return '';
    }
    return describe.getKeyPrefix();
  }

  //==============================================================
  // Get Record Type of an Object
  //==============================================================
  public void loadObjRecTypes(String objName) {
    Schema.DescribeSObjectResult objDescribe = getObjectDescribe(objName); //Schema.getGlobalDescribe().get(objName);
    Map<String, Schema.RecordTypeInfo> rtMapByName = objDescribe.getRecordTypeInfosByName();
    for (Schema.RecordTypeInfo rti : rtMapByName.values()) {
      recordTypeId_Map.put(rti.getName(), rti.getRecordTypeId());
    }
  }

  //==============================================================
  // Returns recordtypeId when passed object name and record name
  //==============================================================
  public String getRecordTypeIdByName (String rtName) {
    if (recordTypeId_Map.containsKey(rtName)) {
      return recordTypeId_Map.get(rtName);
    }
    return null;
  } 

  //==============================================================
  // Returns all the Record Types given an Object name
  //==============================================================
  private static Map<String, String> getRecordTypes(String objectName) {
    Schema.DescribeSObjectResult objDescribe = getObjectDescribe(objectName);

    if (!recordTypesByObjectMap.keySet().contains(objectName)) {
      System.debug('\n[DescribeUtility : getRecordTypes] RT Entries for ' + objectName + ' did not exist...Creating entry.');
      Map<String, Schema.RecordTypeInfo> rtMapByName = objDescribe.getRecordTypeInfosByName();
      for (Schema.RecordTypeInfo rti : rtMapByName.values()) {
        if (recordTypesByObjectMap.get(objectName) == null) {
          recordTypesByObjectMap.put(objectName, new Map<String, String>());
        }
        recordTypesByObjectMap.get(objectName).put(rti.getName(), rti.getRecordTypeId());
      }
    }
    return recordTypesByObjectMap.get(objectName);
  }

  //==============================================================
  // Returns recordtypeId when passed object name and record name
  //==============================================================
  public static String getRecordTypeIdByName(String objectName, String rtName) {

    initDescribeMap();
    Map<String, String> objRecordTypes = getRecordTypes(objectName);

    if (objRecordTypes.containsKey(rtName)) {
      System.debug('\n[DescribeUtility : getRecordTypes] Returning RT:' + objRecordTypes.get(rtName));
      return objRecordTypes.get(rtName);
    }
    return null;
  } 

  //==============================================================
  // Check weather the object has creatable FLS
  //==============================================================
  public static Boolean isCreateable(String objName) {
     Schema.DescribeSObjectResult objDescribe = getObjectDescribe(objName);
     if (objDescribe.isCreateable()) {
       return true;
     } else {
        return false;
     }
  }

  //===============================================================
  // Get picklist values of object and field name
  //===============================================================
  public static list<SelectOption> getPicklistValues(SObject obj, String fld){
    list<SelectOption> options = new list<SelectOption>();
    // Get the object type of the SObject.
    Schema.sObjectType objType = obj.getSObjectType(); 
    // Describe the SObject using its object type.
    Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
    // Get a map of fields for the SObject
    map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
    // Get the list of picklist values for this field.
    list<Schema.PicklistEntry> values =
       fieldMap.get(fld).getDescribe().getPickListValues();
    // Add these values to the selectoption list.
    for (Schema.PicklistEntry a : values)
    { 
      options.add(new SelectOption(a.getLabel(), a.getValue())); 
    }
    return options;
  }
  
  //====================================================================
  // Get fields map of object passed as parameter
  //====================================================================
  public static Map<String, Schema.SObjectField> getFieldMap (sObject obj) {
    // Get the object type of the SObject.
    Schema.sObjectType objType = obj.getSObjectType(); 
    // Describe the SObject using its object type.
    Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
    // Get a map of fields for the SObject
    Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
    
    return fieldMap;
  }
}