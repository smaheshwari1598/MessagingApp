/* Class Name : TwilioSendSMS
   Author : Sweta
   Description : This is a helper class for doing callout to Twilio.
*/

public class TwilioSendSMS {
     
    @future(callout = true)
    public static void sendSMS(String messageRecId, String toNumber, List<String> mmsUrls) {
        if(String.IsNotBlank(messageRecId)){
            Message__c messageRec = [SELECT ID, Is_Delivered__c,Message_Content__c FROM Message__c WHERE Id = :messageRecId WITH SECURITY_ENFORCED];
            
            HttpRequest request = new HttpRequest();
            String smsBody = (String.IsNotBlank(messageRec.Message_Content__c))?EncodingUtil.urlEncode(messageRec.Message_Content__c, 'UTF-8'):'';
            String senderNumber = Constants.SENDER_NUMBER;
            String endPoint = 'callout:TwilioConfig/' + Label.Twilio_Acount_Username + '/Messages.json';
            String reqBody = 'To=' + EncodingUtil.urlEncode(toNumber, 'UTF-8') +
                            '&From=' + EncodingUtil.urlEncode(senderNumber, 'UTF-8') +
                            '&Body=' + smsBody;
            
            if (!mmsUrls.isEmpty()) {
                for (String mmsUrl : mmsUrls) {
                    reqBody += '&MediaUrl=' + EncodingUtil.urlEncode(mmsUrl, 'UTF-8');
                }  
            }
            
            request.setBody(reqBody);
            request.setEndpoint(endPoint);
            request.setMethod('POST');
            
            request.setHeader('X-Twilio-Client', 'salesforce-3.2.0');
            request.setHeader('User-Agent', 'twilio-salesforce/3.2.0');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Accept-Charset', 'utf-8');
            
            HTTPResponse res;
            try {
                res = HTTPCalloutService.doCallout(request);
                if (String.valueOf(res.getStatusCode()) == '201'){
                    messageRec.Is_Delivered__c = true;
                }else{
                    messageRec.Is_Delivered__c = false;
                    System.debug('Error Occurred while delivering Message. Error Message: ' + res.getBody());
                }
                update as User messageRec;
            } catch (Exception e) {
                System.debug('Error Occurred : ' + e.getMessage());
            }
        }
    }
}