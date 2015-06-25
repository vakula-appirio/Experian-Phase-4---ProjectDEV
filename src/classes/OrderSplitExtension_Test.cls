/**=====================================================================
 * Appirio, Inc
 * Test Class Name: OrderSplitExtension_Test
 * Class Name: OrderSplitExtension
 * Description: To test functionality of OrderSplitExtension
 * Created Date: Apr 21st, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 30th, 2014               Arpita Bose(Appirio)         Updated createTestData() method to fix the failure
 * May 21st, 2014               Nathalie Le Guay             I-115230: Created testOrderSplitOwnerChangeFunctionality()
 =====================================================================*/
@isTest
private class OrderSplitExtension_Test {
  private static Order__c currentOrder;
  private static User user1;
  private static User user2;
  private static OrderSplitExtension.orderSplitWrapper split1;
  private static OrderSplitExtension.orderSplitWrapper split2;
  
  /*static testMethod void testOrderSplitFunctionality() {
    createTestData();
    
    System.assert(currentOrder.ID != null);
    PageReference pageRef = Page.OrderSplit;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
    
    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(currentOrder);
    OrderSplitExtension controller = new OrderSplitExtension(sc);
    
    //There is no order split currently
    System.assertEquals(controller.defaultOrdSplits.size(), 3);  
    //Added blank row
    controller.addNewRow();
    
    //Without selecting any user/percentage  
    controller.calculateSplits();
    System.assert(String.valueOf(ApexPages.getMessages()).contains(Label.ORD_SPLIT_REQD_ERR_TEAM_PERCENT));
    
    //Selected user but percent total is not 100  
    split1.orderSplit.Split_Percentage__c = 40;
    controller.mapIndexToDefaultOrderSplitWrapper.put(0, split1);
    controller.calculateSplits();
    System.assert(String.valueOf(ApexPages.getMessages()).contains(Label.ORD_SPLIT_PERCENT_REQD_TOBE_100));
    
    controller.mapIndexToDefaultOrderSplitWrapper.put(1, split2);
    controller.calculateSplits();
    
    //System.assert(String.valueOf(ApexPages.getMessages()).contains(Label.ORD_SPLIT_MSG_SUCCESS));
    
    List<Order_Split__c> ordSplits = [SELECT ID, Split_Percentage__c,
                                             Credited_To__c, Credited_To_Sales_Team__c,
                                             Credited_To_GBL__c, Credited_To_Sales_Sub_Team__c,
                                             Credited_To_BU__c, Credited_To_BL__c,
                                             Credited_To_Country__c, Credited_To_Region__c
                                      FROM Order_Split__c WHERE Order__c =: currentOrder.ID];
    System.assertEquals(ordSplits.size(), 2);
    
    System.assertEquals(ordSplits.get(0).Split_Percentage__c, 40);
    System.assertEquals(ordSplits.get(1).Split_Percentage__c, 60);
    System.assertNotEquals(ordSplits.get(1).Credited_To_GBL__c, null);
    System.assertNotEquals(ordSplits.get(0).Credited_To_BL__c, null);
    System.assertNotEquals(ordSplits.get(0).Credited_To_BU__c, null);
    
    Test.stopTest();    
  }

  //Deleting split lines.
  static testMethod void testExistingSplitShowAndDelete() {
    createTestData();
       
    System.assert(currentOrder.ID != null);
    PageReference pageRef = Page.OrderSplit;
    Test.setCurrentPage(pageRef);
    
    
    
    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(currentOrder);
    OrderSplitExtension controller = new OrderSplitExtension(sc);
    
    //There is no order split currently
    System.assertEquals(controller.defaultOrdSplits.size(), 3);  
    
    controller.mapIndexToDefaultOrderSplitWrapper.put(0, split1);
    controller.mapIndexToDefaultOrderSplitWrapper.put(1, split2);
    controller.calculateSplits();
    System.assert(String.valueOf(ApexPages.getMessages()).contains(Label.ORD_SPLIT_MSG_SUCCESS));
    
    List<Order_Split__c> ordSplits = [SELECT ID, Split_Percentage__c, Credited_To__c FROM Order_Split__c WHERE Order__c =: currentOrder.ID];
    System.assertEquals(ordSplits.size(), 2);
    
    System.assertEquals(ordSplits.get(0).Split_Percentage__c, 40);
    System.assertEquals(ordSplits.get(1).Split_Percentage__c, 60);

    Test.startTest();
    
    sc = new ApexPages.Standardcontroller(currentOrder);
    controller = new OrderSplitExtension(sc);    
    
    //Default two wplits loaded
    System.assert(controller.orderSplitList.size() == 2);
    
    controller.toDeleteOrderSplitRowId = '1';
    controller.toDeleteOrderSplitId = ordSplits.get(0).ID;
    controller.deleteOrderSplit();
    controller.calculateSplits();
    
    ordSplits = [SELECT ID, Split_Percentage__c, Credited_To__c FROM Order_Split__c WHERE Order__c =: currentOrder.ID];
    System.debug('[**controller.mapIndexToOrderSplitWrapper**]'+controller.mapIndexToOrderSplitWrapper);
    System.debug('[**controller.mapIndexToDefaultOrderSplitWrapper**]'+controller.mapIndexToDefaultOrderSplitWrapper);
    System.debug('[**ordSplits***]'+ordSplits);
    //Removed a split
    System.assertEquals(controller.mapIndexToOrderSplitWrapper.size(), 1);
    //Adding blank row
    controller.addNewRow();
    System.assertEquals(controller.mapIndexToOrderSplitWrapper.size(), 2);
    
    Integer prevRow = controller.mapIndexToDefaultOrderSplitWrapper.size();
    controller.toDeleteOrderSplitRow = '1';
    controller.deleteDefaultOrderSplitRow();
    //deleted one new row
    System.assertEquals(controller.mapIndexToDefaultOrderSplitWrapper.size(), prevRow-1);
    Test.stopTest();    
  }*/

