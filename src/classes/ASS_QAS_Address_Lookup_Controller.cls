/**=====================================================================
 * Appirio, Inc
 * Name: ASS_QAS_Address_Lookup_Controller
 * Description: 
 * Created Date: Nov 19th, 2013
 * Created By: M Ifran (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 14th, 2014               Arpita Bose(Appirio)         T-249494: Modified constructor with try and
                                                             catch block having a query with limit
 * Mar 06th, 2014               Naresh Kr Ojha (Appirio)     T-256341: CSS - Querying LIMIT 1
 * Mar 18th, 2014               Jinesh Goyal(Appirio)        T-251967
 * Apr 08th, 2014               Arpita Bose                  T-269372: Added addError()in try-catch block
 * Apr 9th, 2015                Paul Kissick                 Case #531600 : Adding Address 2 and 3 to query on line 28
 =====================================================================*/
public with sharing class ASS_QAS_Address_Lookup_Controller {

public String QASTypedownSessionToken {get; private set;} 
public Address__c address {get;set;}
public List<Account_Address__c> accountAddressList {get;set;}
//account id coming from the parent page
public String accId {get;
     set{
       accId = value;
      if (accId != null && accId != '') {
        accountAddressList = new List<Account_Address__c>();
        for(Account_Address__c accAddress : [SELECT Id, Address__r.Address_1__c, Address__r.City__c, 
                                                    Address__r.Address_2__c, Address__r.Address_3__c,
                                                    Address__r.Country__c, Address__r.PostCode__c, Address__c
                                             FROM   Account_Address__c
                                             WHERE  Address__c <> NULL 
                                             AND    Account__c = :accId ]) {
          accountAddressList.add (accAddress);
        }
      } else {
        accountAddressList = null;
      }
    }
}

  
  //Constructor
  public ASS_QAS_Address_Lookup_Controller() {
    //string addressId = ApexPages.currentPage().getParameters().get('addrId'); 
    try {
      QAS_NA__QAS_CA_Account__c accountSObject;
      for (QAS_NA__QAS_CA_Account__c account :[SELECT  QAS_NA__ValidationSessionToken__c 
                                               FROM QAS_NA__QAS_CA_Account__c
                                               LIMIT 1]) {
        accountSObject = account;
      }
      if (accountSObject <> null && accountSObject.QAS_NA__ValidationSessionToken__c <> null) {
        QASTypedownSessionToken = accountSObject.QAS_NA__ValidationSessionToken__c;
      }
    } catch (Exception ex) {
      System.debug('\n[ASS_QAS_Address_Lookup_Controller: QATypedownSessionToken]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('AddressMerge','mergeAddressesInBatch', ex.getStackTraceString(), ex);
    }
  }
  
}