Class DL.Azure Extends DL.LocalFile
{

ClassMethod GetFileList(location) As %Status
{
    //  https://mystorageaccount.blob.core.windows.net/container/
    kill %etFileList
    set server=$p(location,"/",3)
    set key=$p(location,"/",4,*)
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server
    set request.Https=1                                     
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set request.Authorization = ..GetAccessToken()
    do request.SetHeader("x-ms-version","2017-11-09")
    //set request.Port = tPort
    set url =  "/"_key_"?restype=container&comp=list"
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice
    set data=request.HttpResponse.Data.Read(32000)
    
    set numkeys=$l(data,"<Name>")
    for i=1:1:numkeys-1 {
        set file=$p($p(data,"<Name>",i+1),"</Name>")
        //write !,key
        set %etFileList($I(%etFileList))=location_file
    }    quit $$$OK
}

ClassMethod GetAccessToken() As %String
{
    //curl -X POST -d 'grant_type=client_credentials&client_id=[APP_ID]&client_secret=[PASSWORD]&resource=https%3A%2F%2Fmanagement.azure.com%2F' \
    //https://login.microsoftonline.com/[TENANT_ID]/oauth2/token

    //on the Azure instance you can use metadata. "Identity" should be enabled
    //curl -H Metadata:true 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/'


    if '$data(%etAzureAuthToken) {
        
        set server="login.microsoftonline.com" 
        set clientId=$get(^ET.Config("azure-client-id"),"")
        set clientSecret=$get(^ET.Config("azure-client-secret"),"")
        set tenantId=$get(^ET.Config("azure-tenant-id"),"")

        set request = ##class(%Net.HttpRequest).%New()                         
        set request.Server = server
        set request.Https=1                                     
        set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
        do request.InsertFormData("grant_type","client_credentials")
        do request.InsertFormData("client_id",clientId)
        do request.InsertFormData("client_secret",clientSecret)
        do request.InsertFormData("resource","https://storage.azure.com/")
        set url =  "/"_tenantId_"/oauth2/token"
        //do request.OutputHeaders()
        set sc = request.Post(url)
        //do request.HttpResponse.OutputHeaders()
        //do request.HttpResponse.OutputToDevice
        set json=request.HttpResponse.Data.Read(32000)
        set %etAzureAuthToken={}.%FromJSON(json)."access_token"
    }
    quit " Bearer "_%etAzureAuthToken
}

ClassMethod GetFileHeader(filename, classname = "") As %Status
{
    //  https://mystorageaccount.blob.core.windows.net/container/myfile.txt
    set server=$p(filename,"/",3)
    set key=$p(filename,"/",4,*)
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server
    set request.Https=1                                     
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set request.Authorization = ..GetAccessToken()
    do request.SetHeader("x-ms-version","2017-11-09")
    //set request.Port = tPort
    set url =  "/"_key
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice
    set %dlstream=request.HttpResponse.Data
    Set %dlstream.LineTerminator=$char(10)
	quit $$$OK
}

}
