/* Class Name : TwilioReceiveSMS
   Author : Sweta
   Description : This is a class for receiving messages from Twilio.
*/
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
            Message__c messageRec = new Message__c(
                Is_Outbound__c = false,
                Message_Content__c = smsBody,
                Recipient_Number__c = toNumber,
                Sender_Number__c = fromPhoneNumber
            );
            
            try {
                insert as User messageRec;
            } catch (Exception e) {
                System.debug('Error while saving SMS message: ' + e.getMessage());
            }
        }
    }
}