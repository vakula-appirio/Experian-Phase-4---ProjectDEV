/**************************************************************
Name  : AriaOrder_CloneController.cls
Author: James Weatherall
Date  : May 19th, 2014
Description: Extension class for the VF page behind the Clone 
             button on Aria Order
  
***************************************************************/
public with sharing class AriaOrder_CloneController{

    private final ARIA_Order__c ariaOrder;
    private Id orderId {get; set;}
    private Id newOrderId {get; set;}
    
    public AriaOrder_CloneController(ApexPages.StandardController controller) {
        ariaOrder = (ARIA_Order__c)controller.getRecord();
        orderId = ariaOrder.Id;  
    }

    public PageReference runClone()
    {
        PageReference orderPage;
        
        try {
            // Create the new Order
            newOrderId = cloneOrder();
            // Copy the lines and add to new Order
            cloneOrderLines();
            // Take user to new Order
            orderPage = new PageReference('/' + newOrderId + '/e?retURL=%2F' + newOrderId);
            orderPage.setRedirect(true);            
        } catch(System.Exception ex) {
            String errorHeader = 'There was a problem with the runClone method.'; 
            System.debug(errorHeader);
            System.debug('Exception type caught: ' + ex.getTypeName());
            System.debug('Message: ' + ex.getMessage());    
            System.debug('Cause: ' + ex.getCause());    
            System.debug('Line number: ' + ex.getLineNumber());    
            System.debug('Stack trace: ' + ex.getStackTraceString());                   
        }
        return orderPage;
    }
    
    public Id cloneOrder()
    { 
        String soql = ARIAOrderClone_Utils.getCreatableFieldsSOQL('Aria_Order__c', 'id=\'' + orderId + '\'');
        ARIA_Order__c ao = (ARIA_Order__c)Database.query(soql);
        ARIA_Order__c newOrder = ao.clone(false, true);     
        Global_Settings__c aort = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);

        // Update values for new Order
        newOrder.RecordTypeId = aort.ARIA_Order_Standard_RecordTypeId__c;
        newOrder.ARIA_Order_Ref_Number__c = '';
        newOrder.Status__c = 'Draft';
        newOrder.Order_Received_in_ARIA__c = false;
        newOrder.SendOrdertoAria__c = false;
        newOrder.Push_To_Aria_Datetime__c = null;
        newOrder.Experian_ID__c = '';
        insert newOrder;
        
        return newOrder.Id;
    }
    
    public void cloneOrderLines()
    {
        List<Aria_Order_Items_Detail__c> lstOldAriaOrderItems = new List<Aria_Order_Items_Detail__c>();
        List<Aria_Order_Items_Detail__c> lstNewAriaOrderItems = new List<Aria_Order_Items_Detail__c>();
        
        String soql =ARIAOrderClone_Utils.getCreatableFieldsSOQL('Aria_Order_Items_Detail__c', 'ARIA_Order__c=\'' + orderId + '\'');
        lstOldAriaOrderItems = Database.query(soql);
        for(Aria_Order_Items_Detail__c aoid : lstOldAriaOrderItems)
        {
            Aria_Order_Items_Detail__c newAoid = aoid.clone(false, true);
            newAoid.ARIA_Order__c = newOrderId; // Update ARI_Order__c with new Order Id
            lstNewAriaOrderItems.add(newAoid); 
        } 
        insert lstNewAriaOrderItems; 
    }
}