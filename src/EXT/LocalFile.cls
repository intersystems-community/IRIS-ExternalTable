Class EXT.LocalFile [ Abstract ]
{

ClassMethod GetFileHeader(filename, classname = "") As %Status
{
	Set %extstream=##class(%Stream.FileCharacter).%New()
	Set sc=%extstream.LinkToFile(filename)
	Set %extstream.LineTerminator=$char(10)
	quit $$$OK
}

ClassMethod SkipHeaders(classname)
{
	if classname'="" {
		set config={}.%FromJSON($replace($Parameter(classname,"ExternalTableParameters"),"'",""""))
		if config.skipHeaders'="" {
			for i=1:1:config.skipHeaders { 
				set line=%extstream.ReadLine() 
			}
		}
	}
	quit $$$OK
}

ClassMethod ReadNextLine(location, classname = "") As %String
{
  	if '$IsObject($g(%extstream)) {
		if '$data(%extFileList) {
			do ..GetFileList(location)
		}
		set %extFileNumber=1
		do ..GetFileHeader(%extFileList(%extFileNumber),classname)
		do ..SkipHeaders(classname)
	}
	if %extstream.AtEnd {
		set %extFileNumber=%extFileNumber+1
		if %extFileNumber>%extFileList {
			kill %extstream
			kill %extFileList
			quit ""
		}
		do ..GetFileHeader(%extFileList(%extFileNumber),classname)
		do ..SkipHeaders(classname)
	}
	if '%extstream.AtEnd {
		set line=%extstream.ReadLine()
		s ^||EXTRow=line
		quit $$$OK
	}
}

/// method would initialize list of files in %extFileList array
ClassMethod GetFileList(location, classname = "") As %Status
{
   kill %extFileList
   
   set resultSet = ##class(%ResultSet).%New()
   set resultSet.ClassName = "%Library.File"
   set resultSet.QueryName = "FileSet"
   set status = resultSet.%Execute($get(^EXT.Config("LocalDir"),"")_location)
   if $$$ISERR(status) {
	  //if resultset returns nothing - assume that filename was passed
	  set %extFileList($I(%extFileList))=$get(^EXT.Config("LocalDir"),"")_location
   }
   else {
		while (resultSet.%Next()) {
			//write !, resultSet.Name
			set %extFileList($I(%extFileList))=resultSet.Name
		}

   }
   quit $$$OK
}

ClassMethod GenerateReadNextLine(config, classname = "") As %String
{
   if config.type="jsonlines" {
	   set code="    set res = ##class("_$classname()_").ReadNextLine("""_config.location_""","""_classname_""")"_$c(10)_
				"    set %jsonline={}.%FromJSON(^||EXTRow)"_$c(10)_
				"    quit res"
   } elseif config.type="quoted_csv" {
	   set code="    set res = ##class("_$classname()_").ReadNextLine("""_config.location_""","""_classname_""")"_$c(10)_
				"    if '$data(%extRegEx) set %extRegEx=##class(%Regex.Matcher).%New("",?"""".+?""""|[^""""]+?(?=,)|[^""""]+"")"_$c(10)_
				"    kill %csvline"_$c(10)_
				//"    write ""%extRegEx "",$isobject(%extRegEx)"_$c(10)_
				"    set %extRegEx.Text=^||EXTRow"_$c(10)_
				"    while %extRegEx.Locate() {"_$c(10)_
				"      set %csvline($i(%csvline))=$zstrip(%extRegEx.Group,""<"","","")"_$c(10)_
				"    }"_$c(10)_
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
        "payment_options": "%jsonline.'payment_options'",
        "rate_details_periods": "%jsonline.'rate_details'.periods"}
	*/
	//$case($isobject(obj.embed),1:obj.embed.%ToJSON(),0:obj.embed)
	    set fieldExpression=config.jsonParser.%Get(sqlFieldName)
		//return row.field.%ToJSON() of Attar or Object and row.field if not
		quit "s {*}=$case($IsObject("_fieldExpression_"),1:"_fieldExpression_".%ToJSON(),0:"_fieldExpression_")"

	} else {
		quit "s {*}=%jsonline."""_sqlFieldName_""""
   }
  } elseif config.type="quoted_csv" {
	  quit "s {*}=$get(%csvline("_(sqlColumnNumber-1)_"))"
   } else {
	quit "s {*}=$p(^||EXTRow,"""_config.delimiter_""","_(sqlColumnNumber-1)_")"
   }
}

}
