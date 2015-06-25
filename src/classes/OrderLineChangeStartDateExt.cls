/**=====================================================================
 * Appirio, Inc
 * Name: OrderLineChangeStartDateExt
 * Description: T-270940: Delivery Management: VF Page
 * Created Date: Apr 11th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public with sharing class OrderLineChangeStartDateExt {
  
  //To check access on page
  public Boolean haveAccess{get;set;}
  //Constrcutor
  public OrderLineChangeStartDateExt(ApexPages.StandardController controller) {
    haveAccess = true;
  }
  
  //Check access of valid user to update start date of current Order Line Item
  public Pagereference checkIfUserAllowed() {
    
    Set<ID> delMangementGroupMemberIDs = new Set<ID>();
    Set<ID> profilesHaveAccess_IDs = new Set<ID>();
    //Add profile name for which we need to provide access
    Set<String> profileNamesToGrantAccess = new Set<String>{Constants.PROFILE_SYS_ADMIN, Constants.PROFILE_EXP_SALES_ADMIN};
    
    //Fetching Delivery Management group members
      for (Group grp : [Select ID, (Select ID, UserOrGroupId From GroupMembers) 
            From Group g Where Name =: Constants.GROUP_DELIVERY_MANAGEMENT]) {
        for (GroupMember gm : grp.GroupMembers) {
            delMangementGroupMemberIDs.add(gm.UserOrGroupId);
        }
      }

    //Profile IDs to grant access
    for (Profile p : [SELECT ID FROM Profile WHERE Name IN: profileNamesToGrantAccess]) {
        profilesHaveAccess_IDs.add(p.ID);
    }
    
    //Check access
    if (!profilesHaveAccess_IDs.contains(UserInfo.getProfileId()) && !delMangementGroupMemberIDs.contains(UserInfo.getUserId())) {
      haveAccess = false;
      Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.WARNING, Label.ORDER_LINE_NO_ACCESS);
      Apexpages.addmessage(msg);
    }
    return null;
  }
}