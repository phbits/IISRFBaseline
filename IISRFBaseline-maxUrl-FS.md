# maxUrl_FS #

This request limit setting of Request Filtering checks the length of the normalized URL [Path](https://tools.ietf.org/html/rfc3986#section-3); including the initial forward slash ("`/`"). IIS will log the value of this request in the `cs-uri-stem` field.

If the length exceeds what is set for `maxUrl` an HTTP `404` is returned to the client and IIS logs an HTTP `404.14`.

STIG recommends a value of `4096` or less (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76817).

## Normalizing URL Path ##

URL encoding may substitute the parentheses (round brackets) in "`file(copy).html`" with `%28` and `%29`.

    http://mvc.contoso.com/folder/file%28copy%29.html

IIS normalizes the URL encoding. With each character being a single byte, the minimum value to allow this request is `maxUrl = 23`

    http://mvc.contoso.com/folder/file(copy).html

## Establishing a Value ##

This option is best for websites with static content (e.g. .html, .js, .css, .jpg). Logparser is used to parse the content directory and return a list of proposed `cs-uri-stem` requests with the calculated length. 

File System is used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_maxUrl_FS.sql--

SELECT 
    Path AS FilePath,
    REPLACE_CHR(file-cs-uri-stem,'\\','/') AS PROPOSED-cs-uri-stem,
    STRLEN(PROPOSED-cs-uri-stem) AS maxUrl

USING
    REPLACE_STR(Path, '\\server.contoso.com\www.contoso.com', '') as file-cs-uri-stem
    
INTO D:\WorkingFolder\lp_results_maxUrl_FS.csv

FROM \\server.contoso.com\www.contoso.com\*

WHERE
    Path NOT LIKE '%\\aspnet_client%' AND
    Path NOT LIKE '%.config' AND
    Path NOT LIKE '%.dll' AND
    Path NOT LIKE '%.cs' AND
    Path NOT LIKE '%\\..' AND
    Path NOT LIKE '%\\.'

ORDER BY maxUrl DESC

--lp_query_maxUrl_FS.sql--
```

Selects the path of the file/folder. Replaces any backslash with a forwardslash from `file-cs-uri-stem` to create `PROPOSED-cs-uri-stem`. The length of `PROPOSED-cs-uri-stem` is calculated for `maxUrl`.
```sql
SELECT 
    Path AS FilePath,
    REPLACE_CHR(file-cs-uri-stem,'\\','/') AS PROPOSED-cs-uri-stem,
        STRLEN(PROPOSED-cs-uri-stem) AS maxUrl
```

Removes the base content directory to create `file-cs-uri-stem`.
```sql
USING
    REPLACE_STR(Path, '\\server.contoso.com\www.contoso.com', '') as file-cs-uri-stem
```

Where results will be stored.
```sql
INTO D:\WorkingFolder\lp_results_maxUrl_FS.csv
```

Location of website content directory.
```sql
FROM \\server.contoso.com\www.contoso.com\*
```

This `WHERE` clause removes common files/folders that will not be requested. Update as necessary.
```sql
WHERE
    Path NOT LIKE '%\\aspnet_client%' AND
    Path NOT LIKE '%.config' AND
    Path NOT LIKE '%.dll' AND
    Path NOT LIKE '%.cs' AND
    Path NOT LIKE '%\\..' AND
    Path NOT LIKE '%\\.'
```

Order by `maxUrl` with the longest first.
```sql
ORDER BY maxUrl DESC
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:FS -preserveLastAccTime:ON -o:CSV file:D:\WorkingFolder\lp_query_maxUrl_FS.sql

## Results ##

Start with the first entry (i.e. largest `maxUrl` value) in the results file (`lp_results_maxUrl-FS.csv`). Verify `PROPOSED-cs-uri-stem` would be a valid client request.  Recall that a valid `cs-uri-stem` must begin with a forward slash (`/`). Move down the list until the first valid request is identified, then compare that `maxUrl` value with the one derived from IIS logs (`lp_results_maxUrl_IIS.csv`) and use the longest value for this setting.
