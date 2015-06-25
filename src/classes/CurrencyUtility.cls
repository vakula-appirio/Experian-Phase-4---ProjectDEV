/**=====================================================================
 * Appirio, Inc
 * Name: CurrencyUtility
 * Description: *Currency Conversion The code assumes the Corporate Currency is USD
 * Used Asset : Currency Conversion 
 *              (https://appirio.my.salesforce.com/apex/CMC_AssetView?id=a3E50000000DxvxEAC)
 * Created Date: Feb 19th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified        Modified By              Description of the update
 * Feb 18th, 2014       Original Class           T-248913
 * Mar 03rd, 2014       Arpita Bose(Appirio)     T-243282: Added Constants in place of String
 * Mar 11th, 2014       Naresh kr Ojha(Appirio)  T-257854: Optimized currency utility to load all currencies at once, when
 *                                               No currency passed on init of currencyUtility object in using class.
 * April 3rd, 2014      Mohit Parnami(Appirio)   T-266502: updated Constructor having parameter as set of ISO codes and   
 *                                               added new methods using DatedConversionRate Object
 * Apr 28th, 2014       Arpita Bose              T-275717: Added WHERE clause in queryAndLoadAllConversionRate() method to fix
 *                                               the Force.com Security Scanner Results
 =======================================================================*/
