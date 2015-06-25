/**=====================================================================
 * Appirio Inc
 * Name: BusinessUnitUtility.cls
 * Description: T-314193
 * Created Date: Aug 26th, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified       Modified By                    Description of the update
 * Oct 06th, 2014      Naresh kr Ojha                 Added method getGroupNameForBusinessUnits() to get groupname of multiple users
 * Nov 21st, 2014      Nathalie Le Guay               T-333542: remove userId == UserInfo.getUserId() check in getBusinessUnit() because Id is passed as parameter
 * Apr 20th, 2015      Paul Kissick                   Case #593979 - Removed SOQL queries, and utilised caching of custom settings (reduces SOQL count)
 =====================================================================*/
  public with sharing class BusinessUnitUtility{
    private static Map<String, String> userToBUMap = new Map<String, String>();
    
    // Utility method to return the Alternative Renewal Owner (EDQ Renewals)
    public static String getAltRenewalOwner(String userBusUnit) {
     if (String.isNotBlank(userBusUnit)) {
       for(Business_Unit_Group_Mapping__c busUnit : Business_Unit_Group_Mapping__c.getall().values()) {
         if (busUnit.User_Business_Unit__c != null && busUnit.User_Business_Unit__c == userBusUnit) {
           return busUnit.Alternative_Renewal_Owner__c;
         }
       }
     }
     return null;
    }

    // common utility method to get Business Unit
    public static String getBusinessUnit(Id userId) {
      // List<Business_Unit_Group_Mapping__c> custSettingLst;
      // check the Business Unit for current User
     //if (userId == UserInfo.getUserId()) { NLG 2014-11-21
      if (userToBUMap.get(userId) != null) {
        return userToBUMap.get(userId);
      }
      for (User user : [SELECT Id, Global_Business_Line__c, Business_Line__c, Business_Unit__c
                         FROM User WHERE Id =: userId]) {
         
         String userBusiUnit = user.Business_Unit__c;
         if (userBusiUnit <> null) {
           // if it exists in "Business Unit Group Mapping" custom setting in the "User Business Unit" field.
            // the value in that setting's "Common Group Name" field should be returned.
            // else return an empty string.
           
           for(Business_Unit_Group_Mapping__c busUnit : Business_Unit_Group_Mapping__c.getall().values()) {
           	 if (busUnit.User_Business_Unit__c != null && busUnit.User_Business_Unit__c == userBusiUnit) {
           	 	 userToBUMap.put(user.Id, busUnit.Common_Group_Name__c);
           	 	 return busUnit.Common_Group_Name__c;
           	 }
           }
           /*
           custSettingLst = [SELECT Id, Common_Group_Name__c, User_Business_Unit__c
                               FROM Business_Unit_Group_Mapping__c
                               WHERE User_Business_Unit__c =: userBusiUnit];
                              
             if (custSettingLst.size() > 0) {
               userToBUMap.put(user.Id, custSettingLst.get(0).Common_Group_Name__c);
               return custSettingLst.get(0).Common_Group_Name__c;
             }
             */                     
          }
          else {
            userToBUMap.put(user.Id, '');
          }
       }
     //}
     return null;
   }

   // common utility method to get Business Unit and related group name
   public static Map<String, String> getGroupNameForBusinessUnits(Set<String> businessUnitSet) {
     
     Map<String, String> bu_GroupMap = new Map<String, String>();
     
     //Getting group name for Business units
     for(Business_Unit_Group_Mapping__c busUnit : Business_Unit_Group_Mapping__c.getall().values()) {
	     if (busUnit.User_Business_Unit__c != null && businessUnitSet.contains(busUnit.User_Business_Unit__c)) {
	       if (String.isNotBlank(busUnit.Common_Group_Name__c) && String.isNotBlank(busUnit.User_Business_Unit__c)) {
	         bu_GroupMap.put(busUnit.User_Business_Unit__c, busUnit.Common_Group_Name__c);
	       }
	     }
	   }
	   /*
     for (Business_Unit_Group_Mapping__c mapping : [SELECT Id, Common_Group_Name__c, User_Business_Unit__c
                              FROM Business_Unit_Group_Mapping__c
                              WHERE User_Business_Unit__c  IN: businessUnitSet]) {
        if (!String.isBlank(mapping.Common_Group_Name__c) && !String.isBlank(mapping.User_Business_Unit__c)) {
           bu_GroupMap.put(mapping.User_Business_Unit__c, mapping.Common_Group_Name__c);
        }
     }
     */
     return bu_GroupMap;
   }

    public static Set<String> getBUsFromGroupNames(Set<String> groupNames) {
      Set<String> buSet = new Set<String>();
     
     //Getting group name for Business units
     for(Business_Unit_Group_Mapping__c busUnit : Business_Unit_Group_Mapping__c.getall().values()) {
       if (busUnit.Common_Group_Name__c != null && groupNames.contains(busUnit.Common_Group_Name__c)) {
         if (String.isNotBlank(busUnit.Common_Group_Name__c) && String.isNotBlank(busUnit.User_Business_Unit__c)) {
           buSet.add(busUnit.User_Business_Unit__c);
         }
       }
     }
     /*
     for (Business_Unit_Group_Mapping__c mapping : [SELECT Id, Common_Group_Name__c, User_Business_Unit__c
                              FROM Business_Unit_Group_Mapping__c
                              WHERE Common_Group_Name__c  IN: groupNames]) {
        if (!String.isBlank(mapping.Common_Group_Name__c) && !String.isBlank(mapping.User_Business_Unit__c)) {
           //if (!groupMap_BU.containsKey(mapping.Common_Group_Name__c)) {
           //  groupMap_BU.put(mapping.Common_Group_Name__c, new Set<String>());
           //}
           //groupMap_BU.get(mapping.Common_Group_Name__c).add(mapping.User_Business_Unit__c);
           buSet.add(mapping.User_Business_Unit__c);
        }
     }
     */
     return buSet;
    }

 }