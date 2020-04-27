# IRIS External Table

## Usage

Create table as usual:

```sql
CREATE TABLE test.table1
    (field1 VARCHAR(50), 
    int1 INT, 
    float1 DOUBLE, 
    field2 VARCHAR(50))
```
Than convert it to "External" table
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
`location` can point to individual file or directory with multiple files.

Supported adapters:
- DL.LocalFile
- DL.AWSS3
- DL.GoogleStorage
- DL.Azure

