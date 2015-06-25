/**=====================================================================
 * Appirio Inc
 * Name: AddressUtility.cls
 * Description: Utility class to support Address Smart Searches
 * Created Date: 21 January 2014
 * Created By: Nathalie Le Guay (Appirio)
 *
 * Date Modified       Modified By            Description of the update
 * Feb 13th, 2014      Jinesh Goyal(Appirio)  T-232763: Added Exception Logging
 * Mar 14th, 2014			 Naresh K Ojha (Appirio)T-251968: made findMatchingaddress method public.
 * Apr 07th, 2014      Arpita Bose (Appirio)  T-269372: Added addError()in try-catch block
 * May 19th, 2014      Nathalie Le Guay       : created hasDuplicateAddresses() which checks if the a
 =====================================================================*/
public without sharing class AddressUtility {
  private static List<String> addressFields = new List<String>{
                                                   'Address_1__c',
                                                   'Address_2__c',
                                                   'Address_3__c',
                                                   'Address_4__c',
                                                   'City__c',
                                                   'Country__c',
                                                   'CEDEX__c',
                                                   'Codiga_Postal__c',
                                                   'County__c',
                                                   'District__c',
                                                   'Emirate__c',
                                                   'Floor__c',
                                                   'Partofterritory__c',
                                                   'POBox__c',
                                                   'Postcode__c',
                                                   'Prefecture__c',
                                                   'Province__c',
                                                   'SortingCode__c',
                                                   'State__c',
                                                   'Suite__c',
                                                   'Zip__c'};
  /**
   * Perform a database check to find an address match
   */
  public static Address__c checkDuplicateAddress(Address__c address) {
    String addressString = '';
    addressFields.sort();

    addressString = DescribeUtility.buildKey(addressFields, (SObject) address, 'Address__c');
    if (addressString.length() >= 255) {
      addressString = addressString.substring(0, 255);
    }

    if (String.isNotEmpty(addressString)) {
      try {
        List<Address__c> databaseAddressCheck = [SELECT Id, Address_1__c,Address_2__c,Address_3__c,Address_4__c,Address_Id__c,City__c,Country__c ,CEDEX__c,Codiga_Postal__c,County__c,District__c,Emirate__c,Floor__c,Partofterritory__c,POBox__c,Postcode__c,Prefecture__c,Province__c,SortingCode__c,State__c,Suite__c,Zip__c,Last_Validated__c,Validation_Status__c
                                                 FROM Address__c
                                                 WHERE Address_Id__c =: addressString];
        Address__c addressMatch;

        if (databaseAddressCheck.size() > 0) {
          System.debug('\n~AddressUtility: Found one or many match(es): '+ databaseAddressCheck);

          addressMatch = findMatchingAddress(address, databaseAddressCheck);
          // This address will be used when creating the Account_Address__c record
        }
        if (addressMatch != null) {
          System.debug('\n~AddressUtility: Found existing entry for: ' + addressString);
          address = addressMatch;
        } else {
          System.debug('\n~AddressUtility: No duplicate was found for entry: ' + addressString);
          address.Address_Id__c = addressString;
        }
        return address;
      } catch(QueryException e) {
        System.debug('\n~AddressUtility: No duplicate was found for entry: ' + addressString);
        // Assigning the key in the Address_Id__c field
        address.Address_Id__c = addressString;
        ApexLogHandler.createLogAndSave('AddressUtility','checkDuplicateAddress', e.getStackTraceString(), e);
        for (Integer i=0; i < e.getNumDml(); i++) {
          address.addError(e.getDMLMessage(i));
        }  
      }
    }
    return address;
  }

  public static Boolean hasDuplicateAddresses(List<Address__c> addresses, Set<Id> recordIds, String objectName) {
    if (recordIds == null || recordIds.size() == 0) {
      return false;
    }
    String addressString = '';
    // List to store all the addressKey generated
    List<String> addressKeys = new List<String>();

    // Map to store the key of each address
    Map<String, String> addressKeyByAddressId = new Map<String, String>();

    // Map to store the results of key search
    Map<String, List<Address__c>> addressesByKey = new Map<String, List<Address__c>>();
    addressFields.sort();

    for (Address__c address: addresses) {
      addressString = DescribeUtility.buildKey(addressFields, (SObject) address, 'Address__c');
      if (addressString.length() >= 255) {
        addressString = addressString.substring(0, 255);
      }
      addressKeys.add(addressString);
      addressKeyByAddressId.put(address.Id, addressString);
    }

    if (addressKeys.size() > 0) {
      for (Address__c address : [SELECT Id, Address_1__c,Address_2__c,Address_3__c,Address_4__c,Address_Id__c,
                                        City__c,Country__c ,CEDEX__c,Codiga_Postal__c,County__c,District__c,Emirate__c,Floor__c,
                                        Partofterritory__c,POBox__c,Postcode__c,Prefecture__c,Province__c,SortingCode__c,State__c,Suite__c,Zip__c,
                                        Last_Validated__c,Validation_Status__c,
                                        (Select Id, Contact__c FROM Contact_Addresses__r),
                                        (Select Id, Account__c FROM Account_Address__r)
                                 FROM Address__c
                                 WHERE Address_Id__c in : addressKeys]) {
        if (addressesByKey.get(address.Address_Id__c) == null) {
          addressesByKey.put(address.Address_Id__c, new List<Address__c>());
        }
        addressesByKey.get(address.Address_Id__c).add(address);
      }
    }
    
    Address__c addressMatch;
    for (Address__c address: addresses) {
      String addressKey = addressKeyByAddressId.get(address.Id);
      system.debug('\n[AddressUtility : checkDuplicateAddresses] Address Key: ' + addressKey);

      List<Address__c> addressesMatch = addressesByKey.get(addressKey);
      if (addressesMatch != null && addressesMatch.size() > 0) {
        System.debug('\n~AddressUtility: Found one or many match(es): '+ addressesMatch);
        addressMatch = findMatchingAddress(address, addressesMatch);
      }
      if (addressMatch != null) {
        if (objectName.equalsIgnoreCase(Constants.SOBJECT_CONTACT)) {
          for (Contact_Address__c contactAddress: addressMatch.Contact_Addresses__r) {
            if (recordIds.contains(contactAddress.Contact__c)) {
              system.debug('\nFOUND DUPLICATE with '+ contactAddress.Id);
              return true;
            }
          }
        }
        if (objectName.equalsIgnoreCase(Constants.SOBJECT_ACCOUNT)) {
          for (Account_Address__c accountAddress: addressMatch.Account_Address__r) {
            if (recordIds.contains(accountAddress.Account__c)) {
              system.debug('\nFOUND DUPLICATE with '+ accountAddress.Id);
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /**
   * This method will check the full key string, given the 255 characters limitations given by the external Id
   */
  public static Address__c findMatchingAddress(Address__c address, List<Address__c> addressesToCompare) {
    String databaseEntryAddress = '';
    String userInputAddress = DescribeUtility.buildKey(addressFields, (SObject) address, 'Address__c');
    for (Address__c addressToCompare: addressesToCompare) {
      databaseEntryAddress = DescribeUtility.buildKey(addressFields, (SObject) addressToCompare, 'Address__c');
      System.debug('\n~AddressUtility: \nComparing: ' + databaseEntryAddress + ' with: ' + userInputAddress);
      if (databaseEntryAddress == userInputAddress) {
        System.debug('~AddressUtility: Match found: ' + addressToCompare);
        return addressToCompare;
      }
    }
    return null;
  }
}