public with sharing class BoxPreviewController {
    public static final String APPLICATION_ENCODED_HEADER = 'application/x-www-form-urlencoded';
    public static final String AUTHORIZATION_HEADER = 'Authorization';
    public static final String CONTENT_TYPE_HEADER = 'Content-Type';
    public static final String POST_METHOD = 'POST';
    public static final String TOKEN_URL_STRING = 'https://api.box.com/oauth2/token';

    

    public string ltnOrigin {get{ return URL.getOrgDomainUrl().toExternalForm().split('\\.')[0] + '.lightning.force.com';} set;}

    @AuraEnabled(cacheable = true)
    public static string getVFOrigin() {
        string vfOrigin = '';
        string baseURL = URL.getOrgDomainUrl().toExternalForm(); // Expected Format = https://domain.my.salesforce.com

        // Expected Format for DE, Sandbox & Production ORgs = https://domain--c.visualforce.com
        vfOrigin = baseURL.split('.my.')[0] + '--c.' + 'visualforce.com';

        /* ********* Below odd Discrepancy was found while implementing this in a Trailhead Playground ***********
        Organization oOrg = [SELECT InstanceName, IsSandbox, OrganizationType FROM Organization LIMIT 1];
        if(oOrg.OrganizationType == 'Developer Edition'){
        // Expected Format for Trailhead Playground DE Org = https://domain--c.ap4.visual.force.com
        vfOrigin = baseURL.split('.my.')[0]+'--c.'+oOrg.InstanceName.toLowercase()+'.visual.force.com';
        } else {
        // Expected Format for personal DE, Sandbox & Production Orgs = https://domain--c.visualforce.com
        vfOrigin = baseURL.split('.my.')[0]+'--c.'+'visualforce.com';
        }  */

        return vfOrigin;
    }


    @AuraEnabled()
    public static Map<String, String> downscopeToken(String fileId, String scopes) {

        System.debug('Found fileId: ' + fileId);
        System.debug('Found scopes: ' + scopes);
        String ltnOrigin = URL.getOrgDomainUrl().toExternalForm().split('\\.')[0] + '.lightning.force.com';

        System.debug('Ltn origin: ' + ltnOrigin);


        // Get parent access token from Client Credentials Grant Auth
        BoxClient boxClient = new BoxClient();
        boxClient.authenticate(null);

        // Create map for downscoped token request
        String resource = 'https://api.box.com/2.0/files/' + fileId;
        Map<String, String> downscopeTokenMap = new Map<String, String>();
        String urlParameters = String.format(
        'grant_type={0}&subject_token={1}&subject_token_type={2}&scope={3}&resource={4}',
        new List<String>{
            'urn:ietf:params:oauth:grant-type:token-exchange',
            boxClient.getAccessToken(),
            'urn:ietf:params:oauth:token-type:access_token',
            scopes,
            resource
        });

        Map<String, String> headers = new Map<String, String>();
        headers.put(CONTENT_TYPE_HEADER, APPLICATION_ENCODED_HEADER);

        // Get downsceoped token
        HttpResponse response = boxClient.sendRequest(POST_METHOD, TOKEN_URL_STRING, headers, urlParameters);
        System.debug('Found response: ' + response.getBody());
        System.debug('Found status: ' + response.getStatus());
       
        String accessToken;
        if(response.getStatus() == 'OK') {
            String body = response.getBody();
            AuthenticationResponse authResponse = AuthenticationResponse.parse(body);
            accessToken = authResponse.access_token;
        }

    
        // Set folderId and downscoped token to pass back to LWC javascript controller
        Map<String, String> buieMap = new Map<String, String>();
        buieMap.put('fileId', fileId);
        buieMap.put('accessToken', accessToken);
        buieMap.put('ltnOrigin', ltnOrigin);

        return buieMap;
    }
}