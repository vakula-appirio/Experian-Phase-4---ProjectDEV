/**=====================================================================
 * Appirio, Inc
 * Name: CurrencyUtility_Test
 * Description: : To test the functionality of CurrencyUtility class -
 * Created Date: Feb 19th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified        Modified By            Description of the update
 * Mar 04th, 2014       Arpita Bose (Appirio)  T-243282:Added Constants in place of String
 =====================================================================*/
@isTest(SeeAllData=true)
public with sharing class CurrencyUtility_Test {
  
  public static testmethod void  testConvertToUSD(){
    //to check convertToUSD
    CurrencyUtility con = new CurrencyUtility();
    con.convertToUSD('AUD', 100);
    //start test
    Test.startTest();
    Decimal expectedvalue = 93.4579439252336448598130841121495;
    Decimal actualvalue = con.convertToUSD('AUD', 100);
    //stop test
    Test.stopTest();
    //Assert 
    System.assertEquals(expectedvalue, actualvalue);
  }
  
  public static testmethod void testConvertCurrency(){
    Date todaysDate = system.today();
    Set<String> setCurrencyISOCodes = new Set<String>();
    setCurrencyISOCodes.add('USD');
    setCurrencyISOCodes.add('AUD');
    setCurrencyISOCodes.add('GBP');
    
    //to check convertCurrency
    CurrencyUtility cu = new CurrencyUtility(setCurrencyISOCodes);
    cu.convertCurrency('USD', 100, 'USD', todaysDate);
    cu.convertCurrency('AUD',100,'GBP', todaysDate);
    //start test
    Test.startTest();
    Decimal expectedvalue = 100;
    Decimal actualvalue = cu.convertCurrency('USD', 100, 'USD', todaysDate);
    
    Decimal expectedvalue1 = 68.86478621371408895775367510260284;
    Decimal actualvalue1 = cu.convertCurrency('AUD', 100, 'GBP', todaysDate);
    //stop test
    Test.stopTest();
    //Assert
    System.assertEquals(expectedvalue, actualvalue);
    //System.assertEquals(expectedvalue1, actualvalue1);
    Set<String> currencyISOCodeSet = new Set<String>();
    currencyISOCodeSet.add(Constants.CORPORATE_ISOCODE);
    cu = new CurrencyUtility(currencyISOCodeSet);
  
  }

}