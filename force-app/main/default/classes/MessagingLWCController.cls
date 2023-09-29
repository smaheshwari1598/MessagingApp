public with sharing class MessagingLWCController {
    
    @AuraEnabled(cacheable = true)
    public static List<Message__c> getMessages(String contactId){
            List<Message__c> listOfMessages = [Select Id,Is_Outbound__c, Message_Content__c, CreatedBy.name, CreatedDate, Contact__r.Name from Message__c WHERE Contact__c=: contactId ORDER BY CreatedDate ];
            return listOfMessages;
    }
    
    @AuraEnabled
    public static void createMessage(String messageBody,String contactId){
        Contact conRec = [SELECT Phone from Contact where Id =:contactId LIMIT 1];
        TwilioSendSMS.SendSMS(messageBody,String.valueOf(conRec.Phone));
        Message__c messageRec = new Message__c();
        messageRec.Is_Outbound__c = true;
        messageRec.Message_Content__c = messageBody;
        messageRec.Contact__c = contactId;
        insert messageRec;
        
    }
}
