trigger ContactTrigger on Contact(before insert) {
    if (Trigger.isBefore) {
    System.debug('In Contact Trigger');
        if (Trigger.isInsert) {
            ContactTriggerHandler.createAccount(Trigger.new);
        }
    }
}