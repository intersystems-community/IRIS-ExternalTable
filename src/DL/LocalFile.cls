Class DL.LocalFile [ Abstract ]
{

ClassMethod GetFileHeader(filename, classname = "") As %Status
{
	Set %dlstream=##class(%Stream.FileCharacter).%New()
	Set sc=%dlstream.LinkToFile(filename)
	Set %dlstream.LineTerminator=$char(10)
	quit $$$OK
}

ClassMethod SkipHeaders(classname)
{
	if classname'="" {
		set config={}.%FromJSON($replace($Parameter(classname,"ExternalTableParameters"),"'",""""))
		if config.skipHeaders'="" {
			for i=1:1:config.skipHeaders { 
				set line=%dlstream.ReadLine() 
			}
		}
	}
	quit $$$OK
}

ClassMethod ReadNextLine(location, classname = "") As %String
{
  	if '$IsObject($g(%dlstream)) {
		if '$data(%etFileList) {
			do ..GetFileList(location)
		}
		set %etFileNumber=1
		do ..GetFileHeader(%etFileList(%etFileNumber),classname)
		do ..SkipHeaders(classname)
	}
	if %dlstream.AtEnd {
		set %etFileNumber=%etFileNumber+1
		if %etFileNumber>%etFileList {
			kill %dlstream
			kill %etFileList
			quit ""
		}
		do ..GetFileHeader(%etFileList(%etFileNumber),classname)
		do ..SkipHeaders(classname)
	}
	if '%dlstream.AtEnd {
		set line=%dlstream.ReadLine()
		s ^||ETRow=line
		quit $$$OK
	}
}

/// method would initialize list of files in %etFileList array
ClassMethod GetFileList(location, classname = "") As %Status
{
   kill %etFileList
   
   set resultSet = ##class(%ResultSet).%New()
   set resultSet.ClassName = "%Library.File"
   set resultSet.QueryName = "FileSet"
   set status = resultSet.%Execute($get(^ET.Config("LocalDir"),"")_location)
   if $$$ISERR(status) {
	  //if resultset returns nothing - assume that filename was passed
	  set %etFileList($I(%etFileList))=$get(^ET.Config("LocalDir"),"")_location
   }
   else {
		while (resultSet.%Next()) {
			//write !, resultSet.Name
			set %etFileList($I(%etFileList))=resultSet.Name
		}

   }
   quit $$$OK
}

ClassMethod GenerateReadNextLine(config, classname = "") As %String
{
   if config.type="jsonlines" {
	   set code="    set res = ##class("_$classname()_").ReadNextLine("""_config.location_""","""_classname_""")"_$c(10)_
				"    set %jsonline={}.%FromJSON(^||ETRow)"_$c(10)_
				"    quit res"
   } else { 
	   //default to CSV 
	   set code="    quit ##class("_$classname()_").ReadNextLine("""_config.location_""","""_classname_""")"
   }
   quit code
}

ClassMethod GenerateRetrievalCode(config, propertyName, sqlFieldName, sqlColumnNumber) As %String
{
   if config.type="jsonlines" {
	if config.jsonParser.%Get(sqlFieldName)'="" {
	 /*   "jsonParser": {
        "payment_options": "%jsonline.'payment_options'.%ToJSON()",
        "rate_details_periods": "%jsonline.'rate_details'.periods.%ToJSON()"}
	*/
		quit "s {*}="_$replace(config.jsonParser.%Get(sqlFieldName),"'","""")

	} else {
		quit "s {*}=%jsonline."""_sqlFieldName_""""
   }
   } else {
	quit "s {*}=$p(^||ETRow,"""_config.delimiter_""","_(sqlColumnNumber-1)_")"
   }
}

}
