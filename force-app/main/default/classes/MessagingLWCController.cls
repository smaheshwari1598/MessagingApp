public class MessagingLWCController {
    
    @AuraEnabled(cacheable = true)
    public static MessagingWrapper getMessages(String contactId, String offSetValFromUI){
        	MessagingWrapper msgWrapper;
        	Integer totalMessagesCount = [SELECT Count() FROM Message__c WHERE Contact__c = :contactId WITH USER_MODE];
        	Integer offSetVal=0;
        	
        	String strQuery = 'Select Id,Is_Outbound__c, Message_Content__c, CreatedBy.name, CreatedDate,Is_Delivered__c,Contact__r.Name FROM Message__c WHERE Contact__c = \'' + contactId + '\'';
            
        	if(totalMessagesCount > Integer.ValueOf(Label.MessagePerPage)){
                offSetVal = calOffSetValue(totalMessagesCount,offSetValFromUI);
            }
            strQuery += (totalMessagesCount > Integer.ValueOf(Label.MessagePerPage) && String.IsBlank(offSetValFromUI))?(' ORDER BY CreatedDate LIMIT '+ Label.MessagePerPage):'';
        
            Contact conRec = getContactDetails(contactId);
        	strQuery += ' OFFSET '+ offSetVal;
        
        	List<Message__c> listOfMessages = Database.query(strQuery,AccessLevel.USER_MODE);
        	msgWrapper = new MessagingWrapper(conRec, listOfMessages,offSetVal);
            return msgWrapper;
    }
    
    public static Integer calOffSetValue(Integer totalMessagesCount, String offSetValFromUI){
        Integer offSetVal=0;
         
        if(String.IsNotBlank(offSetValFromUI)){
            return ((Integer.valueOf(offSetValFromUI) >= 0)?Integer.Valueof(offSetValFromUI):0);
        }else{
            return (totalMessagesCount - Integer.ValueOf(Label.MessagePerPage));
        }
    }
    
    @AuraEnabled
    public static void createMessage(String messageBody,String contactId, String fileName, String fileData, String fileType){
        try {
            
            String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            String mmsSharedUrl = '';
            String endPointUrl = 'callout:Connect_to_s3' +'/'+ fileName;
            String contentType= 'image/jpeg';
            String url = 'callout:Connect_to_S3';
            
            HttpRequest req  = new HttpRequest();
            HttpResponse resFromS3  = new HttpResponse();
            
            req.setMethod('PUT');
            req.setEndpoint(endPointUrl);
            req.setHeader('Access-Control-Allow-Origin', '*');
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('Content-type', contentType);
            req.setHeader('Connection', 'keep-alive');
            req.setHeader('Date', formattedDateString);
            req.setHeader('ACL', 'READ_ACP');
            
            req.setBodyAsBlob(Blob.valueOf(fileData));
            
            Http http = new Http();
            resFromS3 = http.send(req);
            
            System.debug('*Resp:' + String.ValueOF(resFromS3.getBody()));
            System.debug('RESPONSE STRING: ' + resFromS3.toString());
            System.debug('RESPONSE STATUS: ' + resFromS3.getStatus());
            System.debug('STATUS_CODE: ' + resFromS3.getStatusCode());
            
            Contact contactDetails = getContactDetails(contactId);
            
            if(resFromS3.getStatusCode() == 200){
                String mmsUrl = 'https://mypublicfilesbucketforsalesforce.s3.eu-north-1.amazonaws.com' + '/'+ filename;
               	Id messageRecId = createMessageRecord(messageBody,contactId);
                if(String.isNotBlank(fileName) && String.isNotBlank(fileData)){
                    insertAttachments(fileName,contactId,fileData);
                }
                TwilioSendSMS.SendSMS(messageRecId,messageBody,contactDetails.Phone,mmsUrl);
            }
            
        } catch (Exception e) {
            System.debug('Error while saving SMS message: ' + e.getMessage());
        }        
    }
    
    public static void insertAttachments(String fileName, String contactId,String fileData){
        ContentVersion cVersion = new ContentVersion();
        cVersion.PathOnClient = fileName;//File name with extention
        cVersion.FirstPublishLocationId = contactId;  
        cVersion.Title = fileName;//Name of the file
        cVersion.VersionData = EncodingUtil.base64Decode(fileData);//File content
        Insert cVersion;
        
        //After saved the Content Verison, get the ContentDocumentId
        ContentVersion conDocument = [SELECT Id,ContentDocumentId, title FROM ContentVersion WHERE Id =:cVersion.Id];
        
        ContentDocument contentDocument = [SELECT FileType FROM ContentDocument WHERE Id = :conDocument.ContentDocumentId LIMIT 1];
        
    }
    
    public static String createMessageRecord(String messageBody,String contactId){
        Contact conRec = getContactDetails(contactId);
        Message__c messageRec = new Message__c(
            Is_Outbound__c = true,
            Message_Content__c = messageBody,
            Recipient_Number__c = conRec.Phone,
            Sender_Number__c = Constants.SENDER_NUMBER,
            Contact__c = contactId);
        insert as user messageRec;
        return messageRec.Id;
    }
    
    public static Contact getContactDetails(String contactId){
        return [SELECT Id, Phone, Name from Contact where Id =:contactId LIMIT 1];
    }

    public class MessagingWrapper{
        @AuraEnabled
        public Contact contactRecord{get;set;}
        @AuraEnabled
        public List<Message__c> messages{get;set;}
        @AuraEnabled
        public Integer defaultOffSet{get;set;}
        public MessagingWrapper(Contact contactRecord,List<Message__c> messages,Integer defaultOffSet){
            this.contactRecord = contactRecord;
            this.messages = messages;
            this.defaultOffSet = defaultOffSet;
        }
    }
    
    
}