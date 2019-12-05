# allowHighBitCharacters_IIS #

This Request Filtering (RF) setting checks if the URL Path (`cs-uri-stem`) contains a high bit (i.e. non-ASCII) character which is anything from `0x80` (128 decimal) and beyond. 

> Examples: €, ƒ, ©, ™, ®, Æ

If a request using a high bit character is denied by this setting, the client will receive an HTTP `404` and IIS will log an HTTP `404.12`.

If no results file is created (`lp_results_allowHighBitCharacters_IIS.csv`), the target website has not received a request using high bit characters.

STIG recommends disabling this functionality (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76823).

## Identifying High Bit Characters via IIS Logs	##

This technique is best for a target website/application that dynamically generates URLs (e.g. MVC and WebAPI). Microsoft Logparser will parse the IIS logs to identify requests using high bit characters.

Requests blocked by this setting (HTTP `404.12`) will be included in the results. Leverage the additional fields to determine whether the requests are legitimate as described in the "Results" section.

IIS Logs are used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

The following is an example of a company PDF using the Copyright sign (`©`) and how the URL correlates with the content share.

    Website URL   : http://www.contoso.com/docs/contoso©.pdf
    Encoded URL   : http://www.contoso.com/docs/contoso%A9.pdf
    Content Share : \\server.contoso.com\www.contoso.com\docs\contoso©.pdf

## LogParser Script ##

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_allowHighBitCharacters_IIS.sql--

SELECT 
    date,
    time,
    c-ip,
    cs-host,
    sc-status,
    sc-substatus,
    cs-uri-stem,
    URLESCAPE(cs-uri-stem) AS EncodedURL,
    cs(User-Agent)

INTO D:\WorkingFolder\lp_results_allowHighBitCharacters_IIS.csv

FROM D:\folder\u_ex*.log

WHERE 
    s-sitename LIKE 'W3SVC3’
    AND (EncodedURL LIKE '%\%8%' OR
        EncodedURL LIKE '%\%9%' OR
        EncodedURL LIKE '%\%a%' OR
        EncodedURL LIKE '%\%b%' OR
        EncodedURL LIKE '%\%c%' OR
        EncodedURL LIKE '%\%d%' OR
        EncodedURL LIKE '%\%e%' OR
        EncodedURL LIKE '%\%f%' OR
        (sc-status=404 AND sc-substatus=12))
    AND NOT ((sc-status=400 AND sc-substatus=0) 
        OR (sc-status=404 AND sc-substatus=0))

--lp_query_allowHighBitCharacters_IIS.sql--
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
    URLESCAPE(cs-uri-stem) AS EncodedURL,
    cs(User-Agent)
```

Where results will be stored only if matches are found.
```sql
INTO D:\WorkingFolder\lp_results_allowHighBitCharacters_IIS.csv
```

Location of the IIS logs.
```sql
FROM D:\folder\u_ex*.log
```

Specifies the target IIS website.
```sql
WHERE s-sitename LIKE 'W3SVC3' 
```

With a high bit character (i.e. non-ASCII) defined as anything encoded as `%80` and above, return an EncodedURL containing: `%8`, `%9`, `%a`, `%b`, `%c`, `%d`, `%e`, `%f`.
```sql
AND (EncodedURL LIKE '%\%8%' OR
    EncodedURL LIKE '%\%9%' OR
    EncodedURL LIKE '%\%a%' OR
    EncodedURL LIKE '%\%b%' OR
    EncodedURL LIKE '%\%c%' OR
    EncodedURL LIKE '%\%d%' OR
    EncodedURL LIKE '%\%e%' OR
    EncodedURL LIKE '%\%f%' OR
```

Additionally return any requests having been blocked by this setting which is an HTTP `404.12`.
```sql
(sc-status=404 AND sc-substatus=12))
```

Exclude Bad Requests (HTTP `400.0`) and actual File Not Found (HTTP `404.0`). This excludes much traffic from internet vulnerability scanners.
```sql
AND NOT ((sc-status=400 AND sc-substatus=0) OR (sc-status=404 AND sc-substatus=0))
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_allowHighBitCharacters_IIS.sql

## Results ##

Results file (`lp_results_allowHighBitCharacters-IIS.csv`) will only be created if one or more requests have been made to the target website using a high bit (i.e. non-ASCII) character in the path (`cs-uri-stem`). If there is a results file, use the following to determine if this setting should be enabled.

* Vulnerability Scanners - Most common sources of this technique. Check the `c-ip` and `cs(User-Agent)` fields to determine if this is the case. In-house vulnerability scanners are easily detectable this way. For internet scanners, the friendly ones will declare themselves via `cs(User-Agent)` or a Reverse DNS lookup of `c-ip`. To rule out unfriendly scanners, check across all fields to see if the request looks to be valid. Also check if the `date` and `time` between requests seems to be automated or made by an actual human.
* Actual Client Requests - with vulnerability scanners ruled out, research the actual client request to determine if it is device specific (e.g. tablet, mobile, etc.) or browser/app specific. Is it handlining a link improperly or a URL directly typed in? Can either be fixed allowing this setting to be disabled? 
* Target Resource - Is the target resource a file or an application method? Can it be renamed to disable this setting?
