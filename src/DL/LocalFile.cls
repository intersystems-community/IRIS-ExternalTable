Class DL.LocalFile [ Abstract ]
{

ClassMethod ReadNextLine(location) As %String
{
  	if '$IsObject($g(%dlstream)) {
        Set %dlstream=##class(%Stream.FileCharacter).%New()
	    Set sc=%dlstream.LinkToFile($get(^ET.Config("LocalDir"),"")_location)
	    Set %dlstream.LineTerminator=$char(10)
	}
	if '%dlstream.AtEnd {
		//s counter=$I(counter)
		Set line=%dlstream.ReadLine()
		s ^||ETRow=line
		quit $$$OK
		; Process the chunk here
	} else {
		kill %dlstream
		quit ""
	}
}

ClassMethod GenerateReadNextLine(config) As %String
{
   quit "    quit ##class(DL.LocalFile).ReadNextLine("""_config.location_""")"
}

ClassMethod GenerateRetrievalCode(config, propertyName, sqlFieldName, sqlColumnNumber) As %String
{
	quit "s {*}=$p(^||ETRow,"""_config.delimiter_""","_(sqlColumnNumber-1)_")"
}

}
