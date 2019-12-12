# maxAllowedContentLength #

This request limit setting of Request Filtering checks the value of the `Content-Length` request header. If the value in the request header exceeds what is set for `maxAllowedContentLength`, an HTTP `404` (Not found) or `413` (Request entity too large) is returned. To confirm which module is responding to the request use Failed Request Tracing.

Triggering this limit is a hard fail since the client receives an HTTP 404 (Not Found) or 413 (Request entity too large). In some cases, the TCP connection is closed by IIS responding with the RST flag set. If your website accepts file uploads or form submissions, consider performing client-side input validation to prevent legitimate client requests from triggering this hard fail.

For more details about file uploads or large requests, see ***File Uploads or Large Requests*** in the FAQ.

STIG recommends a value of `30000000` or less (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76819).

## Content-Length ##

This request header is most often used during `POST` requests where the client will include data in the request body. It can range from logon credentials (username/password), form submissions, file uploads, etc. The client performing this action, often the browser, will calculate the size of the request body in bytes and update this header with the appropriate value. 

The following is a simplified example showing a `POST` request using "`abc`" (without quotes) in the request body and thus `Content-Length=3`. This request would be blocked if `maxAllowedContentLength=2` (or lower).
```
POST /UploadSvc HTTP/1.1
Host: mvc.contoso.com
Content-Length: 3

abc
```

The following is a more realistic scenario where a client HTTP POST is captured via Microsoft Network Monitor (netmon). The arrow shows `Content-Length=25` and it can also be seen in the "Hex Details" (right pane). The actual request body is highlighted in blue which consists of "`inputOne=ONE&inputTwo=TWO`" (without quotes). Each character is a single byte resulting in `Content-Length=25`. The minimum value to still allow this request would be `maxAllowedContentLength=25`.

