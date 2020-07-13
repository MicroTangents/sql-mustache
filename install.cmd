for /F "usebackq eol=;" %%s in ("install.ini") do set %%s

sqlCmd -S %ServerName% -E -Q "IF (SCHEMA_ID('mustache') IS NULL) BEGIN EXEC sp_executeSql @sql = N'CREATE SCHEMA [%Schema%]'; END" -v DatabaseName=%DatabaseName%

for /r %%i in (src\functions\*) do sqlCmd -S %ServerName% -E -i "%%i" -v DatabaseName=%DatabaseName%