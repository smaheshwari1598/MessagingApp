public with sharing class MessagingLWCController {
    
    @AuraEnabled(cacheable = true)
    public static MessagingWrapper getMessages(String contactId, String offSetValFromUI){
        	MessagingWrapper msgWrapper = new MessagingWrapper();
        	Integer totalMessagesCount = [SELECT Count() FROM Message__c WHERE Contact__c = :contactId];
        	Integer offSetVal=0;
        	
        	String strQuery = 'Select Id,Is_Outbound__c, Message_Content__c, CreatedBy.name, CreatedDate,Is_Delivered__c,Contact__r.Name FROM Message__c WHERE Contact__c = \'' + contactId + '\'';
        	
            if(totalMessagesCount > Integer.ValueOf(Label.MessagePerPage)){
                if(String.IsNotBlank(offSetValFromUI)){
                       if(Integer.valueOf(offSetValFromUI) >= 0){
                           offSetVal = Integer.Valueof(offSetValFromUI);
                       }else{
                           offSetVal=0;
                       }
                }else{
                    offSetVal = totalMessagesCount - Integer.ValueOf(Label.MessagePerPage);
                    strQuery += ' ORDER BY CreatedDate LIMIT '+ Label.MessagePerPage;
                }
            }
              
            Contact conRec = getContactDetails(contactId);
        	strQuery += ' OFFSET '+ offSetVal;
        
        	List<Message__c> listOfMessages = Database.query(strQuery);
            msgWrapper.contactRecord = conRec;
            msgWrapper.messages = listOfMessages;
        	msgWrapper.defaultOffSet = offSetVal;
            return msgWrapper;
    }
    
    @AuraEnabled
    public static void createMessage(String messageBody,String contactId){
        Contact conRec = getContactDetails(contactId);
        
        String delieveryStatusCode = TwilioSendSMS.SendSMS(messageBody,String.valueOf(conRec.Phone));
        
        Message__c messageRec = new Message__c();
        messageRec.Is_Outbound__c = true;
        messageRec.Message_Content__c = messageBody;
        messageRec.Recipient_Number__c = conRec.Phone;
        messageRec.Sender_Number__c = Constants.SENDER_NUMBER;
        messageRec.Contact__c = contactId;
        if(delieveryStatusCode == '201'){
            messageRec.Is_Delivered__c = true;
        }else{
            messageRec.Is_Delivered__c = false;
        }
        try {
            insert messageRec;
        } catch (Exception e) {
            System.debug('Error while saving SMS message: ' + e.getMessage());
        }        
    }
    
    public static Contact getContactDetails(String contactId){
        return [SELECT Id, Phone, Name from Contact where Id =:contactId LIMIT 1];
    }

    public class MessagingWrapper{
        @AuraEnabled
        public Contact contactRecord{get;set;}
        @AuraEnabled
        public List<Message__c> messages{get;set;}
        @AuraEnabled
        public Integer defaultOffSet{get;set;}
    }
}