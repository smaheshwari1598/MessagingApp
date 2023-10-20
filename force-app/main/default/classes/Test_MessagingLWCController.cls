@isTest
public class Test_MessagingLWCController {

    @isTest
    static void testGetMessages() {
        
        Contact testContact = new Contact();
        testContact.LastName = 'TestContact';
        testContact.Phone = '+919958501744';
        insert testContact;

        List<Message__c> testMessages = new List<Message__c>();
        for (Integer i = 0; i < 5; i++) {
            Message__c testMessage = new Message__c();
            testMessage.Contact__c = testContact.Id;
            testMessage.Recipient_Number__c = '+919958501744';
            testMessage.Sender_Number__c = '+12565734669';
            testMessages.add(testMessage);
        }
        
        Test.startTest();
        
        insert testMessages;
		MessagingLWCController.MessagingWrapper result = MessagingLWCController.getMessages(testContact.Id, '0');
        
        Test.stopTest();

        System.assertEquals(testContact.Id, result.contactRecord.Id);
        System.assertEquals(5, result.messages.size()); // Assuming 5 messages were inserted
    }

    @isTest
    static void testCreateMessage() {
        
        Contact testContact = new Contact();
        testContact.LastName = 'TestContact';
        testContact.Phone = '+919958501744';
        insert testContact;

        Test.startTest();

        MessagingLWCController.createMessage('Test message', testContact.Id);

        Test.stopTest();

        List<Message__c> messages = [SELECT Id FROM Message__c WHERE Contact__c = :testContact.Id];
        System.assertEquals(1, messages.size()); // Expecting one message record
    }
}