public class TwilioSendSMS {   

    public static String SendSMS(String smsBody, String toNumber){
        String accountSid = 'AC59acae6e0cfbe113da97890649bf2e87'; 
        String token = '2f56ba5f2482d38f645f01f037700a8c'; 
        String endPoint = 'https://api.twilio.com/2010-04-01/Accounts/'+accountSid+'/Messages.json';
        Blob creds = Blob.valueOf(accountSid+':' +token);
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        String VERSION  = '3.2.0';
        req.setHeader('X-Twilio-Client', 'salesforce-' + VERSION);
        req.setHeader('User-Agent', 'twilio-salesforce/' + VERSION);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Accept-Charset', 'utf-8');
        req.setHeader('Authorization', 'Basic '+EncodingUtil.base64Encode(creds));
        req.setBody('To=' + EncodingUtil.urlEncode(toNumber, 'UTF-8') + '&From=' + EncodingUtil.urlEncode('+12565734669','UTF-8') + '&Body=' + smsBody);
        res = http.send(req);
        System.debug('------>----'+res.getBody());
        
       if(res.getStatusCode() == 201){

           return 'SMS Sent Successfully';
       } else{
           errorWrapper er = (errorWrapper)json.deserialize(res.getBody(), errorWrapper.class);
           throw newMessageException('Error : ' + er.message);
       }
    }
 
    public class errorWrapper{
       String code;
       String message;
       String moreInfo;
       String status; 
   }
 
    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}


