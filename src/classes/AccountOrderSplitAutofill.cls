public class AccountOrderSplitAutofill {
   public static void orderautofill(Order_Split__c[] ordersplits) {
      for (Order_Split__c b :ordersplits){
         b.Account__c  = b.Account_ID__c;
         }      
   }
}