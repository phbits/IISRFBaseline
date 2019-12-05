# maxUrl_IIS #

This request limit setting of Request Filtering checks the length of the normalized URL [Path](https://tools.ietf.org/html/rfc3986#section-3); including the initial forward slash ("`/`"). IIS will log the value of this request in the `cs-uri-stem` field.

If the length exceeds what is set for `maxUrl` an HTTP `404` is returned to the client and IIS logs an HTTP `404.14`.

STIG recommends a value of `4096` or less (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76817).

## Normalizing URL Path ##

URL encoding may substitute the parentheses (round brackets) in "`file(copy).html`" with `%28` and `%29`.

    http://mvc.contoso.com/folder/file%28copy%29.html

IIS normalizes the URL encoding. With each character being a single byte, the minimum value to allow this request is `maxUrl = 23`

    http://mvc.contoso.com/folder/file(copy).html

## Establishing a Value ##

This technique is best for a target website/application that dynamically generates URLs (e.g. MVC and WebAPI). Logparser is used to parse the IIS logs and return a list of proposed `cs-uri-stem` requests with the calculated length.

Only successful requests are included in the results. See ***Successful Requests*** in the FAQ for details.

IIS Logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_maxUrl_IIS.sql--

SELECT DISTINCT 
    cs-uri-stem as Path,
    STRLEN(cs-uri-stem) AS PathLength

INTO D:\WorkingFolder\lp_results_maxUrl_IIS.csv

FROM D:\folder\u_ex*.log

WHERE 
    s-sitename LIKE 'W3SVC3'
        AND (sc-status<303 AND sc-status>=200)

GROUP BY Path

ORDER BY PathLength DESC

--lp_query_maxUrl_IIS.sql--
```

Selects the `cs-uri-stem` field from the IIS log and uses the LogParser function `STRLEN()` to return the length of the specified string.
```sql
SELECT DISTINCT 
    cs-uri-stem as Path,
    STRLEN(cs-uri-stem) AS PathLength
```

Where results will be stored.
```sql
INTO D:\WorkingFolder\lp_results_maxUrl_IIS.csv
```

Location of the IIS logs for this website.
```sql
FROM D:\folder\u_ex*.log
```

Specifies the target IIS website.
```sql
WHERE s-sitename LIKE 'W3SVC3' 
```

We are only concerned with successful requests and thus targeting HTTP status codes in the `2XX` range as well as redirects of `301` or `302`.
```sql
AND (sc-status<303 AND sc-status>=200)
```

Grouping by `Path` since a `SELECT DISTINCT` is being performed.
```sql
GROUP BY Path
```

Order by `PathLength` with the longest first.
```sql
ORDER BY PathLength DESC
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_maxUrl_IIS.sql

## Results ##

Begin with the top result (longest `PathLength`) that is a valid request. Compare with the result derived from the file system (`lp_results_maxUrl_FS.csv`) and use the longest value for this setting.
