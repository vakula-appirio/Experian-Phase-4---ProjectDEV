/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTemplateHelper
 * Description: T-360797: Action Plans: Code
 * Created Date: Feb 10th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 24th, 2015               Arpita Bose                  Updated class to fix the failure of test class
 * Mar 16th, 2015               Noopur                       Modified the variable names
  =====================================================================*/
 global class BusinessProcessTemplateHelper {
   //==========================================================================
   // Webservice method to deepCopy of Business_Process_Template__c
   //==========================================================================
   webservice static String deepCopy(String bpTemplateId) {
     List<Business_Process_Template_Item__c> BPIRecordSetList = new List<Business_Process_Template_Item__c>();
     String newBPTemplateId;
     Business_Process_Template__c  oldBPTemplate = [SELECT Description__c, Name 
                                                 FROM Business_Process_Template__c 
                                                 WHERE id=:bpTemplateId limit 1];
     if (oldBPTemplate == null) {
       return '';
     }
     
     Business_Process_Template__c newService = oldBPTemplate.clone(false, true);
     insert newService;
     newBPTemplateId = newService.id;

     List<String> oldBPIRecordSetList = new List<String>();
     List<String> newBPIRecordSetList = new List<String>();
     for (Business_Process_Template_Item__c[] BPTItem : [SELECT Default_Owner__c, Id, Assign_To_Queue_when_Ready__c, 
                                                                           Description__c, Name, Send_Owner_Email__c, Sequence__c,
                                                                           Business_Process_Template__c, Time_Quota__c,  
                                                                           Wait_On_All_Preds__c, Work_Item_Id__c 
                                                                          FROM Business_Process_Template_Item__c
                                                                          WHERE Business_Process_Template__c =: bpTemplateId]) {
        BPIRecordSetList = new List<Business_Process_Template_Item__c>();
        for (Business_Process_Template_Item__c newBPTItem : BPTItem) {
          Business_Process_Template_Item__c newItem = newBPTItem.clone(false, true);
          newItem.Business_Process_Template__c = newBPTemplateId;
          BPIRecordSetList.add(newItem);
          oldBPIRecordSetList.add(newBPTItem.id);
        }
        
        if (BPIRecordSetList.size() > 0) {
          insert BPIRecordSetList;
        }
        
        for (Integer i = 0; i < BPIRecordSetList.size(); i++ ) {
          newBPIRecordSetList.add(BPIRecordSetList[i].id);
        }    
      }
      
      if ( newBPIRecordSetList.size() > 0 ) {
        List<Business_Process_Template_Item_Link__c> BPTitemLinks = new List<Business_Process_Template_Item_Link__c>();
        for (Business_Process_Template_Item_Link__c[] bptil : [SELECT Id, Loop_Back_Link__c, Name,
                                                                 Predecessor__c, Status__c, Successor__c 
                                                                FROM Business_Process_Template_Item_Link__c  
                                                                WHERE Predecessor__c IN :oldBPIRecordSetList
                                                                OR Successor__c IN :oldBPIRecordSetList]) {
          BPTitemLinks = new List<Business_Process_Template_Item_Link__c>();
          
          for (Business_Process_Template_Item_Link__c newbptil : bptil) {
            Business_Process_Template_Item_Link__c newlink = new Business_Process_Template_Item_Link__c();
            newlink.Loop_Back_Link__c = newbptil.Loop_Back_Link__c;
            newlink.Status__c = newbptil.Status__c;
          
            if (newbptil.Predecessor__c != null) {
              newlink.Predecessor__c = getNewId(oldBPIRecordSetList, newBPIRecordSetList, newbptil.Predecessor__c);
            }
          
            if (newbptil.Successor__c != null) {
              newlink.Successor__c = getNewId(oldBPIRecordSetList, newBPIRecordSetList, newbptil.Successor__c);
            }
            BPTitemLinks.add(newlink);
          }
          
          if (BPTitemLinks.size() > 0) {
            insert BPTitemLinks;
          }
        }
      }
    return newBPTemplateId;
  }
  
  //==========================================================================
  // Getting new Id
  //==========================================================================  
  public static string getNewId(List<String> oldBPIRecordSetList, 
                                 List<String> newBPIRecordSetList, String val) {
    for (Integer i = 0; i < oldBPIRecordSetList.size() ; i++) {
      if (oldBPIRecordSetList[i] == val) {
        return newBPIRecordSetList[i];
      }
    }
    return val;
  }
}