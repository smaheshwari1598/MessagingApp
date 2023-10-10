public with sharing class MessagingLWCController {
    
    @AuraEnabled(cacheable = true)
    public static MessagingWrapper getMessages(String contactId, String offSetValFromUI){
        	MessagingWrapper msgWrapper;
        	Integer totalMessagesCount = [SELECT Count() FROM Message__c WHERE Contact__c = :contactId WITH USER_MODE];
        	Integer offSetVal=0;
        	
        	String strQuery = 'Select Id,Is_Outbound__c, Message_Content__c, CreatedBy.name, CreatedDate,Is_Delivered__c,Contact__r.Name FROM Message__c WHERE Contact__c = \'' + contactId + '\'';
            
        	if(totalMessagesCount > Integer.ValueOf(Label.MessagePerPage)){
                offSetVal = calOffSetValue(totalMessagesCount,offSetValFromUI);
            }
            strQuery += (totalMessagesCount > Integer.ValueOf(Label.MessagePerPage) && String.IsBlank(offSetValFromUI))?(' ORDER BY CreatedDate LIMIT '+ Label.MessagePerPage):'';
        
            Contact conRec = getContactDetails(contactId);
        	strQuery += ' OFFSET '+ offSetVal;
        
        	List<Message__c> listOfMessages = Database.query(strQuery,AccessLevel.USER_MODE);
        	msgWrapper = new MessagingWrapper(conRec, listOfMessages,offSetVal);
            return msgWrapper;
    }
    
    public static Integer calOffSetValue(Integer totalMessagesCount, String offSetValFromUI){
        Integer offSetVal=0;
         
        if(String.IsNotBlank(offSetValFromUI)){
            return ((Integer.valueOf(offSetValFromUI) >= 0)?Integer.Valueof(offSetValFromUI):0);
        }else{
            return (totalMessagesCount - Integer.ValueOf(Label.MessagePerPage));
        }
    }
    
    @AuraEnabled
    public static void createMessage(String messageBody,String contactId, String fileName, String fileData){
        try {
            Contact conRec = getContactDetails(contactId);
            
            HttpResponse responseFromSendSMS= TwilioSendSMS.SendSMS(messageBody,String.valueOf(conRec.Phone));
            
            Message__c messageRec = new Message__c(
                Is_Outbound__c = true,
                Message_Content__c = messageBody,
                Recipient_Number__c = conRec.Phone,
                Sender_Number__c = Constants.SENDER_NUMBER,
                Contact__c = contactId);
            
            if(String.ValueOf(responseFromSendSMS.getStatusCode()) == '201'){
                messageRec.Is_Delivered__c = true;
            }else{
                messageRec.Is_Delivered__c = false;
                System.debug('Error Occured while delievery Message. Error Message----'+responseFromSendSMS.getBody());
            }
            insert as user messageRec;
            
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
        public MessagingWrapper(Contact contactRecord,List<Message__c> messages,Integer defaultOffSet){
            this.contactRecord = contactRecord;
            this.messages = messages;
            this.defaultOffSet = defaultOffSet;
        }
    }
}