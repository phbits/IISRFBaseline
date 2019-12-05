# fileExtensions_FS #

Request Filtering offers three settings when dealing with file extensions.

1.	`Allow` – specific file extensions allowed (whitelist).
2.	`Deny` – specific file extensions denied (blacklist).
3.	`allowUnlisted` – boolean enabled by default allows all file extensions not explicitly denied. When false, all requests must use an explicitly allowed file extension.

For requests without an extension, see the following section. 

Triggering this rule results in an HTTP `404` and IIS logs an HTTP `404.7`.

STIG recommends setting `allowUnlisted=false` and whitelisting allowed file extensions (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76827).

## Default Document & Requests without Extensions ##

For requests without a file extension, such as referencing a base directory (e.g. default document), a period (`.`) must be added to the allow list when `allowUnlisted=false`. The following configuration will only allow such occurrences.

```xml
<configuration>
   <system.webServer>
      <security>
         <requestFiltering>
            <fileExtensions allowUnlisted="false">
               <clear/>
               <add fileExtension="." allowed="true" />
            </fileExtensions>
         </requestFiltering>
      </security>
   </system.webServer>
</configuration>
```

## Clear Default fileExtensions ##

By default, IIS Request Filtering contains a list of file extensions to be blocked. Many of which are obvious such as .cs, .config, and .mdb files. This list works because of the default setting `allowUnlisted=True`. 

If the whitelist approach is pursued by setting `allowUnlisted=False`, use `<clear/>` to remove any inherited lists.

## Establishing a Value ##

This technique is best for a target website comprised of static content (e.g. .html, .css, .js, .jpg, etc.). Microsoft Logparser will search the website content directory identifying file extensions in use. 

File System is used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_fileExtensions_FS.sql--

SELECT DISTINCT 	
    EXTRACT_EXTENSION(Name) AS Extension,
    COUNT(*) AS TotalFiles

INTO D:\WorkingFolder\lp_results_fileExtensions_FS.csv

FROM \\server.contoso.com\www.contoso.com\*

WHERE Attributes NOT LIKE 'D%'

GROUP BY Extension

ORDER BY TotalFiles DESC

--lp_query_fileExtensions_FS.sql--
```

Selects the unique occurrences of all file extensions and counts the number of files with that extension as `TotalFiles`.
```sql
SELECT DISTINCT 
    EXTRACT_EXTENSION(Name) AS Extension,
    COUNT(*) AS TotalFiles
```

Where results will be stored.
```sql
INTO D:\WorkingFolder\lp_results_fileExtensions_FS.csv
```

Location of website content directory.
```sql
FROM \\server.contoso.com\www.contoso.com\*
```

Exclude directories.
```sql
WHERE Attributes NOT LIKE 'D%'
```

Grouping by `Extension` since a `SELECT DISTINCT` is being performed.
```sql
GROUP BY Extension
```

Order the results by `TotalFiles` in descending order.
```sql
ORDER BY TotalFiles DESC
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:FS -preserveLastAccTime:ON -o:CSV file:D:\WorkingFolder\lp_query_fileExtensions_FS.sql

## Results ##

A list of extensions and the number of occurrences is returned in the results (`lp_results_fileExtensions-FS.csv`). Omit file extensions that should not be requested by clients such as `.cs` and extensions from other supporting files. Next, compare these results with those from `fileExtensions-IIS` to create a file extensions whitelist for Request Filtering.