  static testMethod void testOrderSplitOwnerChangeFunctionality() {
    createTestData();
    
    System.assert(currentOrder.ID != null);
    PageReference pageRef = Page.OrderSplit;
    Test.setCurrentPage(pageRef);
    
    Test.startTest();
    
    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(currentOrder);
    OrderSplitExtension controller = new OrderSplitExtension(sc);
    
    
    split1.orderSplit.Split_Percentage__c = 40;
    controller.mapIndexToDefaultOrderSplitWrapper.put(0, split1);
    split2.orderSplit.Split_Percentage__c = 60;
    controller.mapIndexToDefaultOrderSplitWrapper.put(1, split2);
    controller.calculateSplits();

    List<Order_Split__c> ordSplits = [SELECT ID, Split_Percentage__c, OwnerId,
                                             Credited_To__c, Credited_To_Sales_Team__c,
                                             Credited_To_GBL__c, Credited_To_Sales_Sub_Team__c,
                                             Credited_To_BU__c, Credited_To_BL__c,
                                             Credited_To_Country__c, Credited_To_Region__c
                                      FROM Order_Split__c WHERE Order__c =: currentOrder.ID];
    
    // Verify the Credited_To_XX__c are stamped from the Owner record
    for (Order_Split__c orderSplit: ordSplits) {
      if (orderSplit.Id == split1.OrderSplit.Id) {
        system.assertEquals(user1.Business_Line__c, orderSplit.Credited_To_BL__c);
        system.assertEquals(user1.Business_Unit__c, orderSplit.Credited_To_BU__c);
        system.assertEquals(user1.Global_Business_Line__c, orderSplit.Credited_To_GBL__c);
      }
    }
    
    
    // Change the OwnerId (represented with "TEAM MEMBER" on the VF page)
    split1.orderSplit.OwnerId = user2.Id;
    split1.orderSplit.Split_Percentage__c = 40;
    split2.orderSplit.Split_Percentage__c = 60;
    controller.mapIndexToOrderSplitWrapper.put(0, split1);
    controller.mapIndexToOrderSplitWrapper.put(1, split2);
    controller.calculateSplits();
    
    Test.StopTest();
    
    ordSplits = [SELECT ID, Split_Percentage__c, OwnerId,
                                             Credited_To__c, Credited_To_Sales_Team__c,
                                             Credited_To_GBL__c, Credited_To_Sales_Sub_Team__c,
                                             Credited_To_BU__c, Credited_To_BL__c,
                                             Credited_To_Country__c, Credited_To_Region__c
                                      FROM Order_Split__c WHERE Order__c =: currentOrder.ID];
    
    // Verify the OwnerId is changed, but none of the Credited_To_XX__c field are changed
    for (Order_Split__c orderSplit: ordSplits) {
      if (orderSplit.Id == split1.orderSplit.Id) {
        system.assertEquals(user2.Id, orderSplit.OwnerId);
        system.assertEquals(user1.Id, orderSplit.Credited_To__c);
        system.assertEquals(user1.Business_Line__c, orderSplit.Credited_To_BL__c);
        system.assertEquals(user1.Business_Unit__c, orderSplit.Credited_To_BU__c);
        system.assertEquals(user1.Global_Business_Line__c, orderSplit.Credited_To_GBL__c);
      }
    }
    
    
  }
  
