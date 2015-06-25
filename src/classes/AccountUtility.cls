/**=====================================================================
 * Appirio Inc
 * Name: AccountUtility.cls
 * Description: T-257202: AccountUtility class to store logic that will be reused by
                multiple classes in a Utility class
 * Created Date: 10th March 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified       Modified By                    Description of the update
 * March 10th, 2014    Naresh Kr Ojha (Appirio)       Added populateAccShareMap method
 * March 28th, 2014    Arpita Bose (Appirio)          T-267517:Removed references to ContactAccessLevel - Contact Sharing setting is set as 'Controlled by Parent'
 =====================================================================*/

public without sharing class AccountUtility {

  //=========================================================================
  // Method to get the records of AccountTeamMember for the given AccountIds
  //=========================================================================
  public static Map<String, List<AccountTeamMember>> fetchAccountTeamMember(Set<ID> accIDs) {
    // Map to store account IDs, and related AccountTeamMembers to each account ID.
    Map <String, List<AccountTeamMember>> accIdToListTeamMember = new Map <String, List<AccountTeamMember>>();
    List <AccountTeamMember> atmList;

    // Iterate through the AccountTeamMember to fill accIdToListTeamMember map
    for (AccountTeamMember accTeam : [SELECT Id, UserId, AccountId, AccountAccessLevel,
                                             TeamMemberRole, IsDeleted, CreatedDate
                                      FROM AccountTeamMember
                                      WHERE AccountId IN : accIDs]) {
      if (accIdToListTeamMember.containsKey(accTeam.AccountId)) {
        accIdToListTeamMember.get(accTeam.AccountId).add(accTeam);
      } else {
        atmList = new  List <AccountTeamMember>();
        atmList.add(accTeam);
        accIdToListTeamMember.put(accTeam.AccountId, atmList);
      }
    } // End of For loop
    return accIdToListTeamMember;
  } // End of fetchAccountTeamMember


  //==================================================================================================
  // Method to get the records of AccountShare for the given AccountIds and related AccountTeamMembers
  //==================================================================================================
  public static Map<String, List<AccountShare>> fetchAccountShare(Set<ID> accIDs, Map<String, List<AccountTeamMember>> accIdToListTeamMember){
    // Set to store UserIds related to AccountTeamMember
    Set<String> setUserIds = new Set<String>();
    Map<String, List<AccountShare>> accIdToListAccountshare = new Map<String, List<AccountShare>>();

    // Populating set of userIds
    for (List<AccountTeamMember> atm : accIdToListTeamMember.values()) {
      for (AccountTeamMember tempATM : atm) {
        setUserIds.add(tempATM.UserId);
      }
    }

    List <AccountShare> accShareList;
    // Loop through AccountShare to fill the accIdToListAccountshare map
    for(AccountShare accShare : [SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel,
                                        OpportunityAccessLevel, CaseAccessLevel //ContactAccessLevel T-267517:Removed references to ContactAccessLevel
                                 FROM AccountShare
                                 WHERE AccountId IN : accIDs AND UserOrGroupId = :setUserIds ]) {
      if (accIdToListAccountshare.containsKey(accShare.AccountId)) {
        accIdToListAccountshare.get(accShare.AccountId).add(accShare);
      } else {
        accShareList = new List <AccountShare>();
        accShareList.add(accShare);
        accIdToListAccountshare.put (accShare.AccountId, accShareList);
      }
    } // End of For Loop

    return accIdToListAccountshare;
  } // End of method fetchAccountShare


  //=========================================================================
  // Populating map of accountshare records of given accounts
  //=========================================================================
  public static void populateAccShareMap (Set<ID> accIDs, Map<String, AccountShare> accShareMap) {
    for (Account acc : [SELECT Id,
                          (SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel,
                                  OpportunityAccessLevel, CaseAccessLevel //ContactAccessLevel T-267517:Removed references to ContactAccessLevel
                           FROM Shares)
                        FROM Account
                        WHERE ID IN : accIDs]) {
      for (AccountShare accShare : acc.Shares) {
        if (!accShareMap.containsKey(accShare.AccountId+'~~'+accShare.UserOrGroupId)) {
          accShareMap.put (accShare.AccountId+'~~'+accShare.UserOrGroupId, accShare);
        }
      }
    }
  }

}