/* Class Name : HTTPCalloutService
   Author : Sweta
   Description : This is a helper class for callouts.
*/
public class HTTPCalloutService {
    public static HttpResponse doCallout(HttpRequest request){
        Http http = new Http();
        HTTPResponse response = new HTTPResponse();
        response = http.send(request);
        return response;
    }
}