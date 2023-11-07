public class MessageTriggerHelper {
    public MessageTriggerHelper() {
        
    }
    
    public static void afterInsertOperations(List<Message__c> newMessages, Map<ID, SObject> newMessagesMap){
        List<NewMessage__e> newMessageEvents = new List<NewMessage__e>();

        for (Message__c message : newMessages) {
             NewMessage__e newMessageEvent = new NewMessage__e(
                Sender__c = message.Sender_Number__c,
                Recipient__c = message.Recipient_Number__c
            );
    
            newMessageEvents.add(newMessageEvent);
        }
        
        try {
            EventBus.publish(newMessageEvents);
        } catch (Exception e) {
            System.debug('Error publishing platform events: ' + e.getMessage());
        }
    }   
}