  private static void createTestData () {
    //Create Account
    Account acc = Test_Utils.insertAccount();
    //Create Contact
    Contact cont = Test_Utils.insertContact(acc.ID);
    //Create order
    currentOrder = new Order__c (Name='test Order', Contract_Start_Date__c = Date.Today(),
                           Locked__c = false,  Type__c = 'New', Account__c = acc.Id, 
                           Contact__c = cont.Id, Opportunity__c = null, Close_Date__c = Date.Today()+30,
                           Contract_Number__c = '1234test',Transactional_Sale__c = true);
    insert currentOrder;
    
    //create order line items
    Test_Utils.insertOrderLineItems(true, currentOrder.ID, null);
    
    //Create users
    user1 = Test_Utils.createUser('System Administrator');
    user1.Business_Line__c = 'TEST Business Line';
    user1.Business_Unit__c = 'TEST Business Unit';
    user1.Country__c = 'United Kingdom';
    user1.Region__c = 'UK&I';
    user1.Global_Business_Line__c = 'TEST Global Business Line';
    user2 = Test_Utils.createUser('System Administrator');
    user2.Business_Line__c = 'TEST Business Line';
    user2.Business_Unit__c = 'TEST Business Unit';
    user2.Country__c = 'United Kingdom';
    user2.Region__c = 'UK&I';
    user2.Global_Business_Line__c = 'TEST Global Business Line';
    List<User> userList = new List<User>{user1, user2};
    insert userList;
    
    System.debug('[UserInserted]'+userList);
    
    //Creating split 1
    Order_Split__c orderSplit = new Order_Split__c();
    orderSplit.OwnerId = user1.ID;
    orderSplit.Order__c = currentOrder.Id;
    orderSplit.Split_Percentage__c = 40;
    
    split1 = new OrderSplitExtension.orderSplitWrapper();
    split1.orderSplit = orderSplit;
    
    //Creating split 2
    Order_Split__c orderSplit2 = new Order_Split__c();
    orderSplit2.OwnerId = user2.ID;
    orderSplit2.Order__c = currentOrder.Id;
    orderSplit2.Split_Percentage__c = 60;
    
    split2 = new OrderSplitExtension.orderSplitWrapper();
    split2.orderSplit = orderSplit2;
    delete [SELECT ID FROM Order_Split__c WHERE Order__c =: currentOrder.ID];
  }
}