/**=====================================================================
 * Appirio, Inc
 * Name: AssignmentTeamMemberTriggerHandler
 * Description: Handler class for the AssignmentTeamMemberTrigger for task T-358272
 * Created Date: Feb 03rd, 2015
 * Created By: Naresh Kr Ojha(Appirio)
 *
 * Date Modified            Modified By                  Description of the update
 * Feb 18th , 2015          Gaurav Kumar Chadha          T-361103 - Populated teamMember.Assignment_Team_Role__c if it is null
  =====================================================================*/
public with sharing class AssignmentTeamMemberTriggerHandler{
  //=================================================
  // Before Insert Call
  //=================================================
  public static void beforeInsert (List<Assignment_Team_Member__c> newList) {
    setStartingValues(newList);
  }

  //===========================================================================
  // Sets Assignment Team Starting Values
  //===========================================================================
  private static void setStartingValues (List<Assignment_Team_Member__c> newList) {

    map<Id,String> userIdWithCSDATeamRole = new map<Id,String>();
    for (Assignment_Team_Member__c teamMember : newList) {
      teamMember.IsActive_Starting_Value__c = teamMember.IsActive__c;
      if (teamMember.User__c != null) {
        teamMember.User_Starting_Value__c = teamMember.User__c;
        // to get CSDA_Team_Role__c value from user
        userIdWithCSDATeamRole.put(teamMember.User__c , null);
      }
      if (teamMember.Assignment_Team_Role__c != null) {
        teamMember.Assignment_Team_Role_Starting_Value__c = teamMember.Assignment_Team_Role__c;
      }
    }

    // map populate map of userId and CSDA_Team_Role__c
    for (User user : [SELECT CSDA_Team_Role__c , ID
                     FROM User
                     WHERE ID in :userIdWithCSDATeamRole.keySet()]) {
      userIdWithCSDATeamRole.put(user.id, user.CSDA_Team_Role__c);
    }

    // populate teamMember.Assignment_Team_Role__c from user if it is not populated
    for ( Assignment_Team_Member__c teamMember  : newList) {
      if ( teamMember.Assignment_Team_Role__c == null && teamMember.User__c != null &&
                              userIdWithCSDATeamRole.containskey(teamMember.User__c)) {

        if (userIdWithCSDATeamRole.get(teamMember.User__c) != null) {
            teamMember.Assignment_Team_Role__c = userIdWithCSDATeamRole.get(teamMember.User__c);
        }
      }
    }
  }
}