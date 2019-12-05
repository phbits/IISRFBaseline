# verbs #

Defined by [RFC7231](https://tools.ietf.org/html/rfc7231#section-4) as Request Methods, Request Filtering has three settings to deal with HTTP verbs.

1.	`Allow` – specific HTTP verbs allowed (whitelisted).
2.	`Deny` – specific HTTP verbs denied (blacklisted).
3.	`allowUnlisted` – boolean enabled by default allowing all verbs not explicitly denied. When false, all requests must use an explicitly allowed verb.

Triggering this setting returns an HTTP `404` to the client and IIS logs an HTTP `404.6`.

## HTTP verb ##

[RFC7231](https://tools.ietf.org/html/rfc7231#section-4) describes it as:

> the purpose for which the client has made this request

The following example is an HTTP GET request.

```
GET /default.html HTTP/1.1
Host: www.contoso.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Connection: Keep-Alive
Accept-Encoding: gzip, deflate
Cache-Control: no-cache
Accept: */*
```

## Establishing a Value ##

Microsoft Logparser will parse the IIS logs of the target website/application to determine what verbs are used.

Only successful requests are included in the results. See ***Successful Requests*** in the FAQ for details.

IIS Logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_verbs.sql--

SELECT DISTINCT 
    cs-method AS verb,
    cs-uri-stem,
    COUNT(*) AS Hits

INTO D:\WorkingFolder\lp_results_verbs.csv

FROM D:\folder\u_ex*.log

WHERE s-sitename LIKE 'W3SVC3'
    AND (sc-status<303 AND sc-status>=200)

GROUP BY verb, cs-uri-stem

ORDER BY cs-uri-stem, Hits

--lp_query_verbs.sql--
```

Selects the unique occurrences of `cs-method` and `cs-uri-stem`, then count how many of those requests have been received as `Hits`.
```sql
SELECT DISTINCT 
    cs-method AS verb,
    cs-uri-stem,
    COUNT(*) AS Hits
```

Where results will be stored only if matches are found.
```sql
INTO D:\WorkingFolder\lp_results_verbs.csv
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
AND sc-status<303 and sc-status>=200
```

Grouping by `verb` and `cs-uri-stem` since `SELECT DISTINCT` is being performed.
```sql
GROUP BY verb, cs-uri-stem
```

Order the results by `cs-uri-stem` and `Hits` in descending order.
```sql
ORDER BY cs-uri-stem, Hits
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_verbs.sql

## Results ##

Since only successful requests are processed, use the following to build a whitelist of verbs for this Request Filtering setting.

* Verify the `verb` used with each `cs-uri-stem` is valid. Generally, requests using anything other than `GET` or `HEAD` should be looked into.
* If `GET` is allowed so should `HEAD`
* Avoid `TRACE`
* Consider implementing the `Access-Control-Allow-Methods` response header containing the whitelisted HTTP verbs.
