/**=====================================================================
 * Appirio, Inc
 * Name: Constants
 * Description: Class to hold constants used throughout the application
 * Created Date: Feb 03rd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified        Modified By                  Description of the update
 * 02/07/2014           Sadar Yacob                  Added Constants for CaseTriggerHandler 
 * Feb 12th, 2014       Nathalie Le Guay             Added GLOBAL_SETTING 
 * Feb 16th, 2014       Nathalie Le Guay             Merge to add OPPTY_CLOSED_LOST and OPPTY_STATUS_LOST back
 * Feb 20th, 2014       Nathalie Le Guay (Appirio)   Adding SObject Names
 * Feb 26th, 2014       Nathalie Le Guay             Adding Activity Types
 * Feb 28th, 2014       Nathalie Le Guay             Adding Profile & Account Team Roles
 * Mar 03rd, 2014       Arpita Bose (Appirio)        Added Constants for Access Level, Node Type
 * Mar 04th, 2014       Arpita Bose (Appirio)        Added Constansts for Trigger Names
 * Mar 18th, 2014       Naresh Kr Ojha               Added Oppty type renwal constant
 * Mar 21st, 2014       Nathalie Le Guay             Added ORDERTYPE_TRIAL
 * Mar 07th, 2014       Nathalie Le Guay             Added ORDER_LINE_ITEM_RENEWAL_ONE_OFF & ORDER_RENEWAL
 * Apr 07th, 2014       Arpita Bose                  Added RECORDTYPE_MASS_TRANSFER_REQUEST
 * Apr 09th, 2014       Nathalie Le Guay             Added SOBJECT_ORDER_REVENUE_SCHEDULE, REGION_INDIA,
 *                                                   REGION_LATAM, REGION_EMEA, REGION_NA, REGION_UKI
 *                                                   STATUS_NEW, CASE_TYPE_INTERNAL, STATUS_PENDING
 * Apr 10th, 2014       Nathalie Le Guay             PROFILE_EXP_SALES_ADMIN becomes 'Experian Sales Effectiveness'
 * Apr 11th, 2014       Naresh Kr Ojha               GROUP_DELIVERY_MANAGEMENT added 'Delivery Management'
 * Apr 16th, 2014       Jinesh Goyal                 Added Constants for picklist values in User.Global_Business_Line__c
 * Apr 17th, 2014       Nathalie Le Guay             Added STATUS_ACTIVE
 * Apr 18th, 2014       Rahul Jain                   Added Constant -for trigger ESDEL_TimecardTrigger (for T-270393 and T-270392) 
 * Apr 23rd, 2104       Rahul Jain                   Added Constant -for Case Type - CASE_TYPE_SPAIN_DELIVERY_TASK(for T-270394)
 * Apr 28th, 2014       Arpita Bose                  Added Constant ADDRESS_CA_AIAU_BIBU_TRIGGER 
 * Apr 28th, 2014       Rahul Jain                   Added Constants.OPPORTUNITY_PLAN_TRIGGER for (T-273695)
 * May 1st,  2014       Rahul Jain                   Added Constants.ACCOUNT_PLAN_TEAM_TRIGGER for (T-275542)
 * May 7th,  2014       Rahul Jain                   Added Constants ACCOUNT_PLAN_SWOT_TRIGGER,ACCOUNT_PLAN_OPPORTUNITY_TRIGGER for T-276704, T-276706
 * May 20th, 2014       Jinesh Goyal                 Added STATUS_INACTIVE 
 * Aug 20th, 2014       Arpita Bose                  Added SOBJECT_PROJECT
 * Sep 08th, 2014       Arpita Bose                  Added Constants for CaseTrigger_ResolutionTime
 * Sep 16th, 2014       Arpita Bose                  Added Constant CASE_REC_TYPE_EDQ_GPD_CASE
 * Sep 17th, 2014       Arpita Bose                  Added constants for T-319512
 * Sep 18th, 2014       Noopur (Appirio)             Added constants for a profile T-320438
 * Sep 19th, 2014       Nathalie Le Guay             Added EDQ
 * Sep 23rd, 2014       Arpita Bose                  Added OPPTY_CONTACT_ROLE_RENEWAL and OPPTY_CONTACT_ROLE_UPDATE
 * Sep 18th, 2014       James Weatherall             Case #6875: Added TEAM_ROLE_STRAT_ACCOUNT_MANAGER
 * Sep 28th, 2014       Nathalie Le Guay             Added TIMECARD_TYPE_DELIVERY and TIMECARD_TYPE_TRAVEL
 * Sep 26th, 2014       Arpita Bose                  Added Constants for T-322814
 * Oct 1st, 2014        Nathalie                     Added RECORDTYPE_CASE_EDQ_COMMERCIAL, RECORDTYPE_CASE_SPANISH, RECORDTYPE_CASE_EDQ
 * Oct 6/7th, 2014      Nathalie                     Added SOBJECT_ASSET, REGION_LATIN_AMERICA, REGION_GLOBAL, OPPTY_SALES_PROCESS_STANDARD
 * Oct 9th,  2014       Noopur                       Added Constant for Opportunity Type Credited
 * Oct 13th, 2014       Pallavi Sharma               Added Constant for Order Line Item Delivery Method
 * Oct 20th, 2014       Arpita Bose                  Updated for task T-326528
 * Oct 21st, 2014       Arpita Bose                  Added Constant SOBJECT_USER
 * Oct 22th, 2014       Pallavi Sharma               Added Constant for Country Japan
 * Oct 27th, 2014       Nathalie Le Guay             Added ASSET_ITEM_NUMBER and ASSET_QUOTE_NUMBER
 * Nov 03rd, 2014       Nathalie Le Guay             I-137453: COPS Roles
 * Nov 25th, 2014       Naresh Kr Ojha               Added : EDQ user types on user object for field EDQ_User_Type__c 
 * Dec 03rd, 2014       Arpita Bose                  Added Constants for RLI.Type__c and RLI.Status__c
 * Dec 05th, 2014       James Weatherall             Case #9748 Pre Sales Support Constants SALES_SUPPORT_REQUEST_TRIGGER, SOBJECT_SALES_SUPPORT_REQUEST, REDIRECT_PRE_SALES_SUPPORT
 * Dec 23rd, 2014       Nathalie                     Added ASSET_IMPLEMENTATION_ON_DEMAND
 * Jan 13th, 2015       Arpita Bose                  Added Constants for T-349831
 * Jan 19th, 2015       Naresh Kr Ojha               Added Constants for String Ignore and Service.
 * Jan 21st, 2015       Arpita Bose                  Added Constant  ACCOUNT_ASSIGNMENT_TEAM_TRIGGER
 * Jan 28th, 2015       Naresh Kr Ojha               Added ACCOUNTPLAN_CSF_TRIGGER
 * Feb 02nd, 2015       Naresh Kr Ojha               Added String Constants for Positive and Negative string values.
 * Feb 10th, 2015       Gaurav Kumar Chadha          Added String Constant for Order Type Free Trial
 * Feb 18th, 2015       Arpita Bose                  Added constants BUSINESSPROCESS_TRIGGER
 * Feb 20th, 2015       Arpita Bose                  Updated for deployment of S-281999 to merge the code of DevOppStag 
 * Feb 24th, 2015       Gaurav Kumar Chadha          Added constant for Picklist value buisnessProcessItem.Status__c i.e READY
 * Feb 26th, 2015       Gaurav Kumar Chadha          Added constant  MEMBERSHIP_CHANGE_TYPE_STATUS , MEMBERSHIP_CHANGE_TYPE_OWNER 
                                                     MEMBERSHIP_HISTORY_OWNER_TYPE_USER , HISTORY_OWNER_TYPE_USER , HISTORY_OWNER_TYPE_QUEUE
 * Feb 26th, 2015       James Weatherall             Added ACTIVITY_TYPE_CROSS_BUSINESS_UNIT
 * Mar 3rd,  2015       Gaurav Kumar Chadha          Added constact for ContractTrigger , VALIDATION_STATUS_FAIL , Agency 
 * Mar 4th, 2015        James Weatherall             Case #542997: Added Case Record Types for SLA Metrics
 * Mar 11th, 2015       Terri Kellough               Changed ASSET_TRIGGER = 'AssertTrigger' to ASSET_TRIGGER = 'AssetTrigger'
 * Mar 11th, 2015       Diego Olarte                 Case #583716: OpportunityContactAddressTriggerHandler
 * Mar 23rd, 2015       Nathalie Le Guay             T-372844: Update OPPTY_CONTACT_ROLE_PURCHASE_LEDGER from 'Purchase Ledger' to 'Bill-To'
 * Mar 26th, 2015       Terri Kellough               Changed MEMBERSHIP_CHANGE_TYPE_STATUS to CHANGE_TYPE_STATUS as a part of 
 * Mar 27th, 2015       Naresh Kr                    Added STR_QUEUE constant.
 * Apr 01st, 2015       Terri Kellough               T-375024 Added BUSINESSPROCESSTEMPLATEITEM_TRIGGER, PROFILE_EXP_ATTORNEY_MEMBERSHIP, PERMISSIONSET_BPT_ADMINISTRATOR
 * Apr 3th, 2015        Nur Azlini                   Case #555032: Added STATUS_EXPIRED
 * Apr 08th, 2015       Terri Kellough               Added Business Process Template constants section
 * Apr 10th, 2015       Terri Kellough               Changed RELATED_TO_MEMBERSHIPS from Memberships to Membership
 * Apr 13th, 2015       Paul Kissick                 Case #607717: Added ORDER_TYPE_CREDIT_NOTE
 * Apr 15th, 2015       Nathalie Le Guay             Added ACCOUNT_SEGMENT_*
 * Apr 20th, 2015       Paul Kissick                 Case #593979: Added TEAM_ROLE_RENEWAL_OWNER
 * Apr 22nd, 2015       Arpita Bose                  I-156139: Added CPQ_USERTYPE_*
 * Apr 23th, 2014       Richard Joseph               Case # 00607940- Added RPI % and RPI Amount field names for Asset
 * Apr 27th, 2015       Nathalie Le Guay             Adding MEMBERSHIP_TRIGGER
 * Apr 29th, 2015       Noopur                       Added constants for EMS case functionality
 * Apr 29th, 2015       Arpita Bose                  Added constants CASE_COMMENT_TRIGGER
 * May 01st, 2015        Terri Kellough               Added ORDER_TYPE_NEW_FROM_NEW 
 * May 09th, 2015        Nathalie Le Guay             Added new Oppty close reasons: OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_COMP_CAP,
 *                                                   *EXP_STRATEGIC_DECISION, INADEQUATE_SERVICE_REC
 * May 19th, 2015       Nur Azlini                    Case #630336 - Added new EDQ COPS Group
 ===========================================================================*/

