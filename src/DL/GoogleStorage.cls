Class DL.GoogleStorage Extends DL.LocalFile
{

ClassMethod GetFileList(location) As %Status
{
    kill %etFileList
    //curl -H "Authorization: Bearer $TOKEN" "https://storage.googleapis.com/storage/v1/b/iris-external-table/o?prefix="
    set tmpfilename="gsutil_ls.txt" //##class(%File).TempFilename()
    set args=2
    set args(1)="ls"
    set args(2)=location
    set sc = $ZF(-100,"/STDOUT="_tmpfilename, "gsutil", .args)
    set file=##class(%Stream.FileCharacter).%New()
    set sc=file.LinkToFile(tmpfilename)
    while 'file.AtEnd {
        //write !, file.ReadLine()
        set %etFileList($I(%etFileList))=file.ReadLine()
    } 
    quit $$$OK
}

ClassMethod GetAccessToken() As %String
{
    //$ gcloud auth print-access-token
    if '$data(%etGoogleAuthToken) {
        set tmpfilename="gc_token.txt" //##class(%File).TempFilename()
        set args=2
        set args(1)="auth"
        set args(2)="print-access-token"
        set sc = $ZF(-100,"/STDOUT="_tmpfilename, "gcloud", .args)
        set file=##class(%Stream.FileCharacter).%New()
        set sc=file.LinkToFile(tmpfilename)
        set %etGoogleAuthToken=file.Read(1000)
        set file=""
        set sc=##class(%File).Delete(tmpfilename)
    }
    //curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
    quit " Bearer "_%etGoogleAuthToken
}

ClassMethod GetFileHeader(filename) As %Status
{
	//curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    //"https://storage.googleapis.com/download/storage/v1/b/<bucket>/o/<key>?alt=media"
    
    //  gs://iris-external-table/file3.csv
    set server="storage.googleapis.com" 
    set bucket=$p(filename,"/",3)
    set key=$p(filename,"/",4,*)
    set request = ##class(%Net.HttpRequest).%New()                         
    set request.Server = server
    set request.Https=1                                     
    set request.SSLConfiguration="ISC.FeatureTracker.SSL.Config"
    set request.Authorization = ..GetAccessToken()
    //set request.Port = tPort
    set url =  "/download/storage/v1/b/"_bucket_"/o/"_key_"?alt=media"
    //do request.OutputHeaders()
    set sc = request.Get(url)
    //do request.HttpResponse.OutputHeaders()
    //do request.HttpResponse.OutputToDevice
    set %dlstream=request.HttpResponse.Data
    Set %dlstream.LineTerminator=$char(10)
	quit $$$OK
}

// gsutil ls -l gs://iris-external-table/

// curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \

// "https://storage.googleapis.com/storage/v1/b/chc-api-qwiklabs/o"

}
