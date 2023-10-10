public class MessageTriggerHandler implements TriggerHandler {
	public void beforeInsert(List<Message__c> newMessages) {
       
    }
    public void beforeUpdate(List<Message__c> oldMessages, List<Message__c> newMessages, Map<ID, SObject> oldMessagesMap, Map<ID, SObject> newMessagesMap) {
       
    }
    public void beforeDelete(List<Message__c> oldMessages, Map<ID, SObject> oldMessagesMap) {
 
    }
    public void afterInsert(List<Message__c> newMessages, Map<ID, SObject> newMessagesMap) {
 		MessageTriggerHelper.afterInsertOperations(newMessages,newMessagesMap);
    }
    public void afterUpdate(List<Message__c> oldMessages, List<Message__c> newMessages, Map<ID, SObject> oldMessagesMap, Map<ID, SObject> newMessagesMap) {
        
    }
    public void afterDelete(List<Message__c> oldMessages, Map<ID, SObject> oldMessagesMap) {
        
    }
    public void afterUndelete(List<Message__c> newMessages, Map<ID, SObject> newMessagesMap) {
        
    }
}