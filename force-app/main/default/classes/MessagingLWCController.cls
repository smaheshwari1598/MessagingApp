/* Class Name : MessagingLWCController
   Author : Sweta
   Description : This is a helper class for MessagingApp LWC which is used to send messages and media Messages.
*/
public class MessagingLWCController {
    
    /* Description : Used to get messages to display in Conversation View. 
    */
    @AuraEnabled(cacheable = true)
    public static MessagingWrapper getMessages(String recordId, String offSetValFromUI,String objectApiName){

        String phoneFieldName = getPhoneFieldName(objectApiName);
        
        MessagingWrapper msgWrapper;
        SObject recordDetail = getRecordDetails(recordId,objectApiName);
        Integer totalMessagesCount = calTotalMessages((String)recordDetail.get(phoneFieldName));
        Integer offSetVal=0;
        
        String strQueryForMessage = 'Select Id,Is_Outbound__c, Message_Content__c, CreatedBy.name, CreatedDate,Is_Delivered__c FROM Message__c WHERE Sender_Number__c= \'' + (String)recordDetail.get(phoneFieldName) + '\'';
        strQueryForMessage += ' OR Recipient_Number__c= \'' + (String)recordDetail.get(phoneFieldName) + '\'';
        
        if(totalMessagesCount > Integer.ValueOf(Label.MessagePerPage)){
            offSetVal = calOffSetValue(totalMessagesCount,offSetValFromUI);
        }
        strQueryForMessage += (totalMessagesCount > Integer.ValueOf(Label.MessagePerPage) && String.IsBlank(offSetValFromUI))?(' ORDER BY CreatedDate LIMIT '+ Label.MessagePerPage):'';
        
        strQueryForMessage += ' OFFSET '+ offSetVal;
        
        List<Message__c> listOfMessages = Database.query(strQueryForMessage,AccessLevel.USER_MODE);
        
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
        
        msgWrapper = new MessagingWrapper((String)recordDetail.get('Name'), listOfMessageDetailsWithAttachment,offSetVal);
        return msgWrapper;

    }
    
    /* Description : Used to get Phone field Name from Custom Metadata. 
    */
    public static String getPhoneFieldName(String objectApiName){
        Object_Name_with_Phone_Field__mdt messageCustomMetadataRecord = Object_Name_with_Phone_Field__mdt.getInstance(objectApiName);
        return messageCustomMetadataRecord.Phone_Field_API_Name__c;
    }

    /* Description : Used to get Record Details based on recrdId and ObjectAPIName. 
    */
    @AuraEnabled(cacheable = true)
    public static SObject getRecordDetails(String recordId,String objectApiName){
        String phoneFieldName = getPhoneFieldName(objectApiName);
        String query = 'SELECT Id,'+phoneFieldName+','+'Name' + ' FROM '+objectApiName +' WHERE Id='+'\'' +recordId+'\''+' LIMIT 1';
        return Database.query(query);
    }
    
    /* Description : Used to calculate number of messages related to that phone number. 
    */
    public static Integer calTotalMessages(String phoneNumber){
        return [SELECT Count() FROM Message__c WHERE Sender_Number__c=:phoneNumber OR Recipient_Number__c =:phoneNumber WITH USER_MODE];
    }
    
    /* Description : Helper method used to calculate Offset Value . 
    */
    public static Integer calOffSetValue(Integer totalMessagesCount, String offSetValFromUI){
        Integer offSetVal=0;
         
        if(String.IsNotBlank(offSetValFromUI)){
            return ((Integer.valueOf(offSetValFromUI) >= 0)?Integer.Valueof(offSetValFromUI):0);
        }else{
            return (totalMessagesCount - Integer.ValueOf(Label.MessagePerPage));
        }
    }
    
