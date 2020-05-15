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
    //DO NOT use this method for AWS. It's only for compatibility with AWS Signature method V2.
    //All AWS reginos now accept AWS4-HMAC-SHA256 implemented in AWSSignRequestV4()
    //Some older "S3 - compatible" services might require V2, so left here only for compatibility
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

ClassMethod hex(str As %String)
{
	set hexstring = ""
	for i=1:1:$L(str) 
	{
		set hexcode = $zh($a($e(str,i))) 
		set:($l(hexcode)=1) hexcode = "0"_hexcode
	 	set hexstring = hexstring _ hexcode
	}
	quit $ZCVT(hexstring,"L")
}

ClassMethod AWSSignRequestV4(ByRef request, requeststring) As %String
{
    //Reference:
    //https://docs.aws.amazon.com/general/latest/gr/sigv4-signed-request-examples.html
    //https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
    //https://czak.pl/2015/09/15/s3-rest-api-with-curl.html
    //https://github.com/mhart/aws4/blob/master/aws4.js - a lot of "SPECIAL CASES" for S3

    #define HMACSHA256(%key,%msg) $system.Encryption.HMACSHA(256, $ZCONVERT(%msg,"O","UTF8"), %key)
    #define HEX(%str) ..hex(%str)
    #define HASHSHA256(%msg) $system.Encryption.SHAHash(256, $ZCONVERT(%msg,"O","UTF8"))
    if '$data(%extAWS) {
	    set sc=..GetAWSCredentials()
	}
    set awsAccessKeyId =%extAWS("AccessKeyId")
    set awsSecretAccessKey = %extAWS("SecretAccessKey")
    
    set requestDate=$p($ZDT($H, 8,7),"T",1)
    set requestDateTime=$replace($ZDT($H, 8,7),":","")
    do request.SetHeader("X-Amz-Date",requestDateTime)
    set awsContentHash=$$$HEX($$$HASHSHA256(""))
    do request.SetHeader("X-Amz-Content-SHA256",awsContentHash)
    set awsQueryString=$P(requeststring,"?",2) //delimiter=/&list-type=2&prefix=
    //set awsQueryString=##class(%CSP.Page).EscapeHTML(awsQueryString)
    set awsQueryString=$replace(awsQueryString,"/","%2F")
    set awsCanonicalRequest=""_
        $P(requeststring," ",1)_$c(10)_ // GET
        $P($P(requeststring," ",2),"?",1)_$c(10)_ // /
        awsQueryString_$c(10)_ // 
        "host:"_request.Server_$c(10)_ // host:iris-external-table.s3.amazonaws.com
        "x-amz-content-sha256:"_awsContentHash_$c(10)_
        "x-amz-date:"_requestDateTime_$c(10)_
        $c(10)_
        "host;x-amz-content-sha256;x-amz-date"_$c(10)_
        ""_awsContentHash

    set bucket = $p(request.Server,".",1)
    //set ^EXT.S3BucketRegion("covid19-lake")="us-east-2"
    set awsRegion=$get(^EXT.S3BucketRegion(bucket),"us-east-1")
    set awsService="s3"


    set awsDateKey=$$$HMACSHA256("AWS4"_awsSecretAccessKey,requestDate)
    set awsDateRegionKey=$$$HMACSHA256(awsDateKey,awsRegion)
    set awsDateRegionServiceKey=$$$HMACSHA256(awsDateRegionKey,awsService)
    set awsSigningKey=$$$HMACSHA256(awsDateRegionServiceKey,"aws4_request")
    
    set awsCredentialScope=requestDate_"/"_awsRegion_"/"_awsService_"/aws4_request"
    set awsCanonicalRequestHash=$$$HEX($$$HASHSHA256(awsCanonicalRequest))
    set awsStringToSign="AWS4-HMAC-SHA256"_$c(10)_requestDateTime_$c(10)_awsCredentialScope_$c(10)_awsCanonicalRequestHash
   
    //The 256-bit signature expressed as 64 lowercase hexadecimal characters. For example:
    set signature=$$$HEX($$$HMACSHA256(awsSigningKey,awsStringToSign))
    //Set pRequest.AuthorizationHeader= ..#SignatureMethodName_" Credential=" _ pRequest.AccessKey.AccessKey _ "/" _ credentialScope _ ", " _ "SignedHeaders=" _ signedHeaders _ ", " _ "Signature=" _ signatureHex
    set authorization="AWS4-HMAC-SHA256 "_ 
    //"Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request, "_ 
    "Credential="_awsAccessKeyId_"/"_requestDate_"/"_awsRegion_"/"_awsService_"/aws4_request, "_ 
    //"SignedHeaders=host;x-amz-content-sha256;x-amz-date, "_ 
    "SignedHeaders=host;x-amz-content-sha256;x-amz-date, "_ 
    //"Signature=fe5f80f77d5fa3beca038a248ff027d0445342fe2855ddc963176630326f1024"
    "Signature="_signature
    set request.Authorization=authorization
    quit $$$OK
}

