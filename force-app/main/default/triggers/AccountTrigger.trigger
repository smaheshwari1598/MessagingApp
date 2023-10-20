trigger AccountTrigger on Account(after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
        System.debug('In Account Trigger');
            AccountTriggerHandler.createContact(Trigger.new);
        }
    }
}