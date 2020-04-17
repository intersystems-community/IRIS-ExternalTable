Class DL.ExternalStorage [ Abstract ]
{

// Parameter FileName = "c:\InterSystems\orders.tbl";

Parameter FileName = "s3://bigdataantonum/emrdata-s/orders/orders.tbl";

ClassMethod ConvertToExternal(tablename, location, delimiter = ",") As %Status [ SqlName = ConvertToExternal, SqlProc ]
{
 s classname=tablename //add proper tablename detection
 s tempsourcefile="tempsrc.cls"
 s temptargetfile="temptgt.cls"
 s newClassNamePrefix="ext"
 Set sc=$system.OBJ.ExportUDL(classname_".cls",tempsourcefile)
 Set file=##class(%Stream.FileCharacter).%New()
 Set sc=file.LinkToFile(tempsourcefile)
 kill tmp
 set LNBR=$c(10,13)
 set targetProperties=LNBR
 set storageProperties=LNBR
 while 'file.AtEnd {
	 set line=file.ReadLine()
	 if line["Property " {
		 set propertyName=$p(line," ",2)
		 //set tmp(pname,"line")=line
		 set sqlFieldName=$p($p(line,"SqlFieldName",2)," ",3)
		 if sqlFieldName="" {set sqlFieldName=propertyName}
		 set sqlColumnNumber=$p($p($p(line,"SqlColumnNumber",2)," ",3),",",1)
		 //set tmp(pname,"sqlname")=sqlFieldName
		 //set tmp(pname,"sqlcolumn")=sqlColumnNumber
	 	 //write !,line
	 	 set targetProperties=targetProperties_line_LNBR
	 	 /*
	 	 <Data name="O_TOTALPRICE">
			<RetrievalCode>s {*}=$p(^||CSVRow,"|",4)</RetrievalCode>
		 </Data>
		   */
	 	 set storageProperties=storageProperties_"<Data name="""_sqlFieldName_""">"_LNBR
	 	 set storageProperties=storageProperties_"<RetrievalCode>s {*}=$p(^||CSVRow,"""_delimiter_""","_(sqlColumnNumber-1)_")</RetrievalCode>"_LNBR
	 	 set storageProperties=storageProperties_"</Data>"_LNBR
	 }
 }
 // SqlTableName = ""{{TABLENAME}}"",
 set classHead=""_
 "Class {{CLASSNAME}} Extends (%Persistent, DL.ExternalStorage) [ SqlRowIdPrivate, StorageStrategy = CSVFileStorage ]"_LNBR_
  "{"_LNBR_
  "// Parameter FileName = ""c:\directory\file.csv"";"_LNBR_
  "// Parameter FileName = ""s3://bucketname/folder/file.csv"";"_LNBR_
  ""_LNBR_
  "Parameter FileName = ""{{LOCATION}}"";"_LNBR_
  ""_LNBR_
  "Index Master On RowID [ IdKey, Internal, PrimaryKey, Unique ];"_LNBR_
  ""_LNBR_
  "Property RowID As %Integer [ Internal, Private ];"_LNBR
  set classHead=$replace(classHead,"{{CLASSNAME}}",newClassNamePrefix_classname)
  set classHead=$replace(classHead,"{{TABLENAME}}",tablename)
  set classHead=$replace(classHead,"{{LOCATION}}",location)

 set storageHead=LNBR_
 "Storage CSVFileStorage"_LNBR_
 "{"_LNBR_
 "<SQLMap name=""Map1"">"_LNBR
 
 set storageTail=LNBR_
  "<Global>^||CSVRow</Global>"_LNBR_
  "<Subscript name=""1"">"_LNBR_
  "<Expression>{RowID}</Expression>"_LNBR_
  "<NextCode>s status=##class({{CLASSNAME}}).ReadNextLine({L1})"_LNBR_
  " if status="""" set {L1}="""" QUIT"_LNBR_
  " s {L1}=""DO NOT USE!"""_LNBR_
  " QUIT"_LNBR_
  "</NextCode>"_LNBR_
  "</Subscript>"_LNBR_
  "<Type>data</Type>"_LNBR_
  "</SQLMap>"_LNBR_
  "<StreamLocation>^{{CLASSNAME}}S</StreamLocation>"_LNBR_
  "<Type>%Storage.SQL</Type>"_LNBR_
  "}"_LNBR

  set storageTail=$replace(storageTail,"{{CLASSNAME}}",newClassNamePrefix_classname)
  
  set classTail=LNBR_"}"
 
 //zw tmp
 //w targetProperties
 //w storageProperties
 //w storageTail
 
 Set file=##class(%File).%New(temptargetfile)
 Do file.Open("WSN")
 Do file.Write(classHead)
 Do file.Write(targetProperties)
 Do file.Write(storageHead)
 Do file.Write(storageProperties)
 Do file.Write(storageTail)
 Do file.Write(classTail)
 kill file //close(?) file
 do $system.OBJ.Delete(newClassNamePrefix_classname)
 do $system.OBJ.Load(temptargetfile,"c")
 quit $$$OK
}

ClassMethod ReadNextLine(counter) As %String
{
	if '$IsObject($g(%dlstream)) {
		if ..#FileName [ "s3://" {
		      set tBucket = $p(..#FileName,"/",3) //"deepsee-2018"
              //add non - us-east1 region here
              set tServer = tBucket_".s3.amazonaws.com"
              set tFilename=$p(..#FileName,"/",4,*) // "test.csv"
              //set tPort = 80
              if '$data(^AWSCredentials) {
	              set sc=..GetAWSCredentials()
	              //if $$$ISERR(sc) warn that credentials not found. Attempt to proceed in case file is public
              }
              set tAccessKeyId =^AWSCredentials("AccessKeyId")
              set tSecretAccessKey = ^AWSCredentials("SecretAccessKey")

              set tStart = $ZH
              set tRequest = ##class(%Net.HttpRequest).%New()                         
              set tRequest.Server = tServer                                       
              set tRequest.SSLConfiguration="SSLClient"
              //set tRequest.Port = tPort
              set tDateH = $ZTS
              set tWeekDay = $P($ZDT(tDateH,11)," ",1)
              set tDate = tWeekDay_", "_$ZDT(tDateH,2,1)_" GMT"
              //w !,"Date: "_tDate
              set tRequest.Date = tDate
              set tContentMD5 = ""
              set tContentType = ""
              set tStringToSign = "GET"_$C(10)_tContentMD5_$C(10)_tContentType_$C(10)_tDate_$C(10)_"/"_tBucket_"/"_tFilename
              //w !,"StringToSign (before UTF-8 conversion): "_tStringToSign
              set tStringToSignUTF8 = $ZCONVERT(tStringToSign,"O","UTF8")
              //w !,"StringToSign (after UTF-8 conversion): "_tStringToSign
              set tSignature = ##class(%SYSTEM.Encryption).HMACSHA1(tStringToSignUTF8,tSecretAccessKey)
              //w !,"Signature (before Base64 encoding): "_tSignature
              set tSignatureBase64 = ##class(%SYSTEM.Encryption).Base64Encode(tSignature)
              //w !,"Signature (after Base64 encoding): "_tSignature
              set tAuthorization = "AWS "_tAccessKeyId_":"_tSignatureBase64
              //w !,"Authorization: "_tAuthorization
              set tRequest.Authorization = tAuthorization
              set tURL =  "/"_tFilename
              //do tRequest.OutputHeaders()
              set tSC = tRequest.Get(tURL)
              //do tRequest.HttpResponse.OutputHeaders()
              //do tRequest.HttpResponse.OutputToDevice()
              set %dlstream=tRequest.HttpResponse.Data
		}
		else {
			//Local File
			Set %dlstream=##class(%Stream.FileCharacter).%New()
			Set sc=%dlstream.LinkToFile(..#FileName)
		}
		Set %dlstream.LineTerminator=$char(10)
	}
	if '%dlstream.AtEnd {
		//s counter=$I(counter)
		Set line=%dlstream.ReadLine()
		s ^||CSVRow=line
		quit $$$OK
		; Process the chunk here
	} else {
		kill %dlstream
		quit ""
	}
}

ClassMethod GetAWSCredentials() As %Status
{
 //curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/
 //S3-AdminAccess
 //curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/S3-AdminAccess
 do ^initAWS
 quit $$$OK
}

}