ClassMethod GetFileHeader(filename, classname = "") As %Status
{
    //s3://iris-external-table/file3.csv
    set bucket = $p(filename,"/",3) //"iris-external-table"
    set key=$p(filename,"/",4,*) // "file3.csv"
    set object="/"_bucket_"/"_key
    //add non - us-east1 region here
    set awsRegion=$get(^EXT.S3BucketRegion(bucket),"us-east-1")
    if awsRegion="us-east-1" { 
        set server = bucket_".s3.amazonaws.com"
    } else {
        set server = bucket_".s3."_awsRegion_".amazonaws.com"
    }
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server       
    set request.Https=1                                 
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    //set request.ContentEncoding="x-gzip"
    set url =  "/"_key 
    set requeststring="GET "_"/"_key
    set sc= ..AWSSignRequestV4(request,requeststring)

    //do request.OutputHeaders()
    set sc = request.Get(url)
    if request.HttpResponse.StatusCode'=200 {
        write !,request.HttpResponse.StatusCode," ",request.HttpResponse.StatusLine
        //do request.HttpResponse.OutputHeaders()
        //do request.HttpResponse.OutputToDevice()
    }
    set %extstream=request.HttpResponse.Data
    Set %extstream.LineTerminator=$char(10)
	quit $$$OK
}

ClassMethod GetFileList(location) As %Status
{
    kill %extFileList
    //s3://iris-external-table/
    /*if $Extract(location,$Length(location))'="/" {
        //if location does not end with '/' consider it the single file
        set %extFileList=1
        set %extFileList(1)=location
        quit $$$OK
    }*/
    set bucket = $p(location,"/",3) 
    set key=$p(location,"/",4,*) 
    set object="/"_bucket_"/"_key
    //add non - us-east1 region here
    set awsRegion=$get(^EXT.S3BucketRegion(bucket),"us-east-1")
    if awsRegion="us-east-1" { 
        set server = bucket_".s3.amazonaws.com"
    } else {
        set server = bucket_".s3."_awsRegion_".amazonaws.com"
    }
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server       
    set request.Https=1                                 
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set url =  "/?delimiter=/&list-type=2&prefix="_key
    set requeststring="GET "_url
    set sc= ..AWSSignRequestV4(request,requeststring)
    //do request.OutputHeaders()
    set sc = request.Get(url)
    if request.HttpResponse.StatusCode'=200 {
        //write !,request.HttpResponse.StatusCode," ",request.HttpResponse.StatusLine
        //do request.HttpResponse.OutputHeaders()
        //X-AMZ-BUCKET-REGION: us-east-2
        set region=request.HttpResponse.GetHeader("X-AMZ-BUCKET-REGION")
        if (region'="") && (region'="us-east-1") && (region'=$get(^EXT.S3BucketRegion(bucket))) {
            //write !, "Setting bucket header permanently to ", region,!
            set ^EXT.S3BucketRegion(bucket)=region
            quit $$$ERROR("WRONG REGION")
            //set sc= ..AWSSignRequestV4(request,requeststring)
        }
        //s %headers=request.HttpResponse.Headers
        //do request.HttpResponse.OutputToDevice()
    }
    set stream=request.HttpResponse.Data
    set data=stream.Read(32000)
    //write data
    set numkeys=$l(data,"<Key>")
    for i=1:1:numkeys-1 {
        set file=$p($p(data,"<Key>",i+1),"</Key>")
        //write !,key
        set %extFileList($I(%extFileList))="s3://"_bucket_"/"_file
    }
    quit $$$OK
}

}
