/* 5 Nov 2013 Jenna Vuong Added test class for 'filterChatterFeedComment' trigger */

@isTest
private with sharing class filterChatterFeedCommentTEST {
    
    private static testmethod void validateChatterFeedComment() {
    
        // test using a test user
        User testUser = [Select Id,FirstName,LastName,Email,CompanyName from User where IsActive=true and UserType='Standard' limit 1];
        
        FeedItem feedItem = new FeedItem();
        feedItem.ParentId = testUser.Id;
        feedItem.Type = 'TextPost';
        feedItem.Body = 'The mice will see you now.';
        
        insert feedItem;
        
        FeedComment feedComment = new FeedComment();
        feedComment.CommentBody='hello';
        feedComment.FeedItemId = feedItem.Id;
        
        insert feedComment;
        
        
    }

}