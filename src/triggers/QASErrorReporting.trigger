trigger QASErrorReporting on QAS_NA__QAS_CA_Account__c(after update) {
    for (Integer currentRecord = 0; currentRecord < trigger.new.size(); ++currentRecord) { 
         QAS_NA__QAS_CA_Account__c newRecord = trigger.new[currentRecord];
         QAS_NA__QAS_CA_Account__c oldRecord = trigger.old[currentRecord];
        
        if((newRecord.QAS_NA__ValidationSessionToken__c!= null || oldRecord.QAS_NA__ValidationSessionToken__c!= null)
            && newRecord.QAS_NA__ValidationSessionToken__c!= oldRecord.QAS_NA__ValidationSessionToken__c) {
                String[] ccAddresses = new String[1];
                ccAddresses[0] = 'kos.mitev@aptsys.net';
                
                String[] toAddresses = new String[1];
                 toAddresses[0] = 'kelly@aptsys.net';
                
                String subject = 'The token for Experian was successfully refreshed.';
                String message = 'Hello,\nThe session token for Experian was successfully refreshed. The new token is: '  + newRecord.QAS_NA__ValidationSessionToken__c;   
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setCcAddresses(ccAddresses);
                mail.setSubject(subject);
                mail.setUseSignature(false);
                mail.setHtmlBody(message);
                // Send the email
                if(!Test.isRunningTest()) {
                  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
        } 
    }
}