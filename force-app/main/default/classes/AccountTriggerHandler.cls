public class AccountTriggerHandler {
    private static Boolean isExecuting = false;
    public static void createContact(List<Account> listOfAccounts){
        
        if(!isExecuting){
            isExecuting = true;
            List<Contact> listOfContacts = new List<Contact>();
            for(Account accRec : listOfAccounts){
                Contact conRec = new Contact();
                conRec.LastName = 'Test Contact';
                conRec.Department = 'Test';
                conRec.AccountId = accRec.Id;
                listOfContacts.add(conRec);
            }
            insert listOfContacts;
            isExecuting = false;
        }
    }
}