public with sharing class Constants {


  public static Boolean OPPTY_CHECK_SKIPPING = true;
  public static final String ACCESS_LEVEL_EDIT = 'Edit';
  public static final String ACCESS_LEVEL_READ = 'Read';
  public static final String ACCESS_LEVEL_NONE = 'None';
  public static final String ACCESS_LEVEL_ALL = 'All';
  public static final String READ_ONLY = 'Read Only';
  public static final String OPEN = 'Open';
  public static final String READY = 'Ready';
  public static final String ORDER = 'Order';
  public static final String OPPTY_CLOSED_WON = 'Won - Implemented';
  public static final String INSTALLMENT_PERIOD_DAILY = 'Daily';
  public static final String INSTALLMENT_PERIOD_WEEKLY = 'Weekly';
  public static final String INSTALLMENT_PERIOD_MONTHLY = 'Monthly';
  public static final String INSTALLMENT_PERIOD_QUATERLY = 'Quarterly';
  public static final String INSTALLMENT_PERIOD_YEARLY = 'Yearly';
  public static final String REVENUE_SCHEDULED_TYPE_REPEAT = 'Repeat';
  public static final String REVENUE_SCHEDULED_TYPE_REVENUE = 'Revenue';
  public static final String WON_IMPL = 'Won - Implemented';
  public static final String STATUS_ACTIVE = 'Active';
  public static final String STATUS_INACTIVE = 'Inactive';

  //added for USD integration
  public static final String USD_USERID = 'C01775A';
  public static final String USD_PASSWD = 'Sept@2014';

  //Trigger Names
  public static final String ACCOUNT_TRIGGER = 'AccountTrigger';
  public static final String ACCOUNT_ADDRESS_TRIGGER = 'AccountAddressTrigger';
  public static final String ADDRESS_CA_AIAU_TRIGGER = 'Address_CA_AIAU';
  public static final String ADDRESS_CA_BIBU_TRIGGER = 'Address_CA_BIBU';
  public static final String CASE_TRIGGER = 'CaseTrigger';
  public static final String CONTACT_ADDRESS_TRIGGER = 'ContactAddressTrigger';
  public static final String CONTACT_TRIGGER = 'ContactTrigger';
  public static final String CONTRACT_TRIGGER = 'ContractTrigger';
  public static final String FILTER_CHATTER_FEED_COMMENT_TRIGGER = 'FilterChatterFeedComment';
  public static final String FILTER_CHATTER_FEED_ITEM_TRIGGER = 'FilterChatterFeedItem';
  public static final String LEAD_TRIGGER = 'LeadTrigger';
  public static final String OPPTY_LINE_ITEM_TRIGGER = 'OpportunityLineItemTrigger';
  public static final String OPPORTUNITY_TRIGGER = 'OpportunityTrigger';
  public static final String TASK_TRIGGER = 'TaskTrigger';
  public static final String CONFINFO_TRIGGER = 'ConfidentialInformationTrigger';
  public static final String OPPTYTEAMMEMBER_TRIGGER = 'OpportunityTeamMemberTrigger';
  public static final String ARIAPLAN_TRIGGER = 'ARIAPlanTrigger';
  public static final String USER_TRIGGER = 'UserTrigger';  
  public static final String ESDEL_TIMECARD_TRIGGER = 'ESDEL_TimecardTrigger';
  public static final String ADDRESS_CA_AIAU_BIBU_TRIGGER = 'Address_CA_AIAU_BIBU';
  public static final String OPPORTUNITY_PLAN_TRIGGER = 'Opportunity_PlanTrigger';
  public static final String ACCOUNT_PLAN_TEAM_TRIGGER = 'Account_Plan_TeamTrigger';
  public static final String ACCOUNT_PLAN_SWOT_TRIGGER = 'Account_Plan_SWOTTrigger';
  public static final String ACCOUNT_PLAN_OPPORTUNITY_TRIGGER = 'Account_Plan_OpportunityTrigger';
  public static final String ASSET_TRIGGER = 'AssertTrigger';
  public static final String DELIVERY_LINE_TRIGGER = 'DeliveryLineTrigger';
  public static final String ACCOUNT_ASSIGNMENT_TEAM_TRIGGER = 'AccountAssignmentTeamTrigger';
  public static final String ACCOUNTPLAN_CSF_TRIGGER = 'AccountPlan_CSF_Trigger';
  public static final String ACCOUNTPLANCOMPETITOR_TRIGGER = 'AccountPlanCompetitorTrigger';
  public static final String ASSIGNMENTTEAMMEMBER_TRIGGER = 'AssignmentTeamMemberTrigger';
  public static final String BUSINESSPROCESSITEM_TRIGGER = 'BusinessProcessItemTrigger';
  public static final String DEPLOYMENT_TRIGGER = 'DeploymentTrigger';
  public static final String SALES_SUPPORT_REQUEST_TRIGGER = 'SalesSupportRequestTrigger';
  public static final String BUSINESSPROCESS_TRIGGER = 'BusinessProcessTrigger';
  public static final String BUSINESSPROCESSTEMPLATEITEM_TRIGGER = 'BusinessProcessTemplateItemTrigger';
  public static final String ORDER_TRIGGER = 'OrderTrigger';
  public static final String OPPORTUNITY_CONTACT_ADDRESS_TRIGGER = 'OpportunityContactAddressTrigger';
  public static final String MEMBERSHIP_TRIGGER = 'MembershipTrigger';

  // Custom Settings Constants
  public static final String GLOBAL_SETTING = 'Global';
  

  public static final String OPPTY_STAGE_3 = System.Label.OPPTY_STAGE_QUALIFY; // '3 - Qualify opportunity';
  public static final String OPPTY_STAGE_4 = System.Label.OPPTY_STAGE_PROPOSE; // '4 - Tailor and present solutions';
  public static final String OPPTY_STAGE_5 = System.Label.OPPTY_STAGE_COMMIT; // '5 - Negotiate sale';
  public static final String OPPTY_STAGE_6 = System.Label.OPPTY_STAGE_CONTRACT; //'6 - Negotiate contract';
  public static final String OPPTY_STAGE_7 = System.Label.OPPTY_STAGE_EXECUTE; // '7 - Implement solution';
  public static final String OPPTY_STAGE_SETUP = 'Set-up';
  public static final String STAGE_CLOSED_WON = System.Label.OPPTY_STAGE_EXECUTE; //'7 - Implement solution';
  public static final String OPPTY_CLOSED_LOST = 'Closed Lost';
  public static final String OPPTY_STAGE_CLOSED_WON = 'Closed Won';
  public static final String OPPTY_STATUS_LOST = 'Lost';
  public static final String OPPTY_STAGE_EXECUTION = 'Execution';
  public static final String DECIDER = 'Decider';
 
  public static final String PRIMARY_REASON_WLC_DATA_QUALITY = 'Data Quality';
  public static final String PRIMARY_REASON_WLC_TERMS = 'Terms';
  public static final String PRIMARY_REASON_WLC_COMPETITION = 'Competition';
  public static final String STANDARD_PRICE_BOOK = 'Standard Price Book';


  public static final String ORDERTYPE_TRIAL = 'Trial';
  public static final String ORDER_LINE_ITEM_RENEWAL_ONE_OFF = 'One-off Sale';
  public static final String ORDER_RENEWAL = 'Renewal';
  public static final String ORDER_TYPE_CREDITED = 'Credited';
  public static final String ORDER_TYPE_CREDIT_NOTE = 'Credit Note';
  public static final String ORDER_TYPE_NEW_FROM_NEW = 'New From New'; //May 1st, 2015 - added by ttk

  public static final String PARAM_NAME_RETURL = 'retURL';
  public static final String STATUS_COMPLETED = 'Completed';
  public static final String STATUS_NEW = 'New';
  public static final String STATUS_PENDING = 'Pending';
  public static final String STATUS_EXPIRED = 'Expired';

  // Objects
  public static final String SOBJECT_EVENT = 'Event';
  public static final String SOBJECT_TASK = 'Task';
  public static final String SOBJECT_MKTG_ACTIVITY = 'ELQA_Marketing_Activity__c';
  public static final String SOBJECT_CONTACT = 'Contact';
  public static final String SOBJECT_CASE = 'Case';
  public static final String SOBJECT_ACCOUNT = 'Account';
  public static final String SOBJECT_OPPORTUNITY = 'Opportunity';
  public static final String SOBJECT_CAMPAIGN = 'Campaign';
  public static final String SOBJECT_ORDER = 'Order__c';
  public static final String SOBJECT_ORDER_LINE_ITEM = 'Order_Line_Item__c';
  public static final String SOBJECT_ORDER_REVENUE_SCHEDULE = 'Order_Revenue_Schedule__c'; 
  public static final String SOBJECT_PROJECT = 'Project__c';
  public static final String SOBJECT_ASSET = 'Asset';
  public static final String SOBJECT_USER = 'User';
  public static final String SOBJECT_CONFIDENTIAL_INFO = 'Confidential_Information__c';
  public static final String SOBJECT_SALES_SUPPORT_REQUEST = 'Sales_Support_Request__c';
  public static final String SOBJECT_CONTRACT = 'Contract__c';
  public static final String SOBJECT_MEMBERSHIP = 'Membership__c';
  

  // Profile
  public static final String PROFILE_EXP_SALES_EXEC = 'Experian Sales Executive';
  public static final String PROFILE_SYS_ADMIN = 'System Administrator';
  public static final String PROFILE_EXP_SALES_ADMIN = 'Experian Sales Effectiveness';
  public static final String PROFILE_EXP_SALES_MANAGER = 'Experian Sales Manager';
  public static final String PROFILE_EXP_FINANCE = 'Experian Finance';
  public static final String PROFILE_EXP_SALES_SUPPORT = 'Experian Sales Support';
  public static final String PROFILE_EXP_PROJ_DELIVERY_MANAGER = 'Experian Project / Delivery - Manager';
  public static final String PROFILE_EXP_ATTORNEY_MEMBERSHIP = 'Experian Attorney / Membership';    
  
  //permission sets
  public static final String PERMISSIONSET_BPT_ADMINISTRATOR = 'Business_Process_Template_Administrator';
  public static final String PERMISSIONSET_EDQ_SAAS_DEPLOYMENT_MANAGER = 'EDQ_SaaS_Deployment_Manager';
    
  // Roles
  public static final String ROLE_GLOBAL_ADMIN = 'Global Admin';
  public static final String ROLE_SALES_EXEC_RETAIL_PROPERTY = 'UK&I MS CI&T Retail & Property Sales';
  public static final String ROLE_NA_COPS = 'NA MS EDQ Customer Operations';
  public static final String ROLE_UKI_COPS = 'UK&I MS EDQ Customer Operations';

  // Team Role
  public static final String TEAM_ROLE_SALES_REP = 'Sales Rep';
  public static final String TEAM_ROLE_SALES_MANAGER = 'Sales Manager';
  public static final String TEAM_ROLE_ACCOUNT_MANAGER = 'Account Manager';
  public static final String TEAM_ROLE_STRAT_ACCOUNT_MANAGER = 'Strategic Account Manager'; // 09182014 JW - Case #6875
  public static final String TEAM_ROLE_CHANNEL_MANAGER = 'Channel Manager';
  public static final String TEAM_ROLE_PRE_SALES_CONSULTANT = 'Pre-Sales Consultant'; // 14th April, 2015 JW - Case #9748
  public static final String TEAM_ROLE_DELIVERY_TEAM = 'Delivery Team';
  public static final String TEAM_ROLE_LEAD_QUALIFIER = 'Lead Qualifier';
  public static final String TEAM_ROLE_RENEWAL_OWNER = 'Renewal Owner'; // 20/4/15 PK: Case #593979 
  public static final String CASE_TEAM_ROLE_REQUESTOR = 'Requestor';

  //OLI
  public static final String CURRENCY_GBP = 'GBP';
  public static final String CURRENCY_USD = 'USD';
  public static final String CURRENCY_EUR = 'EUR';
  public static final String CURRENCY_AUD = 'AUD';

  public static final String CORPORATE_ISOCODE = 'USD';
  public static final String PRODUCT_COMPLEX = 'Complex';
  public static final String PRODUCT_SIMPLE_COMPLEX = 'Simple / Complex';


  //Closed/Lost labels for Opportunity used by OpportunityClosedLostExtension.cls
  public static final String OPPTY_PRIMARY_CLOSED_REASON_OTHER = 'Other';
  public static final String OPPTY_STAGE_NO_DECISION = 'Closed No Decision';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_ASPROJECT = 'Abandon/Stalled Project';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_EXPERION_NO_GO_DECISION = 'Experian No Go Decision';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_CUSTOMER_UNDECIDED = 'Customer Undecided';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_NO_BUDGET = 'No/Insufficient Budget';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_DATA_QUALITY = 'Inadequate Data Quality';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_DATA_RANGE = 'Inadequate Data Range';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_DEL_CAP = 'Inadequate Delivery Capability';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_LEGAL_REST = 'Legal Restriction';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_LOST_TO_COMPE = 'Lost to Competition';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_PRICE_TOO_HIGH = 'Price Too High';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_FUNCTIONALITY = 'Inadequate Product / Functionality';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_TERMS = 'Inadequate Terms';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_CLI_REL = 'Inadequate Client Relationship';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_COMP_CAP = 'Inadequate Compliance Capability';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_EXP_STRATEGIC_DECISION = 'Experian Strategic Decision';
  public static final String OPPTY_PRIMARY_CLOSED_REASON_INADEQUATE_SERVICE_REC = 'Inadequate service record';
  public static final String OPPTY_TYPE_RENEWAL = 'Renewal';
  public static final String OPPTY_TYPE_CREDITED = 'Credited';
  public static final String OPPTY_FORECAST_CATEGORY_PIPELINE = 'Pipeline';
  public static final String OPPTY_FORECAST_CATEGORY_FORECAST = 'Forecast';
  public static final String OPPTY_NEW_FROM_NEW = 'New From New';
  public static final String OPPTY_NEW_FROM_EXISTING = 'New From Existing';
  public static final String CROSS_SELL = 'Cross-Sell';

  // Activity Types
  public static final String ACTIVITY_TYPE_QUOTE_DELIVERED      = 'Quote Delivered';
  public static final String ACTIVITY_TYPE_SELECTION_CONFIRMED  = 'Selection Confirmed';
  public static final String ACTIVITY_TYPE_SIGNED_CONTRACT      = 'Received Signed Contract';
  public static final String ACTIVITY_TYPE_CROSS_BUSINESS_UNIT  = 'Cross Business Unit Lead'; // JW - 26/02/2015 - Case #562501

  // URL Redirect Page Actions
  public static final String REDIRECT_CREATE_OPPORTUNITY = 'createOpportunity';
  public static final String REDIRECT_CREATE_ORDER = 'createOrder';
  public static final String REDIRECT_PRE_SALES_SUPPORT = 'createPreSalesSupport';

  //Address Merge Request merge process status
  public static final String MERGE_PROCESS_STATUS_PENDING = 'Pending';
  public static final String MERGE_PROCESS_STATUS_FAILURE = 'Failure';
  public static final String MERGE_PROCESS_STATUS_SUCCESS = 'Success';
  public static final String MERGE_TYPE_MANUAL = 'Manual Merge';
  public static final String MERGE_TYPE_BOOMI = 'Integration Merge via Boomi';
  public static final String BOOMI = 'Boomi';
  public static final String MANUAL = 'Manual';

  //Address Type
  public static final String ADDRESS_TYPE_REGISTERED = 'Registered';
  public static final String ADDRESS_TYPE_SECONDARY = 'Secondary';
  
  //Country Name
  public static final String COUNTRY_NAME_DEFAULT ='Default';
  public static final String COUNTRY_NAME_JAPAN ='Japan';

  //Constants used for BURelationshipCalculator 
  public static final String BUSINESS_UNIT_MS_CIT = 'MS: CI&T';
  public static final String GLOBAL_BUSINESS_MARKETING_SERVICES = 'Marketing Services';
  public static final String BU_RELATIONSHIP_TYPE_PROSPECT = 'Prospect';
  public static final String BU_RELATIONSHIP_TYPE_CLIENT = 'Client';
  public static final String BU_RELATIONSHIP_TYPE_FORMER_CLIENT = 'Former Client';
  
  //Constants used for USER's Business Line
  public static final String USER_BUSINESS_LINE_DC = 'UK&I Decision Analytics';
  public static final String USER_BUSINESS_LINE_CS = 'UK&I Credit Services';
  
  
  public static final String ACCOUNT_SEGMENT_GBL = 'Global Business Line';
  public static final String ACCOUNT_SEGMENT_BL = 'Business Line';
  public static final String ACCOUNT_SEGMENT_BU = 'Business Unit';
  public static final String ACCOUNT_SEGMENT_REGION = 'Region';
  public static final String ACCOUNT_SEGMENT_COUNTRY = 'Country';
  

  //Node type
  public static final String NODE_TYPE_START = 'start';
  public static final String NODE_TYPE_END = 'end';
  public static final String NODE_TYPE_CHILD = 'child';
  public static final String NODE_TYPE_CHILD_END = 'child_end';
  public static final String NODE_TYPE_PARENT = 'parent';
  public static final String NODE_TYPE_PARENT_END = 'parent_end';

  public static final String STAGE_3_DURATION = 'Stage_3_Duration__c';
  public static final String STAGE_4_DURATION = 'Stage_4_Duration__c';
  public static final String STAGE_5_DURATION = 'Stage_5_Duration__c';
  public static final String STAGE_6_DURATION = 'Stage_6_Duration__c';
  
  public static final String ROWCAUSE_OPPTY_TEAM = 'Opportunity_Team__c';
  public static final String ROWCAUSE_ACCOUNT_TEAM = 'Account_Team__c';
  
  public static final String PICKLISTVAL_YES = 'Yes';
  public static final String PICKLISTVAL_NO = 'No';
  
  public static final String REVENUE_TYPE_DIVIDE_AMT_MULTIPLE_INST = 'Divide Amount into multiple installments';
  public static final String REVENUE_TYPE_REPEAST_AMT_EACH_INST = 'Repeat Amount for each installment';
  
  public static final String RECORDTYPE_STANDARDS = 'Standard';
  public static final String RECORDTYPE_MASS_TRANSFER_REQUEST ='Mass Transfer Request';
  public static final String RECORDTYPE_CONF_INFO_OPPTY = 'Confidential Information - Opportunity';
  public static final String RECORDTYPE_CONF_INFO_CONTRACTHEAD = 'Confidential Information - Contract Header';
  public static final String RECORDTYPE_CONTRACT_CSDA_HEADER = 'CSDA Contract Header';
  
  
  public static final String REGION_INDIA = 'India';
  public static final String REGION_LATAM = 'LATAM';
  public static final String REGION_EMEA = 'EMEA';
  public static final String REGION_NA = 'NA';
  public static final String REGION_UKI = 'UK&I';
  public static final String REGION_LATIN_AMERICA = 'Latin America';
  public static final String REGION_GLOBAL = 'Global';
  
  
  public static final String CASE_TYPE_INTERNAL = 'Internal';
  public static final string CASE_TYPE_SPAIN_DELIVERY_TASK = 'Spain Delivery Task';
  
  // Group
  public static final String GROUP_DELIVERY_MANAGEMENT = 'Delivery Management';
  public static final String GROUP_EDQ_COPS = 'EDQ COPS Team';

  public static final String TYPE_OF_SALE_CONSULTANCY = 'Consultancy';
  public static final String TYPE_OF_SALE_SOFTWARESALE = 'Software Sale';
  public static final String TYPE_OF_SALE_ADHOC = 'Ad-Hoc';
  public static final String TYPE_OF_SALE_INITIALSOFTWAREFEE = 'Initial Software Fee';

  public static final String PERIOD_MONTHLY = 'Monthly';
  public static final String PERIOD_QUARTERLY = 'Quarterly';

  public static final String SCHEDULE_TYPE_DIVIDE_AMOUNT = 'Divide Amount into multiple installments';
  public static final String SCHEDULE_TYPE_REPEAT_AMOUNT = 'Repeat Amount for each installment';
  
  public static final String USER_GBL_CREDIT_SERVICES = 'Credit Services';
  public static final String USER_GBL_DECISION_ANALYTICS = 'Decision Analytics';
  public static final String USER_GBL_INTERACTIVE = 'Interactive';
  public static final String USER_GBL_LATAM_SERASA_SALES = 'LATAM Serasa Sales';
  public static final String USER_GBL_MARKETING_SERVICES = 'Marketing Services';
  public static final String STR_PROSPECTING = 'prospecting';
  public static final String STR_QUALIFICATION = 'qualification';
  public static final String STR_NEEDSANALYSIS = 'needs analysis';
  public static final String STR_VALUE_PROPOSITION = 'value proposition';
  public static final String STR_ID_DECISIO_NMAKERS = 'id. decision makers';
  public static final String STR_PERCEPTION_ANALYSIS = 'perception analysis';
  public static final String STR_PROPOSAL_PRICEQUOTE = 'proposal/price quote';
  public static final String STR_NEGOTIATION_REVIEW = 'negotiation/review';
  public static final String STR_CLOSED_WON = 'closed won';
  public static final String STR_CLOSED_LOST = 'closed lost';
  
  //Access Request Case Contacts
  public static final String CASE_REC_TYPE_ACCESS_REQUEST = 'Access Request';
  public static final String ACCT_TEAM_ACCESS = 'Edit';
  public static final String CONTACT_TEAM_ACCESS = 'Edit';
  public static final String OPTY_TEAM_ACCESS = 'Edit';
  public static final String CASE_STATUS_APPROVED = 'Approved';

  //Constants for CaseTrigger_ResolutionTime
  public static final String CASE_REC_TYPE_CCM_NA_CASE = 'CCM NA Case';
  public static final String CASE_REC_TYPE_EDQ_CASE = 'EDQ Case';

  // Start: Case #542997 - 04/03/2015 - JW
  public static final String CASE_REC_TYPE_CSDA_CONT_REQ = 'CSDA Contract Request';
  public static final String CASE_REC_TYPE_ACC_REQUEST = 'Access Request';
  public static final String CASE_REC_TYPE_CRM_REQUEST = 'CRM Request';
  public static final String CASE_REC_TYPE_CAN_DOWN_REQUEST = 'Cancellation/Downgrade Request';
  public static final String CASE_REC_TYPE_CPQ_REQUEST = 'CPQ Requests';
  public static final String CASE_REC_TYPE_PROD_REQUEST = 'Product Request';
  public static final String CASE_REC_TYPE_USER_ONBOARDING = 'User Onboarding';
  // End

  public static final String CASE_CHANGE_TYPE_STATUS = 'Status';
  public static final String CHANGE_TYPE_STATUS = 'Status';
  public static final String MEMBERSHIP_CHANGE_TYPE_STATUS = 'Status';
  public static final String CASE_CHANGE_TYPE_OWNER = 'Owner';
  public static final String MEMBERSHIP_CHANGE_TYPE_OWNER = 'Owner';
  public static final String MEMBERSHIP_HISTORY_OWNER_TYPE_USER = 'User';
  public static final String CASE_HISTORY_OWNER_TYPE_USER = 'User';
  public static final String CASE_HISTORY_OWNER_TYPE_QUEUE = 'Queue';
  public static final String HISTORY_OWNER_TYPE_USER = 'User';
  public static final String HISTORY_OWNER_TYPE_QUEUE = 'Queue';
  
  
  public static final String CASE_REC_TYPE_EDQ_GPD_CASE = 'EDQ GPD Case';
  // constants for T-319512
  public static final String OPPTY_CONTACT_ROLE_SHIPTO = 'Ship-to' ;
  public static final String OPPTY_CONTACT_ROLE_PURCHASE_LEDGER = 'Bill-To';
  public static final String OPPTY_CONTACT_ROLE_COMMERCIAL = 'Commercial';
  // T-322814
  public static final String OPPTY_CONTACT_ROLE_RENEWAL = 'Renewals';
  public static final String OPPTY_CONTACT_ROLE_UPDATE = 'Updates';
  
  public static final String OPPTY_CONTACT_ROLE_CONTRACTUAL = 'Contractual' ;
  
  // T-320132
  public static final String OPPTY_CHANNEL_TYPE_DIRECT = 'Direct';
  public static final String OPPTY_CHANNEL_TYPE_INDIRECT = 'Indirect';


  // Added for EMS functionality
  public static final String CASE_COMMENT_TRIGGER = 'CaseCommentTrigger';
  public static final String RECORDTYPE_CASE_EMS = 'EMS';
  public static final String CASE_TYPE_INCIDENT = 'Incident';
  public static final String CASE_STATUS_CLOSED_RESOLVED = 'Closed Resolved';
  public static final String CASE_STATUS_IN_PROGRESS = 'In progress';
  public static final String CASE_BUSINESSHOURS_FRANCE_MORNING = 'France Morning Hours';
  public static final String CASE_BUSINESSHOURS_FRANCE_AFTERNOON = 'France Afternoon Hours';
  public static final String CASE_BUSINESSHOURS_SPAIN = 'Germany';
  public static final String CASE_BUSINESSHOURS_GERMANY = 'Spain';
  public static final String USER_ROLE_FRANCE_EVOLUTION = 'France Evolution';
  public static final String USER_ROLE_GERMANY_EVOLUTION = 'Germany Evolution';
  public static final String USER_ROLE_SPAIN_EVOLUTION = 'Spain Evolution';
  public static final String USER_ROLE_FRANCE_ONBOARDING = 'France Onboarding';
  public static final String USER_ROLE_GERMANY_ONBOARDING = 'Germany Onboarding';
  public static final String USER_ROLE_SPAIN_ONBOARDING = 'Spain Onboarding';
  public static final String CASE_TYPE_TASK = 'Task';

  public static final String USER_ROLE_FRANCE_L1_CLIENT_SERVICE_AGENT = 'France Level 1 Client Services Agent';
  public static final String USER_ROLE_FRANCE_L2_CLIENT_SERVICE_AGENT = 'France Level 2 Client Services Agent';
  public static final String USER_ROLE_GERMANY_L1_CLIENT_SERVICE_AGENT = 'Germany Level 1 Client Services Agent';
  public static final String USER_ROLE_GERMANY_L2_CLIENT_SERVICE_AGENT = 'Germany Level 2 Client Services Agent';
  public static final String USER_ROLE_SPAIN_L1_CLIENT_SERVICE_AGENT = 'Spain Level 1 Client Services Agents';
  public static final String USER_ROLE_SPAIN_L2_CLIENT_SERVICE_AGENT = 'Spain Level 2 Client Services Agents';


  public static final String RECORDTYPE_CASE_EDQ_GPD = 'EDQ GPD Case';
  public static final String RECORDTYPE_CASE_ONBOARDING = 'User Onboarding';
  public static final String RECORDTYPE_CASE_EDQ_COMMERCIAL = 'EDQ Commercial Case';
  public static final String RECORDTYPE_CASE_SPANISH = 'Spanish Delivery';
  public static final String RECORDTYPE_CASE_EDQ = 'EDQ Case';
  public static final String RECORDTYPE_CASE_CSDA_BIS_SUPPORT = 'CSDA BIS Support';
  public static final String RECORDTYPE_CASE_CSDA_CIS_BA_REQUEST = 'CSDA CIS BA Request';
  public static final String RECORDTYPE_CASE_CSDA_CIS_SUPPORT = 'CSDA CIS Support';
  public static final String OLI_FLD_UPDATE_FREQENCY = 'update_frequency__c';
  public static final String OLI_FLD_DELIVERY_METHOD = 'delivery_method__c';
  public static final String OLI_FLD_TYPE = 'type__c';
  public static final String OLI_FLD_LAST_MODIFIED_DT = 'lastmodifieddate';
  public static final String OLI_FLD_LAST_MODIFIED_BY = 'lastmodifiedby';
  public static final String BUSINESSLINE_DATA_QUALITY = 'Experian Data Quality';
  
  public static final String EDQ = 'EDQ';
  
  public static final String AGENCY = 'Agency';

  public static final String TIMECARD_TYPE_DELIVERY = 'Delivery';
  public static final String TIMECARD_TYPE_TRAVEL = 'Travel';
  
  public static final String OPPTY_TYPE_FREE_TRIAL = 'Free Trial';
  public static final String OLI_TYPE_FREE_TRIAL = 'Free Trial';
  public static final String OPPTY_SALES_PROCESS_STANDARD = 'Standard';
  //T-359589 GC 10/02/2015
  public static final String ORDER_TYPE_FREE_TRIAL = 'Free Trial';

  public static final String ASSET_DATA_USAGE = 'Data_Usage__c';
  public static final String ASSET_IMPLEMENTATION_ON_DEMAND = 'On Demand';
  public static final String ASSET_DIRECT_RENEWAL = 'Direct_Renewal__c';
  public static final String ASSET_INSTALL_DATE = 'InstallDate';
  public static final String ASSET_LAST_MODIFIED_DATE = 'LastModifiedDate';
  public static final String ASSET_OPERATING_SYSTEM = 'Operating_System__c';
  public static final String ASSET_ORDER_LINE = 'Order_Line__c';
  //public static final String ASSET_OS_VERSION = 'OS_Version__c'; //T-326528
  public static final String ASSET_PARTNER = 'Partner__c';
  public static final String ASSET_PARTNER_AMOUNT = 'Partner_Amount__c';
  public static final String ASSET_PRICE = 'Price';
  public static final String ASSET_PURCHASE_DATE = 'PurchaseDate';
  public static final String ASSET_QUANTITY = 'Quantity';
  public static final String ASSET_RELEASE_VERSION = 'Release_Version__c';
  public static final String ASSET_RENEWAL_DISCOUNT = 'Renewal_Discount__c';
  //public static final String ASSET_RENEWAL_VAR = 'Renewal_VAR__c'; //T-326528
  public static final String ASSET_START_DATE = 'Start_Date__c';
  public static final String ASSET_STATUS = 'Status';
  public static final String ASSET_TOTAL_ROYALTY = 'Total_Royalty__c';
  public static final String ASSET_USAG_END_DATE = 'UsageEndDate';
  public static final String ASSET_TYPE_CREDITED = 'Credited';
  public static final String ASSET_ITEM_NUMBER = 'Callidus_Item_Number__c';
  public static final String ASSET_QUOTE_NUMBER = 'Callidus_Quote_Number__c';
  //RJ Case 00607940- Added two field names (ASSET_RPI and ASSET_RPI_AMOUNT)
  public static final String ASSET_RPI = 'RPI__c';
  public static final String ASSET_RPI_AMOUNT = 'RPI_Amount__c';

  public static final String ORDER_LINE_ITEM_DELIVERY_METHOD_NOT_REQ = 'Not Required';
  
  public static final String LOCALNAME_RESULT = 'Result';
  public static final String STR_NOK = 'NOK';
  public static final String STR_OK = 'NOK';
  
  public static final String OPPTY_STAGE_ABANDONED = 'Abandoned';
  public static final String OLI_ORDER_TYPE_PDT = 'Paid Dev Tools';
  public static final String OLI_ORDER_TYPE_UPSELL = 'Up-Sell';
  public static final String OLI_ORDER_TYPE_REPLACEMENT = 'Replacement';

  //EDQ user types on user object for field EDQ_User_Type__c  
  public static final String EDQ_USER_TYPE_SALES_MANAGER = 'EDQ Sales Manager';
  public static final String EDQ_USER_TYPE_CUSTOMER_OPERATIONS = 'EDQ Customer Operations';
  public static final String EDQ_USER_TYPE_COMM_TECH_LEGAL = 'EDQ Commercial Technicians Legal';
  public static final String EDQ_USER_TYPE_FINANCE_MANAGER = 'EDQ Finance Managers';
  public static final String EDQ_USER_TYPE_PROFESSIONAL_SERVICES = 'EDQ Professional Services'; 
  public static final String CPQ_USERTYPE_CSDA_AE_MANAGER = 'CSDA AE Manager';
  public static final String CPQ_USERTYPE_CSDA_STRATEGIC_PRICING = 'CSDA Strategic Pricing';

  //RLI.Type__c and Status__c
  public static final String RLI_TYPE_LONG = 'Long';
  public static final String RLI_TYPE_STANDARD = 'Standard';
  public static final String RLI_STATUS_PAID = 'Paid';
  public static final String RLI_STATUS_UNPAID = 'Unpaid';
  public static final String RLI_STATUS_LOST = 'Lost';

  //T-349831
  public static final String SALES_PROCESS_STANDARD = 'Standard';
  public static final String SALES_PROCESS_LEAD = 'Lead';
  public static final String STR_IGNORE = 'IGNORE';
  public static final String STR_SERVICE = 'Service';
  public static final String STR_QUEUE = 'Queue';
  
  public static final String STR_POSITIVE = 'Positive';
  public static final String STR_NEGATIVE = 'Negative';

  
  public static final String STATUS_WAIT = 'Wait';
  public static final String STATUS_SUCCESS = 'Completed';
  
  public static final String STATUS_FAILED = 'Failed';
  
  public static final String VALIDATION_STATUS_FAIL = 'Fail';
  

  //Business Process Template Constants
  public static final String RELATED_TO_CASES = 'Cases';
  public static final String RELATED_TO_OPPORTUNITIES = 'Opportunities';
  public static final String RELATED_TO_ACCOUNTS = 'Accounts';
  public static final String RELATED_TO_MEMBERSHIPS = 'Membership';
  public static final String BU_CSDA = 'CSDA';
  public static final String SUB_BU_BIS = 'BIS';
  public static final String SUB_BU_CIS = 'CIS';
  



}