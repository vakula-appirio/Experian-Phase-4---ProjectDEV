/**=====================================================================
 * Appirio, Inc
 * Name: AddDefaultAccountTeam_Controller
 * Description: 
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 03rd, 2014               Arpita Bose (Appirio)        T-243282: Added constants in place of string.
 * Mar 28th, 2014               Arpita Bose (Appirio)        T-267517:Removed references to ContactAccessLevel - Contact Sharing setting is set as 'Controlled by Parent'
 =====================================================================*/
public without sharing class AddDefaultAccountTeam_Controller {
    
    private final Account acct;
    
    public AddDefaultAccountTeam_Controller(ApexPages.StandardController stdController){
        this.acct = (Account)stdController.getRecord();
        
        List<UserAccountTeamMember> uatm = [SELECT AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, TeamMemberRole, OwnerId, UserId FROM UserAccountTeamMember where UserId = :UserInfo.getUserId()];
    }
    
    public void addTeamMember(){
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = acct.id;
        atm.UserId = [select id from User where IsActive=true and Profile.Name =: Constants.PROFILE_EXP_SALES_MANAGER limit 1].id;//'005c0000000l5YX';
        atm.TeamMemberRole = Constants.TEAM_ROLE_ACCOUNT_MANAGER ;
        insert atm;
        
        AccountShare accShare = new AccountShare();
        accShare.UserOrGroupId = atm.UserId; 
        accShare.AccountId = acct.Id;
        accShare.AccountAccessLevel = Constants.ACCESS_LEVEL_READ ;
        accShare.OpportunityAccessLevel = Constants.ACCESS_LEVEL_READ ;
        //accShare.ContactAccessLevel = Constants.ACCESS_LEVEL_READ ; T-267517:Removed references to ContactAccessLevel
        insert accShare;
    }
}