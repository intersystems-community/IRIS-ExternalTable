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
Than convert it to "External" table
```sql
CALL DL.ConvertToExternal('test.table1','<path-to>/multifile-gs.json')
```
Note: currently for debugging reason we create new class/table by adding `ext` prefix to the table name so `test.table1` becames `exttest.table1`.

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

