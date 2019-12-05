# maxQueryString #

This request limit setting of Request Filtering enforces a maximum length for the [query](https://tools.ietf.org/html/rfc3986#section-3). IIS stores the value in the `cs-uri-query` log field. 

This limit a hard fail since the client will only see an HTTP 404 (Not Found) which is not indicative of why the request failed. Exercise caution when setting this value if your website/application makes significant use of query parameters.

When a request is blocked by this setting, an HTTP `404` is returned to the client and IIS logs an HTTP `404.15`.

STIG recommends a value of `2048` or less (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76821).

## No Query Normalizing ##

IIS does not normalize the query. If URL encoding is being used, the query length will be checked "as is" with each character being a single byte.

#### Example 1 ####

The following is a basic example with no URL encoding. The minimum value to allow this request: `maxQueryString = 28`

    http://www.contoso.com/SignUp.html?firstname=Test&lastname=User

#### Example 2 ####

This example uses a firstname value with a space in it, "`Test One`". The request is encoded which substitutes the space with `%20`. IIS does not normalize the query, leaving it as is. The minimum value to allow this request: `maxQueryString = 34`

    http://www.contoso.com/SignUp.html?firstname=Test%20One&lastname=User

## Establishing a Value ##

Microsoft Logparser will parse the IIS logs of the target website/application to calculate the length of each query (`cs-uri-query`).

Only successful requests are included in the results. See ***Successful Requests*** in the FAQ for details.

IIS Logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_maxQueryString.sql--

SELECT DISTINCT 
    cs-uri-stem,
    cs-uri-query,
    STRLEN(cs-uri-query) AS QueryLength

INTO D:\WorkingFolder\lp_results_maxQueryString.csv

FROM D:\folder\u_ex*.log

WHERE
    s-sitename LIKE 'W3SVC3'
      AND cs-uri-query LIKE `'%`'
      AND (sc-status<303 AND sc-status>=200)

GROUP BY cs-uri-stem, cs-uri-query

ORDER BY QueryLength DESC

--lp_query_maxQueryString.sql--
```

Selects the `cs-uri-stem` and `cs-uri-query` field from the IIS log. The Logparser function `STRLEN()` is used to return the `cs-uri-query` length. 
```sql
SELECT DISTINCT
    cs-uri-stem,
    cs-uri-query,
    STRLEN(cs-uri-query) AS QueryLength
```

Where results will be stored.
```sql
INTO D:\WorkingFolder\lp_results_maxQueryString.csv
```

Location of the IIS logs for this website.
```sql
FROM D:\folder\u_ex*.log
```

Specifies the target IIS website.
```sql
WHERE s-sitename LIKE 'W3SVC3' 
```

Only select requests using query string parameters.
```sql
AND cs-uri-query LIKE `'%`'
```

We are only concerned with successful requests and thus targeting HTTP status codes in the `2XX` range as well as redirects of `301` or `302`.
```sql
AND (sc-status<303 AND sc-status>=200) 
```

Grouping by `cs-uri-stem` and `cs-uri-query` since a `SELECT DISTINCT` is being performed.
```sql
GROUP BY cs-uri-stem, cs-uri-query
```

Order by `QueryLength` to get the longest first.
```sql
ORDER BY QueryLength DESC
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_maxQueryString.sql

## Results ##

A results file (`lp_results_maxQueryString.csv`) will only be created if query string parameters are used.

Start with the top entry (i.e. longest `QueryLength`) and determine if it is a valid request. If so, use that `QueryLength` value for this setting. Otherwise continue working down the list until a valid request is found and use the corresponding `QueryLength` for this Request Filtering setting.

Reminder that this setting creates a hard fail so consider aiming a bit higher to account for any future changes.
