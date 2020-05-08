Class EXT.ExternalStorage [ Abstract ]
{

ClassMethod ConvertToExternal(tablename, parameters) As %Status [ SqlName = ConvertToExternal, SqlProc ]
{
 if $e($zstrip(parameters,"<W"))="{" {
    //parameters - json string
    set config={}.%FromJSON(parameters)
 } 
 else {
   //parameters - json file
   set file=##class(%Stream.FileCharacter).%New()
   Set sc=file.LinkToFile($get(^EXT.Config("LocalDir"),"")_parameters)
   set config={}.%FromJSON(file.Read(32000))
 }
 set configTxt=config.%ToJSON()
 set configTxt=$replace(configTxt,"""","'")
 
 set LNBR=$c(10)
 s classname=tablename //add proper tablename detection
 s tempsourcefile="tempsrc.cls"
 s temptargetfile="temptgt.cls"
 s newClassNamePrefix=""
 Set sc=$system.OBJ.ExportUDL(classname_".cls",tempsourcefile)
 Set file=##class(%Stream.FileCharacter).%New()
 Set sc=file.LinkToFile(tempsourcefile)
 kill tmp
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
	 	 //set storageProperties=storageProperties_"<RetrievalCode>s {*}=$p(^||EXTRow,"""_config.delimiter_""","_(sqlColumnNumber-1)_")</RetrievalCode>"_LNBR
	 	 set storageProperties=storageProperties_"<RetrievalCode>"_$ClassMethod(config.adapter, "GenerateRetrievalCode", config, propertyName,sqlFieldName,sqlColumnNumber)_"</RetrievalCode>"_LNBR
	 	 set storageProperties=storageProperties_"</Data>"_LNBR
	 }
 }
 // SqlTableName = ""{{TABLENAME}}"",
 set classHead=""_
 "Class {{CLASSNAME}} Extends (%Persistent, EXT.ExternalStorage) [ SqlRowIdPrivate, DdlAllowed, StorageStrategy = ETStorage ]"_LNBR_
  "{"_LNBR_
  "Parameter ExternalTableParameters = """_configTxt_""";"_LNBR_
  "Parameter ExternalTableLocation = """_config.location_""";"_LNBR_
  ""_LNBR_
  //"Parameter FileName = ""{{LOCATION}}"";"_LNBR_
  //""_LNBR_
  "Index Master On RowID [ IdKey, Internal, PrimaryKey, Unique ];"_LNBR_
  ""_LNBR_
  "Property RowID As %Integer [ Internal, Private ];"_LNBR_
  "Property %PATH As %String [ Private ];"_LNBR

   if config.type="jsonlines" {
      //private %DOCUMENT property does contain entire original line
      set classHead=classHead_"Property %DOCUMENT As %String [ Private ];"_LNBR
   }

  set classHead=$replace(classHead,"{{CLASSNAME}}",newClassNamePrefix_classname)
  set classHead=$replace(classHead,"{{TABLENAME}}",tablename)
  //set classHead=$replace(classHead,"{{LOCATION}}",location)

 set methodReadNextLine=
    LNBR_"ClassMethod ReadNextLine(counter) As %String"_LNBR_
    "  {"_LNBR_
    $ClassMethod(config.adapter, "GenerateReadNextLine", config, classname)_LNBR_
    "  }"_LNBR


 set storageProperties=storageProperties_"<Data name=""%PATH"">"_LNBR
 set storageProperties=storageProperties_"<RetrievalCode>s {*}=%extFileList(%extFileNumber)</RetrievalCode>"_LNBR
 set storageProperties=storageProperties_"</Data>"_LNBR

   if config.type="jsonlines" {
      set storageProperties=storageProperties_"<Data name=""%DOCUMENT"">"_LNBR
      set storageProperties=storageProperties_"<RetrievalCode>s {*}=^||EXTRow</RetrievalCode>"_LNBR
      set storageProperties=storageProperties_"</Data>"_LNBR
   }

 set storageHead=LNBR_
 "Storage ETStorage"_LNBR_
 "{"_LNBR_
 "<SQLMap name=""Map1"">"_LNBR
 
 set storageTail=
  "<Global>^||EXTRow</Global>"_LNBR_
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
 //w methodReadNextLine
 //w storageProperties
 //w storageTail
 
 Set file=##class(%File).%New(temptargetfile)
 Do file.Open("WSN")
 Do file.Write(classHead)
 Do file.Write(targetProperties)
 Do file.Write(methodReadNextLine)
 Do file.Write(storageHead)
 Do file.Write(storageProperties)
 Do file.Write(storageTail)
 Do file.Write(classTail)
 kill file //close(?) file
 do $system.OBJ.Delete(newClassNamePrefix_classname)
 do $system.OBJ.Load(temptargetfile,"c")
 quit $$$OK
}

}
