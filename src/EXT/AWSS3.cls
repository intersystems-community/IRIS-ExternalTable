Class EXT.AWSS3 Extends EXT.LocalFile
{

ClassMethod GetAWSCredentials(profile = "default") As %Status
{
    set useInstanceMetadata=0
    set useCredentialsFile=0
    set useEnvVar=0
    if $system.Util.GetEnviron("AWS_ACCESS_KEY_ID")'="" {
        set useEnvVar=1
    } elseif ##class(%File).Exists($system.Util.GetEnviron("HOME")_"/.aws/credentials") {
        set useCredentialsFile=1
    } else {
        set useInstanceMetadata=1
    }

    if (useInstanceMetadata) {
        //curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/
        //S3-AdminAccess
        //curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/S3-AdminAccess
        set request = ##class(%Net.HttpRequest).%New()                         
        set request.Server = "169.254.169.254"       
        set sc = request.Get("/latest/meta-data/iam/security-credentials/")
        set role=request.HttpResponse.Data.ReadLine()
        set sc = request.Get("/latest/meta-data/iam/security-credentials/"_role)
        set json=request.HttpResponse.Data.Read(32000)
        set jsonobject={}.%FromJSON(json)
        set %extAWS("AccessKeyId")=jsonobject.AccessKeyId
        set %extAWS("SecretAccessKey")=jsonobject.SecretAccessKey
        if jsonobject.Token'="" {
            set %extAWS("Token")=jsonobject.Token
        }
        //TODO: deal with credentials expiration
        //"Expiration" : "2020-05-06T02:35:43Z"
    }
    if (useCredentialsFile) {
        set file=##class(%Stream.FileCharacter).%New()
        Set sc=file.LinkToFile($system.Util.GetEnviron("HOME")_"/.aws/credentials")
        //for now just take first/default keypair
        //TODO: parse file and extract "profile" key
        //TODO: adjust for Windows
        /*
            [default]
            aws_access_key_id = AKIAIAEXAMPLEKEY
            aws_secret_access_key = 1234567890aaaaabbbbccccc
        */
        set line=file.ReadLine()      
        set line=file.ReadLine()
        set keyId=$p(line," = ",2)
        set line=file.ReadLine()
        set keySecret=$p(line," = ",2)
        set line=file.ReadLine()
        set token=$p(line," = ",2)

        set %extAWS("AccessKeyId")=keyId
        set %extAWS("SecretAccessKey")=keySecret
        if token'="" { //set token variable only if token present
           set %extAWS("Token")=token
        }
    }
    if (useEnvVar) {
        //https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
        set %extAWS("AccessKeyId")=$system.Util.GetEnviron("AWS_ACCESS_KEY_ID")
        set %extAWS("SecretAccessKey")=$system.Util.GetEnviron("AWS_SECRET_ACCESS_KEY")
        set token=$system.Util.GetEnviron("AWS_SESSION_TOKEN")
        if token'="" { //set token variable only if token present
            set %extAWS("Token")=token
        }
    }
   quit $$$OK
}

ClassMethod AWSSignRequest(ByRef request, requeststring) As %String
{
    if '$data(%extAWS) {
	    set sc=..GetAWSCredentials()
	}
    set tAccessKeyId =%extAWS("AccessKeyId")
    set tSecretAccessKey = %extAWS("SecretAccessKey")
    set tDateH = $ZTS
    set tWeekDay = $P($ZDT(tDateH,11)," ",1)
    set tDate = tWeekDay_", "_$ZDT(tDateH,2,1)_" GMT"
    //w !,"Date: "_tDate
    set request.Date = tDate
    set tContentMD5 = ""
    set tContentType = ""
    set tToken=""
    if $d(%extAWS("Token")) {
        set tToken="x-amz-security-token:"_%extAWS("Token")_$c(10)
    }
    //set tStringToSign = "GET"_$C(10)_tContentMD5_$C(10)_tContentType_$C(10)_tDate_$C(10)_"/"_bucket_"/"_key
    set tStringToSign = $p(requeststring," ",1)_$C(10)_tContentMD5_$C(10)_tContentType_$C(10)_tDate_$C(10)_tToken_$p(requeststring," ",2)
    
    //w !,"StringToSign (before UTF-8 conversion): "_tStringToSign
    set tStringToSignUTF8 = $ZCONVERT(tStringToSign,"O","UTF8")
    //w !,"StringToSign (after UTF-8 conversion): "_tStringToSign
    set tSignature = ##class(%SYSTEM.Encryption).HMACSHA1(tStringToSignUTF8,tSecretAccessKey)
    //w !,"Signature (before Base64 encoding): "_tSignature
    set tSignatureBase64 = ##class(%SYSTEM.Encryption).Base64Encode(tSignature)
    //w !,"Signature (after Base64 encoding): "_tSignature
    set tAuthorization = "AWS "_tAccessKeyId_":"_tSignatureBase64
    //w !,"Authorization: "_tAuthorization
    set request.Authorization=tAuthorization
    if $d(%extAWS("Token")) {
        do request.SetHeader("X-Amz-Security-Token",%extAWS("Token"))
    }
    quit $$$OK
}

ClassMethod GetFileHeader(filename, classname = "") As %Status
{
    //s3://iris-external-table/file3.csv
    set bucket = $p(filename,"/",3) //"iris-external-table"
    set key=$p(filename,"/",4,*) // "file3.csv"
    set object="/"_bucket_"/"_key
    //add non - us-east1 region here
    set server = bucket_".s3.amazonaws.com"
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server       
    set request.Https=1                                 
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    //set request.ContentEncoding="x-gzip"
    set requeststring="GET "_"/"_bucket_"/"_key //_"?response-content-encoding=x-gzip&response-content-type=text/plain"
    set sc= ..AWSSignRequest(request,requeststring)

    set url =  "/"_key //_"?response-content-encoding=x-gzip&response-content-type=text/plain"
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice()
    set %extstream=request.HttpResponse.Data
    Set %extstream.LineTerminator=$char(10)
	quit $$$OK
}

ClassMethod GetFileList(location) As %Status
{
    kill %extFileList
    //s3://iris-external-table/
    if $Extract(location,$Length(location))'="/" {
        //if location does not end with '/' consider it the single file
        set %extFileList=1
        set %extFileList(1)=location
        quit $$$OK
    }
    set bucket = $p(location,"/",3) 
    set key=$p(location,"/",4,*) 
    set object="/"_bucket_"/"_key
    //add non - us-east1 region here
    set server = bucket_".s3.amazonaws.com"
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server       
    set request.Https=1                                 
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set requeststring="GET "_"/"_bucket_"/"_key
    set sc= ..AWSSignRequest(request,requeststring)

    set url =  "/"_key
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice()
    set stream=request.HttpResponse.Data
    set data=stream.Read(32000)
    //write data
    set numkeys=$l(data,"<Key>")
    for i=1:1:numkeys-1 {
        set file=$p($p(data,"<Key>",i+1),"</Key>")
        //write !,key
        set %extFileList($I(%extFileList))=location_file
    }
    quit $$$OK
}

}
