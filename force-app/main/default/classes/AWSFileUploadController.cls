public class AWSFileUploadController {

    @future(callout = true)
    public static void uploadFileToAWS(Id parentId, String strfileName, String fileType, String fileContent,Id versionid) {
        System.debug('strfileName----'+strfileName);
        System.debug('fileType----'+fileType);
        System.debug('fileContent----'+fileContent);
    
        List<ContentVersion> versions=[SELECT VersionData,Title,ContentDocumentId,FileExtension FROM ContentVersion WHERE Id = :versionid AND IsLatest = true];
        if (versions.size() > 0) {
            
            system.debug('file:'+ versions[0]);
            String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            String filename = versions[0].Title;
            
            //Update the content-type based on the file type being attached
            string contentType= 'image/jpeg';
            system.debug('contentType:'+contentType);
			String url = 'callout:Connect_to_S3';
            
            HttpRequest req  = new HttpRequest();
            HttpResponse res  = new HttpResponse();
            req.setMethod('PUT');
            req.setEndpoint('callout:Connect_to_s3' +'/'+ fileName);
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('Content-type', contentType);
            req.setHeader('Connection', 'keep-alive');
            req.setHeader('Date', formattedDateString);
            req.setHeader('ACL', 'public-read');
            req.setBodyAsBlob(Blob.valueOf(fileContent));
            
            Http http = new Http();
            res = http.send(req);
            system.debug('Status Body----'+res.getStatusCode());
            system.debug('Body----'+res.getBody());
            
        }
    }
    
    @future(callout = true)
    public static void putFileAmazonS3(String text){
        String fileName = 'readme.txt';
        String getResponse;
        try {
            HttpRequest request = new HttpRequest();
            request.setMethod('PUT');
             request.setBody(text); // for binary, use setBodyAsBlob(...)
             request.setEndpoint('callout:Connect_to_s3' +'/'+ fileName);
             Http http = new Http();
             HttpResponse res = http.send(request);
             System.debug('Response-----'+res.getBody());
             //return getResponse = res.getBody();

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}