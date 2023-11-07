/* Class Name : TwilioSendSMSBatch
   Author : Sweta
   Description : Batch class is used to send message to multiple numbers at the same time.
   Note : Batch size should not be more than 100.
*/

public class TwilioSendSMSBatch implements Database.Batchable<SObject>,Database.AllowsCallouts, Database.Stateful {
    public final List<String> recordIds;
    public final String phoneFieldName;
    public final String smsBody;
    
    public TwilioSendSMSBatch(List<String> recordIds, String phoneFieldName, String smsBody) {
        this.recordIds = recordIds;
        this.phoneFieldName = phoneFieldName;
        this.smsBody = smsBody;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String objectApiName = String.valueOf(Id.valueOf(recordIds[0]).getSObjectType());
        String query = 'SELECT Id, ' + phoneFieldName + ' FROM '+objectApiName +' WHERE Id IN :recordIds WITH SECURITY_ENFORCED';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try{
            List<Message__c> messageRecords = new List<Message__c>();
            for (SObject record : scope) {
                String phoneNumber = (String) record.get(phoneFieldName);
                HttpRequest request = new HttpRequest();
                String senderNumber = Constants.SENDER_NUMBER;
                String endPoint = 'callout:TwilioConfig/' + Label.Twilio_Acount_Username + '/Messages.json';
                String reqBody = 'To=' + EncodingUtil.urlEncode(phoneNumber, 'UTF-8') +
                                '&From=' + EncodingUtil.urlEncode(senderNumber, 'UTF-8') +
                                '&Body=' + EncodingUtil.urlEncode(smsBody, 'UTF-8');
        
                request.setBody(reqBody);
                request.setEndpoint(endPoint);
                request.setMethod('POST');
        
                request.setHeader('X-Twilio-Client', 'salesforce-3.2.0');
                request.setHeader('User-Agent', 'twilio-salesforce/3.2.0');
                request.setHeader('Accept', 'application/json');
                request.setHeader('Accept-Charset', 'utf-8');
                Message__c messageRec = createMessageRecord(smsBody, phoneNumber);
                HTTPResponse res;
                res = HTTPCalloutService.doCallout(request);
                if (String.valueOf(res.getStatusCode()) == '201') {
                    System.debug('SMS sent successfully to ' + phoneNumber);
                } else {
                    messageRec.Is_Delivered__c = false;
                    System.debug('Error Occurred while delivering Message to ' + phoneNumber + '. Error Message: ' + res.getBody());
                }
                messageRecords.add(messageRec);
            }
            if (!messageRecords.isEmpty()) {
                insert as User messageRecords;
            }
        }catch(Exception e){
            System.debug('An exception occurred while delievering Bulk Messages: ' + e.getMessage());
        }
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext bc) {
        //Perform Finish Operations here
    }

    /* Description : Used to create instance of Message__c based on SMS Body and To Number
       Paramas -> messageBody : Pass SMS Body 
               -> recipientNumber : Pass Receipient Number to whom message need to be sent.
     */
    public static Message__c createMessageRecord(String messageBody, String recipientNumber) {
        Message__c messageRec = new Message__c(
            Is_Outbound__c = true,
            Message_Content__c = messageBody,
            Recipient_Number__c = recipientNumber,
            Sender_Number__c = Constants.SENDER_NUMBER
        );
        return messageRec;
    }
}