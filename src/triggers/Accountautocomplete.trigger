trigger Accountautocomplete on Order_Split__c (before insert,before update) {

        Order_Split__c[] ordersplits = Trigger.new;
        
        AccountOrderSplitAutofill.orderautofill (ordersplits);
}