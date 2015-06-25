/**=====================================================================
* Date Modified                Modified By                  Description of the update
* Oct 27th, 2014               Pallavi Sharma               Fix Failure
=====================================================================*/
@isTest 
private class RedactedTestClass {
	
	  //Invoke the UserStatus Trigger by doing a feed post on the User object
	  public static testmethod void test_getObjectTypeFromId(){
	    redacted.getObjectTypeFromId('Account');
	  }
	  
	  public static testmethod void test_borderCases(){
	    list<FeedItem> posts = new list<FeedItem>();
	    
	    Redacted_Filter__c thisFilter = new Redacted_Filter__c();
	    thisFilter.Active__c = true;
	    thisFilter.Applies_To__c = 'user;feedComment;feedPost;feedItem';
	    thisFilter.Error_on_Match__c = false;
	    thisFilter.Pattern_String__c = 'hello';
	    thisFilter.Notification_Email_Address__c = 'Kenji776@gmail.com';
	    thisFilter.Replacement_Pattern__c = '**REDACTED**';
	    thisFilter.Replace_Pattern__c = true;
	    thisFilter.Send_Email_on_Match__c = true;
	    thisFilter.Track_Matches__c = true;
	    thisFilter.Email_Poster_On_Match__c = true;
	    
      insert thisFilter;
      
      FeedItem feedItem = new FeedItem();
      feedItem.LinkUrl = 'http://www.google.com';
      feedItem.Type = 'LinkPost';
      feedItem.ParentId = UserInfo.getUserId();
      
      insert feedItem;
      
      FeedItem fItem = new FeedItem();
      fItem.Type = 'TextPost';
      fItem.ParentId = UserInfo.getUserId();
      fItem.Body = 'The hello will see you now';
       posts.add(fItem);
       
       String[] filterFields = new String[] {'Body'};
       redacted.filterObject(posts,filterFields); 
       
       //Introduce an exception by passing an invalid field
       filterFields = new String[] {'Body1'};
       redacted.filterObject(posts,filterFields); 
       
       //Introduce another error by passing in null
       //redacted.filterObject(null,filterFields);  
	  }
	

    public static testmethod void testRedacted()
    {
        Profile thisProfile = [select id from profile where name = 'Chatter Free User'];

        User testUser = new User();
       
        String username = 'TestGuy';
        String domain = 'TestDomain';
   
        username += string.valueOf(Math.random());
        domain += string.valueOf(Math.random());
 
        testUser.username = username+'@'+domain+'.com';
       
        testUser.alias = 'Test';
        testUser.communityNickname = username;
        testUser.firstname = 'Test';
        testUser.lastname = 'Guy';
        testUser.email = 'Test@Test.com';
        testUser.LocaleSidKey = 'en_US';
        testUser.languageLocaleKey = 'en_US';
        testUser.EmailEncodingKey = 'ISO-8859-1';
        testUser.TimeZoneSidKey = 'GMT';
       // testUser.CurrentStatus = 'bleh';
        testUser.profileid = thisProfile.id;
        
        system.debug(testUser);

        insert testUser;
        System.runAs( Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN)){
	        list<FeedItem> posts = new list<FeedItem>();
	       
	        Redacted_Filter__c thisFilter = new Redacted_Filter__c();
	        thisFilter.Active__c = true;
	        thisFilter.Applies_To__c = 'user;feedComment;feedPost;feedItem';
	        thisFilter.Error_on_Match__c = false;
	        thisFilter.Pattern_String__c = '[a-zA-Z]{3}[0-9]{6}[a-zA-Z]';
	        thisFilter.Notification_Email_Address__c = 'Kenji776@gmail.com';
	        thisFilter.Replacement_Pattern__c = '**REDACTED**';
	        thisFilter.Replace_Pattern__c = true;
	        thisFilter.Send_Email_on_Match__c = true;
	        thisFilter.Track_Matches__c = true;
	        
	        insert thisFilter;
	        
	        //This post should not trigger the above rule to fire as it does not contain an account number.
	        FeedItem fItem = new FeedItem();
	        fItem.Type = 'TextPost';
	        fItem.ParentId = testUser.id;
	        fItem.Body = 'The mice will see you now';
	        posts.add(fItem);
	        //This post should trigger the above rule, so afterwards we can query for a tracking object.
	        FeedItem fItem2 = new FeedItem();
	        fItem2.Type = 'TextPost';
	        fItem2.ParentId = testUser.id;
	        fItem2.Body = 'My account number is ABC123456D';
	        posts.add(fItem2);
	       
	        insert posts;          
	        
	        String[] filterFields = new String[] {'Body'};
	       
	        redacted.filterObject(posts,filterFields);
	       
	        list<Redacted_Filter_Match__c> matches = [select id, Poster__c, Filter__c, Chatter_Post__c from Redacted_Filter_Match__c where Filter__c = :thisFilter.id];
	       
	        system.assertEquals(2,matches.size());
	       
	        thisFilter.Error_on_Match__c = true;
	        thisFilter.Error_Message__c = 'Fail!';
	       
	        update thisFilter;
	       
	        posts.clear();
	       
	        FeedItem fItem3 = new FeedItem();
	        fItem3.Type = 'TextPost';
	        fItem3.ParentId = testUser.id;
	        fItem3.Body = 'DERP! My account number is ABC123456D DUURRRRR';        
	        posts.add(fItem3); 
	        
	        redacted.filterObject(posts,filterFields);      
        }
        //Try one link post, it should be ignored
    }
    }