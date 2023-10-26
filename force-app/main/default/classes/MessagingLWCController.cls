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
        
        List<Id> listOfMessageIds = new List<Id>();
        for(Message__c messageRec : listOfMessages){
            listOfMessageIds.add(messageRec.Id);
        }
        
        Map<Id,List<ContentVersion>> mapOfMessageIdWithContentVersions = new Map<Id,List<ContentVersion>>();
        for(ContentVersion conVerData :[SELECT ID,VersionData, FirstPublishLocationId,ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId IN : listOfMessageIds]){
            if(mapOfMessageIdWithContentVersions.containskey(conVerData.FirstPublishLocationId)){
                mapOfMessageIdWithContentVersions.get(conVerData.FirstPublishLocationId).add(conVerData);
            }else{
                mapOfMessageIdWithContentVersions.put(conVerData.FirstPublishLocationId, new List<ContentVersion> { conVerData });
            }   
        }
        
        List<MessageDetailsWithAttachment> listOfMessageDetailsWithAttachment= new List<MessageDetailsWithAttachment>();
        for(Message__c messageRec : listOfMessages){
            List<String> listOfAttachmentLinks = new List<String>();
            List<ContentVersion> listOfAttachment = new List<ContentVersion>();
            if(mapOfMessageIdWithContentVersions.containsKey(messageRec.Id)){
                listOfAttachment = mapOfMessageIdWithContentVersions.get(messageRec.Id);
            }
                
            if(!listOfAttachment.isEmpty()){
                for(ContentVersion conVer : listOfAttachment){
                    listOfAttachmentLinks.add('data:image/'+'jpeg'+';charset=utf-8;base64, '+EncodingUtil.base64Encode(conVer.VersionData));
                }
            }
            
            MessageDetailsWithAttachment messagedetail = new MessageDetailsWithAttachment(messageRec,listOfAttachmentLinks);
            listOfMessageDetailsWithAttachment.add(messagedetail);
        }
        
        msgWrapper = new MessagingWrapper(conRec, listOfMessageDetailsWithAttachment,offSetVal);
        System.debug('msgWrapper-----'+msgWrapper);
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
    public static void createMessage(String messageBody,String contactId, String fileName, String fileData,String filetype){
        try {
            String mmsUrl='';
            String messageRecId = '';
            Contact contactDetails = getContactDetails(contactId);
            System.debug('filetype----'+filetype);
            
            if(String.IsNotBlank(fileData) && fileData != ''){
                String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
                String mmsSharedUrl = '';
                String endPointUrl = 'callout:Connect_to_s3' +'/'+ EncodingUtil.urlEncode(fileName, 'UTF-8');
                HttpRequest req  = new HttpRequest();
                HttpResponse resFromS3  = new HttpResponse();
                
                req.setMethod('PUT');
                req.setEndpoint(endPointUrl);
                req.setHeader('Content-Encoding', 'UTF-8');
                req.setHeader('Content-type', filetype);
                req.setHeader('Connection', 'keep-alive');
                req.setHeader('Date', formattedDateString);
                req.setHeader('ACL', 'public-read');
                
                req.setBodyAsBlob(EncodingUtil.base64Decode(fileData));
                
                Http http = new Http();
                resFromS3 = http.send(req);
                
                System.debug('FILE CONTENT:' +  fileData);
                System.debug('FILE NAME: ' + fileName);
                System.debug('*Resp:' + String.ValueOF(resFromS3.getBody()));
                System.debug('RESPONSE STRING: ' + resFromS3.toString());
                System.debug('RESPONSE STATUS: ' + resFromS3.getStatus());
                System.debug('STATUS_CODE: ' + resFromS3.getStatusCode());
                
                if(resFromS3.getStatusCode() == 200){
                    mmsUrl = 'https://mypublicfilesbucketforsalesforce.s3.eu-north-1.amazonaws.com' + '/'+ filename;
                    messageRecId = createMessageRecord(messageBody,contactId);
                    insertAttachments(messageRecId,fileName,contactId,fileData);
                }
            }else{
                messageRecId = createMessageRecord(messageBody,contactId);
            }
            TwilioSendSMS.SendSMS(messageRecId,messageBody,contactDetails.Phone,mmsUrl);
        } catch (Exception e) {
            System.debug('Error while saving SMS message: ' + e.getMessage());
        }        
    }
    
    public static void insertAttachments(Id parentRecordId,String fileName, String contactId,String fileData){
        ContentVersion cVersion = new ContentVersion();
        cVersion.PathOnClient = fileName;//File name with extention
        cVersion.FirstPublishLocationId = parentRecordId;  
        cVersion.Title = fileName;//Name of the file
        cVersion.VersionData = EncodingUtil.base64Decode(fileData);//File content
        insert cVersion;
        
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
        public List<MessageDetailsWithAttachment> messageWithAttachments{get;set;}
        @AuraEnabled
        public Integer defaultOffSet{get;set;}
        public MessagingWrapper(Contact contactRecord,List<MessageDetailsWithAttachment> messageWithAttachments,Integer defaultOffSet){
            this.contactRecord = contactRecord;
            this.messageWithAttachments = messageWithAttachments;
            this.defaultOffSet = defaultOffSet;
        }
    }
    
    public class MessageDetailsWithAttachment{
        @AuraEnabled
        public Message__c messageRec{get;set;}
        @AuraEnabled
        public List<String> attachmentLinks{get; set;}
        public MessageDetailsWithAttachment(Message__c messageRec,List<String> attachmentLinks){
            this.messageRec = messageRec;
            this.attachmentLinks = attachmentLinks;
        }
    }
}