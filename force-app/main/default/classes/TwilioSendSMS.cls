public class TwilioSendSMS {
    
    public static HTTPResponse sendSMS(String smsBody, String toNumber){
        
        String namedCredential = 'callout:TwilioConfig'; // Use the Named Credential's name
        String endPoint = namedCredential + '/'+Label.Twilio_Acount_Username+'/Messages.json';
        String senderNumber = Constants.SENDER_NUMBER;
        
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
        
        req.setBody('To=' + EncodingUtil.urlEncode(toNumber, 'UTF-8') + '&From=' + EncodingUtil.urlEncode(senderNumber,'UTF-8') + '&Body=' + smsBody);
        res = http.send(req);
        
        return res;
    }
}