@RestResource(urlMapping='/TwilioReceiveSMS/*')
global class TwilioReceiveSMS {
    
    @HttpGet
    global static void getSMS() {
        RestRequest req = RestContext.request;       
        Map<String, String> sms = req.params; 

        String fromPhoneNumber;
        String smsBody;
        String toNumber;
        
		if (sms.containsKey('From')){
            fromPhoneNumber = sms.get('From') ;
        }
        if (sms.containsKey('Body')){
            smsBody = sms.get('Body') ;
        }   
        if (sms.containsKey('To')){
            toNumber = sms.get('To') ;
        }    
        
        if(String.isNotBlank(fromPhoneNumber)){
            Contact conRec = [SELECT Id FROM Contact WHERE Phone = :fromPhoneNumber LIMIT 1];
            if (conRec != null) {
                Message__c messageRec = new Message__c(
                Is_Outbound__c = false,
                Message_Content__c = smsBody,
                Recipient_Number__c = toNumber,
                Sender_Number__c = fromPhoneNumber,
                Contact__c = conRec.Id
            	);
                
                try {
                    insert messageRec;
                } catch (Exception e) {
                    System.debug('Error while saving SMS message: ' + e.getMessage());
                }
            } else {
                System.debug('No matching contact found for phone number: ' + fromPhoneNumber);
            }
        }
    }
}