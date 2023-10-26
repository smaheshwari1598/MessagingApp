public class ContactTriggerHandler {
    private static Boolean isExecuting = false;
	public static void createAccount(List<Contact> listOfContacts){
        if(!isExecuting){
            isExecuting = true;
            Set<Id> setOfAccountIds = new Set<Id>();
            for(Contact conRec : listOfContacts){
                setOfAccountIds.add(conRec.AccountId);
            }
            
            Map<Id,Account> mapOfAccount = new Map<Id,Account>([SELECT Id,Name FROM ACCOUNT WHERE ID IN : setOfAccountIds]);
            
            for(Contact conRec : listOfContacts){
                conRec.LastName = conRec.LastName + mapOfAccount.get(conRec.AccountId).Name;
                
            }
        }
    }
}