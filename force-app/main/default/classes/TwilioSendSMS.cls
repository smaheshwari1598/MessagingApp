public class TwilioSendSMS {
     
    @future(callout = true)
    public static void sendSMS(String messageRecId,String smsBody, String toNumber,String mmsUrl){
        
        String namedCredential = 'callout:TwilioConfig'; // Use the Named Credential's name
        String endPoint = namedCredential + '/'+Label.Twilio_Acount_Username+'/Messages.json';
        String senderNumber = Constants.SENDER_NUMBER;
        String reqBody = '';
        
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        
        String version  = '3.2.0';
        req.setHeader('X-Twilio-Client', 'salesforce-' + version);
        req.setHeader('User-Agent', 'twilio-salesforce/' + version);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Accept-Charset', 'utf-8');
        
        reqBody = 'To=' + EncodingUtil.urlEncode(toNumber, 'UTF-8') + '&From=' + EncodingUtil.urlEncode(senderNumber,'UTF-8') + '&Body=' + EncodingUtil.urlEncode(smsBody,'UTF-8');
        
        if(String.isNotBlank(mmsUrl)){
            reqBody += '&MediaUrl='+ EncodingUtil.urlEncode(mmsUrl,'UTF-8');
        }
            
        req.setBody(reqBody);
        res = http.send(req);
        
        System.debug('mmsUrl---'+mmsUrl);
        System.debug('Request----'+req);
        System.debug('Request Body---'+req.getBody());
        System.debug('Response Body---'+res.getBody());
        
        Message__c messageRec = [SELECT ID,Is_Delivered__c FROM Message__c WHERE Id =: messageRecId];
        
        if(String.ValueOf(res.getStatusCode()) == '201'){
            messageRec.Is_Delivered__c = true;
        }else{
            messageRec.Is_Delivered__c = false;
            System.debug('Error Occured while delievery Message. Error Message----'+res.getBody());
        }
        update messageRec;
    }
}