![maxAllowedContentLength-screenshot-1](https://img.phbits.com/86067d849375/maxAllowedContentLength-1-md.jpg)
 

## Establishing a Value ##

Microsoft Logparser will parse the IIS logs to produce a ballpark value since the `Content-Length` header is not natively logged by IIS. The original request gets partially reconstructed and those bytes are subtracted from `cs-bytes`. Details about this process are below.

Only successful requests are included in the results. See ***Successful Requests*** in the FAQ for details.

IIS Logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## cs-bytes ##

The `cs-bytes` IIS log field is used for establishing this setting since IIS doesn’t natively log the `Content-Length` header. Unfortunately, `cs-bytes` represents ALL bytes sent in an HTTP request which includes the entire request header. To add to this, some clients are more verbose than others when it comes to request headers which can really throw off the baseline. To better illustrate this, the following netmon capture is displaying a basic HTTP POST request. The arrow shows the value that will appear in the `cs-bytes` field for this request. Note that in the "Hex Details" pane (right side) the entire HTTP request is highlighted. Even though the request body is only 25 bytes (`Content-Length: 25`), the `cs-bytes` value is `456`. Now consider if additional headers were included such as cookies. That `456` bytes could easily grow to be quite large while the request body remains at `Content-Length=25`.

 ![maxAllowedContentLength-screenshot-2](https://img.phbits.com/86067d849375/maxAllowedContentLength-2-md.jpg)

## Improving on cs-bytes ##

While IIS does not natively log all request headers it does log the most verbose request headers: `User-Agent`, `Referer`, `Cookie`. Using fields which are logged, the original request can be partially reconstructed and then subtracted from cs-bytes. Though not exact, it will provide a far more precise value for this setting. If no value is logged by IIS, the request header is left out of the calculation. Below illustrates how the request header is reconstructed with IIS log fields enclosed in square brackets.
```
[cs-method] [cs-uri-stem]?[cs-uri-query] [cs-version]rn
Cookie: [cs(Cookie)]rn
Referer: [cs(Referer)]rn
User-Agent: [cs(User-Agent)]rn
Host: [cs-host]rn
rn
```

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_maxAllowedContentLength.sql--

SELECT 
    cs-bytes,
    SUB(cs-bytes,STRLEN(ReqLine4)) AS Adjusted-cs-bytes
USING	
    STRCAT(cs-uri-stem, REPLACE_IF_NOT_NULL(cs-uri-query, STRCAT('?',cs-uri-query))) AS ClientRequest, 
    STRCAT(cs-method, STRCAT(' ', STRCAT(ClientRequest, STRCAT(' ', STRCAT(cs-version, 'rn'))))) AS ReqLine0, 
    STRCAT(ReqLine0, REPLACE_IF_NOT_NULL(cs(Cookie), STRCAT('Cookie: ', STRCAT(cs(Cookie),'rn')))) AS ReqLine1, 
    STRCAT(ReqLine1, REPLACE_IF_NOT_NULL(cs(Referer), STRCAT('Referer: ', STRCAT(cs(Referer),'rn')))) AS ReqLine2, 
    STRCAT(ReqLine2, REPLACE_IF_NOT_NULL(cs(User-Agent), STRCAT('User-Agent: ', STRCAT(cs(User-Agent),'rn')))) AS ReqLine3, 
    STRCAT(ReqLine3, STRCAT('Host: ', STRCAT(cs-host, 'rnrn'))) AS ReqLine4
    
INTO D:\WorkingFolder\lp_results_maxAllowedContentLength.csv

FROM D:\folder\u_ex*.log

WHERE 
    s-sitename LIKE 'W3SVC3'
      AND (sc-status<303 AND sc-status>=200)
      AND (cs-method='POST' OR cs-method='PUT')

ORDER BY Adjusted-cs-bytes ASC

--lp_query_maxAllowedContentLength.sql--
```

Selects the `cs-bytes` field from the IIS log and calculates `Adjusted-cs-bytes` by subtracting the length of the rebuilt request (`ReqLine4`) from `cs-bytes`.
```sql
SELECT 
    cs-bytes, 
    SUB(cs-bytes,STRLEN(ReqLine4)) AS Adjusted-cs-bytes
```

Rebuilds the client request header using fields logged by IIS.
```sql
USING	
    STRCAT(cs-uri-stem, REPLACE_IF_NOT_NULL(cs-uri-query, STRCAT('?',cs-uri-query))) AS ClientRequest, 
    STRCAT(cs-method, STRCAT(' ', STRCAT(ClientRequest, STRCAT(' ', STRCAT(cs-version, 'rn'))))) AS ReqLine0, 
    STRCAT(ReqLine0, REPLACE_IF_NOT_NULL(cs(Cookie), STRCAT('Cookie: ', STRCAT(cs(Cookie),'rn')))) AS ReqLine1, 
    STRCAT(ReqLine1, REPLACE_IF_NOT_NULL(cs(Referer), STRCAT('Referer: ', STRCAT(cs(Referer),'rn')))) AS ReqLine2, 
    STRCAT(ReqLine2, REPLACE_IF_NOT_NULL(cs(User-Agent), STRCAT('User-Agent: ', STRCAT(cs(User-Agent),'rn')))) AS ReqLine3, 
    STRCAT(ReqLine3, STRCAT('Host: ', STRCAT(cs-host, 'rnrn'))) AS ReqLine4
```

Where results will be stored.
```sql
INTO D:\WorkingFolder\lp_results_maxAllowedContentLength.csv
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

The HTTP verbs `POST` and `PUT` requests are most often used with content in the request body.
```sql
AND (cs-method='POST' OR cs-method='PUT') 
```

Order everything by `Adjusted-cs-bytes`.
```sql
ORDER BY Adjusted-cs-bytes DESC
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_maxAllowedContentLength.sql

## Results ##

Charting is the best way to analyze this results file (`lp_results_maxAllowedContentLength.csv`). Doing so should show a plateau of `adjusted-cs-bytes` that is an acceptable value. Consider aiming a bit high for this setting since it creates a hard fail. Also verify that it does not interfere with any limits already in place at the website/application level. 

_For example_, if the developer set a file upload limit of 100MB in the application code, this setting should be slightly higher.
