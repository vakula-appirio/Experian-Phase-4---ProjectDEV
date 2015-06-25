/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTrigger_BUHelper
 * Description: T-264797: Refactoring of OpportunityTriggerHandler and Helper classes
 *              The following methods were moved from OpportunityTriggerHandler:
 *                - reAlignBUsOnOwnerChange
 *                - populateBUsOnCreate
 *                - populateParentBUs
 *              FOR HISTORY, REFER TO OpportunityTriggerHandler
 * Created Date: Mar 26th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified          Modified By               Description of the update
 * Mar 28, 2014           Nathalie Le Guay          Changed to 'without sharing'
 * Apr 22, 2014           Nathalie Le Guay          commenting reAlignBUsOnOwnerChange
 =====================================================================*/
public without sharing class OpportunityTrigger_BUHelper {
  
  //============================================================================================
  // Method to check Owner change and align BU lookup fields.
  //============================================================================================
   /* commented NLG April 22nd 2014
    public static void reAlignBUsOnOwnerChange(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap) {
    Set<Id> setOwnerIds = new Set<Id>();
    Set<Id> setOwnerChangeOppIds = new Set<Id>();
    Set<Id> setAccountIds = new Set<Id>();
    Map<Id, User> mapUsers = new Map<Id, User>();
    Map<String,Id> mapAccBUs= new Map<String,Id>();
    List<BU_Relationship__c> lstBUsToCreate = new List<BU_Relationship__c>();
    Set<Id> setBUsToDelete = new Set<Id>();

    for(Opportunity oldOppRec:oldMap.values()) {
      Opportunity newOppRec = newMap.get(oldOppRec.id);
      //Check if Owner has changed.
      if(oldOppRec.OwnerId != newOppRec.OwnerId) {
        setOwnerIds.add(oldOppRec.OwnerId);
        setOwnerIds.add(newOppRec.OwnerId);
        setAccountIds.add(newOppRec.AccountId);
        setOwnerChangeOppIds.add(newOppRec.id);
      }
    }//END: FOR oldOppRec
       
    //Retrieve Old+New User data.
    //Map<Id, User> mapUsers = new Map<Id, User>([SELECT ID, Business_Unit__c, Global_Business_Line__c FROM User WHERE id=:setOwnerIds]);
    
    //Updated for populate map through loop not direct from soql. nojha mar 26, 14.
    for (User u : [SELECT ID, Business_Unit__c, Global_Business_Line__c FROM User WHERE id=:setOwnerIds]) {
      mapUsers.put(u.ID, u);
    } 
    
    //Retrieve Account Related BUs.
    for(Account accRec:[SELECT  ID, 
                            (SELECT Id, Account__c, Global_Line_of_Business_or_BU__c 
                             FROM BU_Relationships__r 
                             WHERE Global_Line_of_Business_or_BU__c != null) 
                        FROM Account WHERE Id =:setAccountIds]) {
      for(BU_Relationship__c buRec:accRec.BU_Relationships__r) {
        mapAccBUs.put(buRec.Account__c + buRec.Global_Line_of_Business_or_BU__c, buRec.ID);
      }
    }
               
    //Iterate through Owner changed Records.
    for(Id oppId:setOwnerChangeOppIds) {
      Opportunity oldOppRec = oldMap.get(oppId);
      Opportunity newOppRec = newMap.get(oppId);
           
      //Add new BUs if does not exist for Accounts.
      
      // Updated 31/10/13 Shane Khublall , naming convention for new BU Relationship records
      String BURelName ='';  // 31/10/13 Shane Khublall
      if(mapUsers.containsKey(newOppRec.OwnerId)) {
        if(mapUsers.get(newOppRec.OwnerId).Business_Unit__c != null && 
          !mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Business_Unit__c)) {
            if(mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c != null) { // 31/10/13 Shane Khublall
              BURelName += mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c;  // 31/10/13 Shane Khublall
            }       
            BURelName += ('/' + mapUsers.get(newOppRec.OwnerId).Business_Unit__c);  // 31/10/13 Shane Khublall
            lstBUsToCreate.add(new BU_Relationship__c(Account__c=newOppRec.AccountId, Name=BURelName,   // 31/10/13 Name field. Shane Khublall
            Global_Line_of_Business_or_BU__c=mapUsers.get(newOppRec.OwnerId).Business_Unit__c));
          }
                   
          if(mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c != null  && 
              !mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c)) {
            lstBUsToCreate.add(new BU_Relationship__c(Account__c=newOppRec.AccountId, Name = mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c,  // 31/10/13 Name field. Shane Khublall
            Global_Line_of_Business_or_BU__c=mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c));
          }
        }//END: IF newOwner in mapUsers
          
        //Identify previous Owner's BU records to delete. Only when BU value of old and new User is different. 
        if(mapUsers.containsKey(oldOppRec.OwnerId)) {
          if(mapUsers.get(oldOppRec.OwnerId).Business_Unit__c != null && 
              mapAccBUs.containsKey(oldOppRec.AccountId+mapUsers.get(oldOppRec.OwnerId).Business_Unit__c) && 
              mapUsers.get(oldOppRec.OwnerId).Business_Unit__c != mapUsers.get(newOppRec.OwnerId).Business_Unit__c) {
            setBUsToDelete.add(mapAccBUs.get(oldOppRec.AccountId + mapUsers.get(oldOppRec.OwnerId).Business_Unit__c));
          }
                 
          if(mapUsers.get(oldOppRec.OwnerId).Global_Business_Line__c != null  && 
              mapAccBUs.containsKey(oldOppRec.AccountId+mapUsers.get(oldOppRec.OwnerId).Global_Business_Line__c) && 
              mapUsers.get(oldOppRec.OwnerId).Global_Business_Line__c != mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c) {
            setBUsToDelete.add(mapAccBUs.get(oldOppRec.AccountId+mapUsers.get(oldOppRec.OwnerId).Global_Business_Line__c));
          }
        }//END: IF oldOwner in mapUsers
      }//END: FOR oppId
       
      //Create new BUs
      if(lstBUsToCreate.size() > 0) {
        insert lstBUsToCreate;
      }       
      //Add newly created BU record ids to map.
      for(BU_Relationship__c buRec:lstBUsToCreate) {
        mapAccBUs.put(buRec.Account__c+buRec.Global_Line_of_Business_or_BU__c,buRec.id);
      }  
       
      //Populate OwnerChanged Opportunities BU lookup fields.
      for(Id oppId:setOwnerChangeOppIds) {
        Opportunity newOppRec = newMap.get(oppId);
          
        //Flush old values.
        newOppRec.Business_Unit__c = null;
        newOppRec.Global_Line_of_Business__c = null;
          
         if(mapUsers.get(newOppRec.OwnerId).Business_Unit__c != null && mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Business_Unit__c)) {
           newOppRec.Business_Unit__c = mapAccBUs.get(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Business_Unit__c);
         }
                 
         if(mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c!=null  && mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c)) {
           newOppRec.Global_Line_of_Business__c=mapAccBUs.get(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c);
         }
       }//END: FOR oppId
       
       //Check the BUs to delete against Opportunities if there are any other Opps linked then should NOT be deleted.
       Set<Id> setBUsWithoutOppToDelete = new Set<Id>();
       for(AggregateResult agrRec: [SELECT  Business_Unit__c, count(Id) from Opportunity where Business_Unit__c =: setBUsToDelete group by Business_Unit__c having count(Id) < 2]) {
         setBUsWithoutOppToDelete.add((Id)agrRec.get('Business_Unit__c'));
       }
       
       for(AggregateResult agrRec: [SELECT  Global_Line_of_Business__c, count(Id) from Opportunity where Global_Line_of_Business__c =: setBUsToDelete group by Global_Line_of_Business__c having count(Id) < 2]) {
         setBUsWithoutOppToDelete.add((Id)agrRec.get('Global_Line_of_Business__c'));
       }
       
       //Delete BUs
       if(setBUsWithoutOppToDelete.size() > 0) {
         List<BU_Relationship__c> lstBUsToDel = new List<BU_Relationship__c>();
         for(Id buId:setBUsWithoutOppToDelete) {
           lstBUsToDel.add(new BU_Relationship__c(Id=buId));
         }
         //Delete records.
         delete lstBUsToDel;    
       }//END: If
   }//END: Method reAlignBUsOnOwnerChange */

  //============================================================================================
  //Method to check Owner change and align BU lookup fields.
  //============================================================================================
  /*public static void populateBUsOnCreate(List<Opportunity> lstNewOpps) {
    Set<Id> setOwnerIds = new Set<Id>();
    Set<Id> setAccountIds = new Set<Id>();
       
    Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
       
    for(Opportunity newOppRec:lstNewOpps) {
      //Get Owner and Acc Ids.
      setOwnerIds.add(newOppRec.OwnerId);
      setAccountIds.add(newOppRec.AccountId);
    }//END: FOR oldOppRec
       
    //Retrieve Old+New User data.
    Map<Id,User> mapUsers = new Map<Id,User>([select id,Business_Unit__c,Global_Business_Line__c from User where id=:setOwnerIds]);
    Map<String,Id> mapAccBUs= new Map<String,Id>();
      
    //Retrieve Account Related BUs.
    for(Account accRec:[SELECT  id, (SELECT Id, Account__c, Global_Line_of_Business_or_BU__c FROM BU_Relationships__r where Global_Line_of_Business_or_BU__c!=null) from Account where Id =: setAccountIds]) {
      for(BU_Relationship__c buRec:accRec.BU_Relationships__r) {
        mapAccBUs.put(buRec.Account__c + buRec.Global_Line_of_Business_or_BU__c, buRec.id);
      }
    }
               
    Map<String,BU_Relationship__c> mapBUsToCreate = new Map<String,BU_Relationship__c>();

    //Iterate through Owner changed Records.
    for(Opportunity newOppRec:lstNewOpps) {
      //Add new BUs if does not exist for Accounts.
      // Updated 31/10/13 Shane Khublall
      String BURelName ='';  // 31/10/13 Shane Khublall           
      if(mapUsers.containsKey(newOppRec.OwnerId)) {
        if(mapUsers.get(newOppRec.OwnerId).Business_Unit__c!=null && !mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Business_Unit__c)) {
          if(mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c != null) { // 31/10/13 Shane Khublall
              BURelName += mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c;  // 31/10/13 Shane Khublall
          }
          BURelName += ('/' + mapUsers.get(newOppRec.OwnerId).Business_Unit__c);  // 31/10/13 Shane Khublall                       
          /*
          lstBUsToCreate.add(new BU_Relationship__c(Account__c=newOppRec.AccountId,CurrencyISOCode='USD', Name=BURelName,   // 31/10/13 Shane Khublall
          Global_Line_of_Business_or_BU__c=mapUsers.get(newOppRec.OwnerId).Business_Unit__c));
          *
                       
          BU_Relationship__c buTmpRec = new BU_Relationship__c(Account__c=newOppRec.AccountId,CurrencyISOCode=custSettings.BU_Default_Currency__c, Name=BURelName,   // 31/10/13 Shane Khublall
          Global_Line_of_Business_or_BU__c=mapUsers.get(newOppRec.OwnerId).Business_Unit__c);
                               
          mapBUsToCreate.put(buTmpRec.Account__c+buTmpRec.Global_Line_of_Business_or_BU__c,buTmpRec); 
        }
                   
        if(mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c!=null  && !mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c)) {
          /*lstBUsToCreate.add(new BU_Relationship__c(Account__c=newOppRec.AccountId, CurrencyISOCode='USD',Name = mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c,  // 31/10/13 Shane Khublall
            Global_Line_of_Business_or_BU__c=mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c));
           *
                               
           BU_Relationship__c buTmpRec = new BU_Relationship__c(Account__c=newOppRec.AccountId, CurrencyISOCode=custSettings.BU_Default_Currency__c,Name = mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c,  // 31/10/13 Shane Khublall
           Global_Line_of_Business_or_BU__c=mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c);
                       
           mapBUsToCreate.put(buTmpRec.Account__c+buTmpRec.Global_Line_of_Business_or_BU__c,buTmpRec);         
         }
       }//END: IF newOwner in mapUsers
     }//END: FOR oppId
       
     //Create new BUs
     /*
     if(lstBUsToCreate.size()>0)
        insert lstBUsToCreate;
     *
     if(mapBUsToCreate.size() > 0)
        insert mapBUsToCreate.values();    
       
     //Add newly created BU record ids to map.
     //for(BU_Relationship__c buRec:lstBUsToCreate)
     for(BU_Relationship__c buRec:mapBUsToCreate.values()) {
        mapAccBUs.put(buRec.Account__c+buRec.Global_Line_of_Business_or_BU__c,buRec.id);
     }  
       
     //Populate OwnerChanged Opportunities BU lookup fields.
     //for(Id oppId:setOwnerChangeOppIds)
     /*for(Opportunity newOppRec:lstNewOpps) { // NLG Commented out Apr 24 2014
        //Flush old values.
       newOppRec.Business_Unit__c=null;
       newOppRec.Global_Line_of_Business__c=null;
          
       if(mapUsers.get(newOppRec.OwnerId).Business_Unit__c!=null && mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Business_Unit__c)) {
          newOppRec.Business_Unit__c=mapAccBUs.get(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Business_Unit__c);
       }
                 
       if(mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c!=null  && mapAccBUs.containsKey(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c)) {
         newOppRec.Global_Line_of_Business__c=mapAccBUs.get(newOppRec.AccountId+mapUsers.get(newOppRec.OwnerId).Global_Business_Line__c);
       }
     }//END: FOR oppId*/
       
     /*
     //Check the BUs to delete against Opportunities if there are any other Opps linked then should NOT be deleted.
     Set<Id> setBUsWithoutOppToDelete = new Set<Id>();
     for(AggregateResult agrRec: [SELECT  Business_Unit__c, count(Id) from Opportunity where Business_Unit__c=:setBUsToDelete group by Business_Unit__c having count(Id)<2])
     {
         setBUsWithoutOppToDelete.add((Id)agrRec.get('Business_Unit__c'));
     }
     
     for(AggregateResult agrRec: [SELECT  Global_Line_of_Business__c, count(Id) from Opportunity where Global_Line_of_Business__c=:setBUsToDelete group by Global_Line_of_Business__c having count(Id)<2])
     {
         setBUsWithoutOppToDelete.add((Id)agrRec.get('Global_Line_of_Business__c'));
     }
     
     system.debug('###############setBUsWithoutOppToDelete################'+setBUsWithoutOppToDelete);
       
     //Delete BUs
     if(setBUsWithoutOppToDelete.size()>0)
     {
         List<BU_Relationship__c> lstBUsToDel = new List<BU_Relationship__c>();
         for(Id buId:setBUsWithoutOppToDelete)
             lstBUsToDel.add(new BU_Relationship__c(Id=buId));
             
         //Delete records.
         delete lstBUsToDel;    
     }//END: If
     *
   }//END: Method populateBUsOnCreate*/

  //============================================================================================   
  // For new/updated Opportunities, Update Child BU's Parent Lookup with GLB Id.
  //============================================================================================
  /* commented NLG April 22nd 2014 
  public static void populateParentBUs(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap) {
     List<BU_Relationship__c> lstBUsToUpdate = new List<BU_Relationship__c>();
     Map<Id,BU_Relationship__c> mapBUsToUpdate = new Map<Id,BU_Relationship__c>();
     //Set<BU_Relationship__c> lstBUsToUpdate = new List<BU_Relationship__c>();
       
     //If Opportunity is New or BUs lookup field values has changed then update the BU records to reflect correct relationship.
     for(Opportunity newOppRec: newMap.values()) {
       if(oldMap == null || newOppRec.Business_Unit__c != oldMap.get(newOppRec.id).Business_Unit__c ||  
               newOppRec.Global_Line_of_Business__c != oldMap.get(newOppRec.id).Global_Line_of_Business__c) {
         if(newOppRec.Business_Unit__c != null)
             mapBUsToUpdate.put(newOppRec.Business_Unit__c,new BU_Relationship__c(id=newOppRec.Business_Unit__c,Parent__c=newOppRec.Global_Line_of_Business__c));
                      //lstBUsToUpdate.add(new BU_Relationship__c(id=newOppRec.Business_Unit__c,Parent__c=newOppRec.Global_Line_of_Business__c));
       }
     }
       
     //Update BU records.        
     //if(lstBUsToUpdate.size()>0)
         //update lstBUsToUpdate;
      if(mapBUsToUpdate.size() > 0) {
        update mapBUsToUpdate.values();
      }    

   }//END: Method populateParentBUs*/
}