public with sharing class CurrencyUtility {

  //Store conversion rates, in a static Map to act as cache
  public static Map<String,Double> currencyConversionRateMap = new Map<String,Double>();
  public static Map<String, List<DatedConversionRate>> currencyISO_ListDtConvRateMap = new Map<String, List<DatedConversionRate>>();
  public static Boolean hasLoadedCurrencyRates = false;
  //public static List<DatedConversionRate> dcrList = new List<DatedConversionRate>();
  //=====================================//
  //Normal No Args constructor
  //====================================//
  public CurrencyUtility() {
    queryAndLoadAllConversionRate();
  }

  //If a lot of conversion needs to happen, pass in all the currency codes
  public CurrencyUtility(Set<String> setCurrencyISOCodes){
    //Commented by Mohit Parnami to get all Conversion rate from DatedConversionRate
    //queryAndLoadConversionRate(setCurrencyISOCodes);
    queryAndLoadConversionRateOnDate(setCurrencyISOCodes);
  }


  //====================================================================//
  //A shortcut method that converts amount to USD from Source Currency
  //=====================================================================//
  public Decimal convertToUSD(String sourceISOCode, Decimal amount) {
    return convertCurrency(sourceISOCode, amount, Constants.CORPORATE_ISOCODE);
  }

  //==================================================================================//
  //@sourceCurrency => Source currency containing the actual amount
  //@destinationCurrency => Destination Currency the target currency in which amount should be converted
  //@Amount => The Amount in Source Currency that needs to converted
  //===================================================================================//
  public Decimal convertCurrency(String sourceISOCode, Decimal amount, String destinationISOCode) {
    loadConversionRates(sourceISOCode, destinationISOCode);

    //Convert the input amount to USD just by multiplying the conversion rate
    //eg 1 Dollar = 50 INR  
    if (sourceISOCode == Constants.CORPORATE_ISOCODE) {
      return amount * currencyConversionRateMap.get(destinationISOCode);
    }

    //Convert the amount into USD
    Decimal computeAmount;
    System.debug('[CurrencyUtility:convertCurrency][sourceISOCode:'+sourceISOCode+']');
    System.debug('[CurrencyUtility:convertCurrency][currencyConversionRateMap:'+currencyConversionRateMap+']');
    System.debug('[CurrencyUtility:convertCurrency][amount:'+amount+']');
    
    if (currencyConversionRateMap.containsKey(sourceISOCode) && amount != null) {
      computeAmount = amount / currencyConversionRateMap.get(sourceISOCode);
    }
    if (computeAmount != null && destinationISOCode != Constants.CORPORATE_ISOCODE && currencyConversionRateMap.containsKey(destinationISOCode)) {
      //reconvert the USD to destination currency
      computeAmount = computeAmount * currencyConversionRateMap.get(destinationISOCode);
    }
    return computeAmount;
    
  }


  //================================================================//
  //Check if the already have the rates, if yes dont load again
  //================================================================//
  private void loadConversionRates(String currency1, String currency2) {
    Set<String> setCurrency = new Set<String>();
    if (!currencyConversionRateMap.containsKey(currency1)) {
      setCurrency.add(currency1);
    }

    if (!currencyConversionRateMap.containsKey(currency2)) {
      setCurrency.add(currency2);
    }
    if (setCurrency.size() == 0) return;
    system.debug('setCurrency:: '+setCurrency);
    //queryAndLoadConversionRate(setCurrency);
  }

  //========================================================================//
  //Query Salesforce and load the latest conversion Rate
  //========================================================================//
  private void queryAndLoadConversionRate(Set<String> setCurrencyISOCode) {
    for (CurrencyType currencyType: [SELECT IsoCode,ConversionRate 
                                     FROM CurrencyType 
                                     WHERE IsoCode IN: setCurrencyISOCode]){
      currencyConversionRateMap.put(currencyType.IsoCode,currencyType.ConversionRate);
    }
  }

  //========================================================================//
  //Query Salesforce and load the latest conversion Rate
  //========================================================================//
  public static void queryAndLoadAllConversionRate() {
    for (CurrencyType currencyType: [SELECT IsoCode,ConversionRate 
                                     FROM CurrencyType 
                                     WHERE IsActive = true]){
      currencyConversionRateMap.put(currencyType.IsoCode,currencyType.ConversionRate);
    }
  }
  
/*******************************Part Added By Mohit to Update conversion on the basis of DatedConversionRate Object Begins*************/ 
 
  //=======================================================================================//
  //Query Salesforce and load the latest conversion Rate From DatedConversionRate object
  //======================================================================================// 
  public static void queryAndLoadConversionRateOnDate(Set<String> setCurrencyISOCode){
    if (hasLoadedCurrencyRates) {
      return;
    }

    for (DatedConversionRate dcr : [SELECT StartDate, NextStartDate, IsoCode, 
                                           Id, ConversionRate 
                                    FROM DatedConversionRate
                                    WHERE IsoCode IN: setCurrencyISOCode]) {
      if (!currencyISO_ListDtConvRateMap.containsKey(dcr.IsoCode)) {
        currencyISO_ListDtConvRateMap.put(dcr.IsoCode, new List<DatedConversionRate>());
      }
      currencyISO_ListDtConvRateMap.get(dcr.IsoCode).add(dcr);
      //dcrList.add(dcr);
    }
    hasLoadedCurrencyRates = true;
  }
  
  //==================================================================================//
  //@sourceCurrency => Source currency containing the actual amount
  //@destinationCurrency => Destination Currency the target currency in which amount should be converted
  //@Amount => The Amount in Source Currency that needs to converted
  //@dateOfRate => Rate at which date conversion is required
  //===================================================================================//
  public Decimal convertCurrency(String sourceISOCode, Decimal amount, String destinationISOCode, Date dateOfRate) {
    loadConversionRatesOnDate(sourceISOCode, destinationISOCode);

    //Convert the input amount to USD just by multiplying the conversion rate
    //eg 1 Dollar = 50 INR  
    Decimal convertedRate = 0;
    if (sourceISOCode == Constants.CORPORATE_ISOCODE) {
      if (currencyISO_ListDtConvRateMap.containsKey(sourceISOCode)){
        for (DatedConversionRate dataConversionRate : currencyISO_ListDtConvRateMap.get(sourceISOCode)) {
          if (dataConversionRate.StartDate <= dateOfRate && dataConversionRate.NextStartDate > dateOfRate) {
            convertedRate = dataConversionRate.ConversionRate;
          }
        }
      }
      return amount * convertedRate;
    }

    //Convert the amount into USD
    Decimal computeAmount = 0;
    System.debug('[CurrencyUtility:convertCurrency][sourceISOCode:'+sourceISOCode+']');
    System.debug('[CurrencyUtility:convertCurrency][currencyISO_ListDtConvRateMap:'+currencyISO_ListDtConvRateMap+']');
    System.debug('[CurrencyUtility:convertCurrency][amount:'+amount+']');
    
    if (currencyISO_ListDtConvRateMap.containsKey(sourceISOCode) && currencyISO_ListDtConvRateMap.get(sourceISOCode)!= null &&amount != null ) {
      for (DatedConversionRate dataConversionRateSource : currencyISO_ListDtConvRateMap.get(sourceISOCode)){
        if (dataConversionRateSource.StartDate <= dateOfRate && dataConversionRateSource.NextStartDate > dateOfRate) {
          computeAmount = amount / dataConversionRateSource.ConversionRate;
        }
      }
    }
    if (computeAmount != null && destinationISOCode != Constants.CORPORATE_ISOCODE && currencyISO_ListDtConvRateMap.containsKey(destinationISOCode)) {
      //reconvert the USD to destination currency
      for (DatedConversionRate dataConversionRateDestination : currencyISO_ListDtConvRateMap.get(destinationISOCode)) {
        if (dataConversionRateDestination.StartDate <= dateOfRate && dataConversionRateDestination.NextStartDate > dateOfRate) {
          computeAmount = computeAmount * dataConversionRateDestination.ConversionRate;
        }
      }
    }
    return computeAmount;
  }
  
  
  //================================================================//
  //Check if the already have the rates, if yes dont load again
  //================================================================//
  private void loadConversionRatesOnDate(String currency1, String currency2) {
    Set<String> setCurrency = new Set<String>();
    if (!currencyISO_ListDtConvRateMap.containsKey(currency1)) {
      setCurrency.add(currency1);
    }

    if (!currencyISO_ListDtConvRateMap.containsKey(currency2)) {
      setCurrency.add(currency2);
    }
    if (setCurrency.size() == 0) return;
    system.debug('setCurrency:: '+setCurrency);
    //queryAndLoadConversionRate(setCurrency);
  }
  /*******************************Part Added By Mohit to Update conversion on the basis of DatedConversionRate Object Ends*************/ 
}