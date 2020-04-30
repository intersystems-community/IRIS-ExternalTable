Class Test.SQLRunner [ Abstract ]
{

ClassMethod RunSQLFile(filename) As %Status
{
	Set sqlfile=##class(%Stream.FileCharacter).%New()
	Set sc=sqlfile.LinkToFile($get(^ET.Config("LocalDir"))_filename)
	//Set sqlfile.LineTerminator=$char(10)
    set teststatus=$$$OK
    kill sql
    while 'sqlfile.AtEnd {
        set line=sqlfile.ReadLine()
        if ($extract(line,0,3)=" --") {
            if $d(sql) {
                set sc=..ExecuteSQL(.sql)
                if $$$ISERR(sc) {
                    set teststatus=$SYSTEM.Status.AppendStatus(teststatus,sc)
                }
            }
            write !,line
            kill sql
        } else {
            set sql($i(sql))=line
        }
    }
    if $$$ISERR(teststatus) {
        write !, "##########################"
        write !, "#### THERE ARE ERRORS ####"
        write !, "##########################"
        do $system.OBJ.DisplayError(teststatus)
    }
	quit teststatus
}

ClassMethod ExecuteSQL(ByRef sql)
{
    write !, "Executing: ",sql(1)
    set result=$system.SQL.Execute(.sql)
    write !,"SQLCODE: ",result.%SQLCODE
    write !
    do result.%Display()
    if result.%SQLCODE>=0 {
        quit $$$OK
    } else {
        quit $$$ERROR($$$GeneralError,result.%Message_" for the statement "_sql(1))
    }
}

}
