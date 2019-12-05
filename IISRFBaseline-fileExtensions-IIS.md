# fileExtensions_IIS #

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

This technique is best for a target website/application that dynamically generates URLs (e.g. MVC and WebAPI). Microsoft LogParser will parse the IIS logs to identify file extensions in requests (`cs-uri-stem`).

Only successful requests are included in the results. See ***Successful Requests*** in the FAQ for details.

IIS Logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

### Caution! ###
Using the Logparser `EXTRACT_EXTENSION()` function when parsing the IIS logs can miss critical URLs. In the following example, the `EXTRACT_EXTENSION()` function is unable to identify `.svc` as a file extension since it appears as though a period was used for the naming of a folder. However, this is a valid WCF service with a corresponding file `myservice.svc`. If possible, review these results with the website/application developer and test before going to production with RF settings.

    Request     : http://www.contosos.com/service/myservice.svc/something
    cs-uri-stem : /service/myservice.svc/something

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_fileExtensions_IIS.sql--

SELECT DISTINCT
    cs-uri-stem,
    EXTRACT_EXTENSION(cs-uri-stem) AS Extension,
    COUNT(*) AS Hits

INTO D:\WorkingFolder\lp_results_fileExtensions_IIS.csv

FROM D:\folder\u_ex*.log

WHERE s-sitename LIKE 'W3SVC3'
    AND (sc-status<303 AND sc-status>=200)

GROUP BY cs-uri-stem, Extension

ORDER BY Hits DESC

--lp_query_fileExtensions_IIS.sql--
```

Selects the unique occurrences of `cs-uri-stem` and extracts the extension from the request path (`cs-uri-stem`), then count how many of those requests have been received as `Hits`. 
```sql
SELECT DISTINCT
    cs-uri-stem,
    EXTRACT_EXTENSION(cs-uri-stem) AS Extension,
    COUNT(*) AS Hits
```

Where results will be stored.
```sql
INTO D:\WorkingFolder\lp_results_fileExtensions_IIS.csv
```
Location of the IIS logs for this website.
```sql
FROM D:\folder\u_ex*.log
```

Specifies the target IIS website.
```sql
WHERE s-sitename LIKE 'W3SVC3' 
```

We’re only concerned with successful requests and thus targeting HTTP status codes in the `2XX` range as well as redirects of `301` or `302`.
```sql
AND (sc-status<303 AND sc-status>=200)
```

Grouping by `cs-uri-stem` and `Extension` since a `SELECT DISTINCT` is being performed.
```sql
GROUP BY cs-uri-stem, Extension
```

Order the results by `Hits` in descending order.
```sql
ORDER BY Hits DESC
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_fileExtensions_IIS.sql

## Results ##

Result file (`lp_results_fileExtensions-IIS.csv`) will show successful requests to `cs-uri-stem` and the file extension of that request. Compare this list with `fileExtensions-FS` results to create a file extensions whitelist for this Request Filtering setting. If file extensions appear in the `FS` list and not `IIS` list, determine if those files will ever be requested by clients. Conversely, if there are file extensions in the `IIS` list that do not appear in the `FS` list determine why this is the case. Is the request to a service or dynamic URL? 