    /* Description : Used to create Message__c and attachments . 
    */
    @AuraEnabled
    public static String createMessage(String messageBody,String recordId, List<FileContent> fileContents ,String objectApiName){
        try {
            String phoneFieldName = getPhoneFieldName(objectApiName);
            List<String> listOfMMSurls = new List<String>();
            SObject recordDetail = getRecordDetails(recordId,objectApiName);
            String messageRecId = createMessageRecord(messageBody,recordId,(String)recordDetail.get(phoneFieldName));
            if(!fileContents.isEmpty()){
                insertAttachments(messageRecId,fileContents);
            }
            return messageRecId;
        }catch (Exception e) {
            System.debug('Error while saving SMS message: ' + e.getMessage());
        } 
        return null;
    }
    
    /* Description : Used to do callout to s3 . 
    */
    @AuraEnabled
    public static void calloutToS3(String recordId, List<FileContent> fileContents ,String objectApiName,String messageRecId){
        try {
            String phoneFieldName = getPhoneFieldName(objectApiName);
            List<String> listOfMMSurls = new List<String>();
            SObject recordDetail = getRecordDetails(recordId,objectApiName);
            if(!fileContents.isEmpty()){
                for(FileContent fileContentRec : fileContents){
                    
					HttpRequest request = new HttpRequest();
                    String endPointUrl = 'callout:Connect_to_s3' +'/'+ EncodingUtil.urlEncode(fileContentRec.fileName, 'UTF-8');
                    String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');

                    request.setHeader('Content-Encoding', 'UTF-8');
                    request.setHeader('Content-type', fileContentRec.filetype);
                    request.setHeader('Connection', 'keep-alive');
                    request.setHeader('Date', formattedDateString);
                    request.setHeader('ACL', 'public-read');
					request.setBodyAsBlob(EncodingUtil.base64Decode(fileContentRec.fileData));
                    request.setEndpoint(endPointUrl);
                    request.setMethod('PUT');
                    
                    HTTPResponse resFromS3 = HTTPCalloutService.doCallout(request);
                    
                    if(resFromS3.getStatusCode() == 200){
                        listOfMMSurls.add('https://mypublicfilesbucketforsalesforce.s3.eu-north-1.amazonaws.com' + '/'+ fileContentRec.filename);
                    }
                }
            }
            if(String.IsNotBlank(messageRecId)){
				TwilioSendSMS.SendSMS(messageRecId,(String)recordDetail.get(phoneFieldName),listOfMMSurls);                
            }
        }catch (Exception e) {
            System.debug('Error doing Callout: ' + e.getMessage());
        } 
    }
    
    /* Description : Used to insert Attachments . 
    */
    public static void insertAttachments(Id parentRecordId,List<FileContent> fileContents){
        List<ContentVersion> listOfContentVersions = new List<Contentversion>();
        for(FileContent file : fileContents){
            ContentVersion cVersion = new ContentVersion();
            cVersion.PathOnClient = file.fileName;//File name with extention
            cVersion.FirstPublishLocationId = parentRecordId;  
            cVersion.Title = file.fileName;//Name of the file
            cVersion.VersionData = EncodingUtil.base64Decode(file.fileData);//File content
            listOfContentVersions.add(cVersion);
        }
        if(!listOfContentVersions.isEmpty())
        insert as User listOfContentVersions; 
    }
    
    /* Description : Used to create Message__c record instance . 
    */
    public static String createMessageRecord(String messageBody,String recordId,String recipientNumber){
        Message__c messageRec = new Message__c(
            Is_Outbound__c = true,
            Message_Content__c = messageBody,
            Recipient_Number__c = recipientNumber,
            Sender_Number__c = Constants.SENDER_NUMBER
            );
        insert as user messageRec;
        return messageRec.Id;
    }
    
   public class FileContent{
        @AuraEnabled
        public String fileName{get;set;}
        @AuraEnabled
        public String fileData{get;set;}
        @AuraEnabled
        public String fileType{get;set;}
   }

    public class MessagingWrapper{
        @AuraEnabled
        public String contactPersonName{get;set;}
        @AuraEnabled
        public List<MessageDetailsWithAttachment> messageWithAttachments{get;set;}
        @AuraEnabled
        public Integer defaultOffSet{get;set;}
        public MessagingWrapper(String contactPersonName,List<MessageDetailsWithAttachment> messageWithAttachments,Integer defaultOffSet){
            this.contactPersonName = contactPersonName;
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