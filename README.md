# IRIS External Table

![CI](https://github.com/antonum/IRIS-ExternalTable/workflows/CI/badge.svg)

## Usage

Create table as usual:

```sql
CREATE TABLE test.table1
    (field1 VARCHAR(50), 
    int1 INT, 
    float1 DOUBLE, 
    field2 VARCHAR(50))
```
Than convert it to "External" table use `DL.ConvertToExternal` stored procedure, specifying existing table name and JSON table configuration

```sql
call DL.ConvertToExternal(
    'test.table1',
    '{ 
        "adapter":"DL.GoogleStorage",
        "location":"gs://iris-external-table/",
        "delimiter": ","
    }' 
)
```
Or using table configuration file
```sql
CALL DL.ConvertToExternal('test.table1','<path-to>/multifile-gs.json')
```
Where `multifile-gs.json` is:
```json
{
    "adapter":"DL.GoogleStorage",
    "location":"gs://iris-external-table/",
    "delimiter": ","
}
```

`adapter` and `location` are required parameters.

`location` can point to a single file or directry/bucket.

Supported adapters:
- DL.LocalFile - files on the local file system
- DL.AWSS3 - 
- DL.GoogleStorage
- DL.Azure

## %PATH

For all the tables, the additional hidden `%PATH` field is created, containing the underlying filename. It can be useful for processing log data where file name itself indicates date/time value. `%PATH` is not included in `SELECT * FROM TableName` query and must be explicitly specified.

```sql
SELECT %PATH, * FROM myExternalTable
```

## CSV files

You must specify `"delimiter": ","`

## JSON files

JSON Lines http://jsonlines.org/ format supported. File contains multiple lines, every line is a single JSON document, converted to the row.

JSON table configuration must specify `"type": "jsonlines"`

Fields in JSON data are matched to the field names in SQL table by default. Names are case sensitive.

For complex/non-flat JSON structures you can specify optional `"jsonParser"` section, where table field name is matched to the ObjectScript code, extracting field data from %jsonline object. Use https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GJSON_create for the reference.

Field names with underscores, dashes etc. must be enclosed in single quotes.

```json
{
    "adapter":"DL.LocalFile",
    "location":"<path-to>/toronto-green-parking.json",
    "type": "jsonlines",
    "jsonParser": {
        "payment_options": "%jsonline.'payment_options'.%ToJSON()",
        "rate_details_periods": "%jsonline.'rate_details'.'periods'"
    }
}
```
For the tables of `jsonlines` type additional hidden `%DOCUMENT` field is created, similar to `%PATH`. `%DOCUMENT` contains the entire JSON document that can be used for extracting data from documents in downstram processing.

```sql
SELECT %DOCUMENT, * FROM myExternalTable
```




