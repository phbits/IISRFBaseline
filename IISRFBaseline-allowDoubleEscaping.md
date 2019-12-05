# allowDoubleEscaping #

This Request Filtering setting checks whether the URL Path (`cs-uri-stem`) of the request has been URL encoded twice. 

Client requests which trigger this setting will receive an HTTP `404` while IIS will log it as an HTTP `404.11`. 

To identify requests using this technique, an unescaped `cs-uri-stem` is compared to a `cs-uri-stem` that is unescaped twice. If the two values are different, the request is flagged for using double escaping.

If no results file is created (`lp_results_allowDoubleEscaping.csv`), the target website has not received a request using the double escaping technique.

Additional points worth mentioning about this setting.

1.	There is documentation recommending this setting be enabled for Active Directory Certificate Services, Exchange and SharePoint.
2.	STIG recommends disabling this functionality (https://stigviewer.com/stig/iis_8.5_site/2018-09-18/finding/V-76825).
3.	Use of the plus sign (`+`) is often why this setting needs to be left enabled. This is cause for confusion since it is a reserved character according to [RFC2396 section 2.2](https://tools.ietf.org/html/rfc2396#section-2.2). See the FAQ entry ***Reserved Characters*** for details.

## URL Encoding ##

URL encoding, also known as [Percent-Encoding](https://tools.ietf.org/html/rfc3986#section-2.1), is the substitution of a character with its hexadecimal equivalent and replacing the hexadecimal indicator of `0x` with a percent sign `%`.

The following URL contains a space between the word "some" and "file". 

    http://www.contoso.com/folder/some file.html

URL encoding will substitute the space with its hexadecimal representation `0x20` which then becomes `%20` using percent encoding.
    
    http://www.contoso.com/folder/some%20file.html

## What is Double Escaping ##

As the name suggests, double escaping is the process of URL encoding an already encoded path. This involves replacing the percent (`%`) with "`%25`" (without quotes).

Using the prior example, we have our URL encoded request.

    http://www.contoso.com/folder/some%20file.html

The hexadecimal representation of a percent sign (`%`) is `0x25` which becomes `%25` using percent encoding.

    http://www.contoso.com/folder/some%2520file.html

## How IIS Identifies Double Escaping ##

Normalizing or unescaping is the process of resolving percent encoded values. This technique is used by IIS to identify double escaping and best explained by the following examples.

#### Example 1 ####

The client sends the following request which is not double escaped. The normalized URL path is compared to a URL path that has been normalized twice. Since the two normalized URL paths return the same value, the request is not double escaped.

    Client Request   : http://www.contoso.com/folder/file%28copy%29.html
    Normalized Once  : http://www.contoso.com/folder/file(copy).html
    Normalized Twice : http://www.contoso.com/folder/file(copy).html

#### Example 2 ####

The client sends the following request which is using double escaping. The normalized URL path is different from the twice normalized URL path. Thus triggering this setting.

    Client Request   : http://www.contoso.com/folder/file%2528copy%2529.html
    Normalized Once  : http://www.contoso.com/folder/file%28copy%29.html
    Normalized Twice : http://www.contoso.com/folder/file(copy).html

## Identify Double Escaping ##

Microsoft Logparser is used to parse the IIS logs of the target website/application. Each request URL Path (`cs-uri-stem`) is normalized once and then normalized twice. If the two normalized results are different, then double escaping was used for that request.

This Logparser query will return any requests using the double escaping technique (HTTP `404.11`). This means requests from vulnerability scanners may appear in the results. Leverage the additional fields to determine whether the requests are legitimate.

IIS logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_allowDoubleEscaping.sql--

SELECT 
    date,
    time,
    c-ip,
    cs-host,
    sc-status,
    sc-substatus,
    cs-uri-stem,
    URLUNESCAPE(cs-uri-stem) AS Normalized1,
    URLUNESCAPE(Normalized1) AS Normalized2,
    cs(User-Agent)

INTO D:\WorkingFolder\lp_results_allowDoubleEscaping.csv

FROM D:\folder\u_ex*.log

WHERE 
    s-sitename LIKE 'W3SVC3'
    AND (Normalized1<>Normalized2 
        OR (sc-status=404 AND sc-substatus=11))
    AND NOT ((sc-status=400 AND sc-substatus=0)
        OR (sc-status=404 AND sc-substatus=0))

--lp_query_allowDoubleEscaping.sql--
```

The select statement returns multiple IIS log fields to better distinguished a legitimate request from what can be considered vulnerability scanners.
```sql
SELECT 
    date,
    time,
    c-ip,
    cs-host,
    sc-status,
    sc-substatus,
    cs-uri-stem,
    URLUNESCAPE(cs-uri-stem) AS Normalized1,
    URLUNESCAPE(URLUNESCAPE(cs-uri-stem)) AS Normalized2,
    cs(User-Agent)
```

Where results will be stored if matches are found.
```sql
INTO D:\WorkingFolder\lp_results_allowDoubleEscaping.csv
```

Location of the IIS logs.
```sql
FROM D:\folder\u_ex*.log
```

Specifies the target IIS website.
```sql
WHERE s-sitename LIKE 'W3SVC3' 
```

This portion of the logparser query will check for double escaping, using the same technique as IIS, by identifying when the two normalized results are different. We also include any requests blocked because of this setting (HTTP `404.11`).
```sql
AND (Normalized1<>Normalized2 OR (sc-status=404 AND sc-substatus=11))
```

Exclude Bad Requests (HTTP `400.0`) and actual File Not Found (HTTP `404.0`). This excludes much traffic from internet vulnerability scanners.
```sql
AND NOT ((sc-status=400 AND sc-substatus=0) OR (sc-status=404 AND sc-substatus=0))
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_allowDoubleEscaping.sql

## Results ##

Results file (`lp_results_allowDoubleEscaping.csv`) will only be created if a request has been made to the target website using the double escaping technique. If there is a results file, use the following to determine if this setting should be enabled.

* Vulnerability Scanners - Most common source of this technique. Check the `c-ip` and `cs(User-Agent)` fields to determine if this is the case. In-house vulnerability scanners are easily detectable this way. For internet scanners, the friendly ones will declare themselves via `cs(User-Agent)` or a Reverse DNS lookup of `c-ip`. To rule out unfriendly scanners, check across all fields to see if the request looks to be valid. Also check if the `date` and `time` between requests seems to be automated or made by an actual human.
* Actual Client Requests - with vulnerability scanners ruled out, research the actual client request to determine if it is device specific (e.g. tablet, mobile, etc.) or browser/app specific. Is it handlining a link improperly or a URL directly typed in? Can either be fixed allowing this setting to be disabled?
