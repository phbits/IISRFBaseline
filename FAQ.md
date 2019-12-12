# IISRFBaseline FAQ #

* [Why use Request Filtering](#why-use-request-filtering)
* [Request Filtering Limitations](#request-filtering-limitations)
* [Why not Fully Automated](#why-not-fully-automated)
* [File System vs IIS Logs](#file-system-vs-iis-logs)
* [Logparser Installation](#logparser-installation)
* [Large or Mixed Websites](#large-or-mixed-websites)
* [Why s-sitename over cs-host](#why-s-sitename-over-cs-host)
* [Reserved Characters](#reserved-characters)
* [What are Successful Requests](#what-are-successful-requests)
* [Required Permissions](#required-permissions)
* [Determine s-sitename](#determine-s-sitename)
* [Updating web.config](#updating-webconfig)
* [Microsoft Documentation](#microsoft-documentation)
* [Manually Launching Logparser Query](#manually-launching-logparser-query)
* [File Uploads or Large Requests](#file-uploads-or-large-requests)

## Why use Request Filtering ##

The IIS Request Filtering module is processed ***very*** early in the request pipeline. Unwanted requests are quickly discarded before proceeding to application code which is slower and has a much larger attack surface. For this reason, some have reported performance increases after implementing Request Filtering settings.

## Request Filtering Limitations ##

1. **Stateless** - Request Filtering has no knowledge of application or session state. Each request is processed individually regardless of whether a session has or has not been established.
2. **Request Header Only** - Request Filtering can only inspect the request header. It has no visibility into the request body or any part of the response.
3. **Basic Logic** - Regular expressions and wildcard matches are not available. Most settings consist of establishing size constraints while others perform simple string matching.

To mitigate, consider placing a [Web Application Firewall (WAF)](https://en.wikipedia.org/wiki/Web_application_firewall) in front of IIS. This solution will have full access to every part of the request.

For something in between the basic functionality of Request Filtering and the full functionality of a Web Application Firewall, consider the Microsoft IIS module [URL Rewrite](https://www.iis.net/downloads/microsoft/url-rewrite). It doesn't have visibility into the request/response body but has regex and wildcard functionality to work with headers. It can also provide custom responses and much much more.

## Why not Fully Automated ##

There are far too many variables in IIS hosted websites to address all use cases. Some may be straight MVC and others serve only static content. While those two scenarios are much easier to diagnose; the difficulty is when they're mixed together with virtual directories or use custom logic.

This PowerShell module uses an approach which casts a wide net allowing the user to make necessary judgment calls based on how the Logparser queries are constructed.

## File System vs IIS Logs ##

These are the two techniques used to baseline a website and each has pros and cons. Understanding the details will allow for a better understanding of how the baselines are generated.

#### 1. File System ####

This technique is ideal for websites serving static content. Examples include straight html, css, and js. Each file should directly correlate with how it is requested as shown by the following example. If there is content rarely accessed, it will still get included in the baseline. Websites built from .dll files should focus on results using the IIS logs. However ASP.Net Web Forms can benefit from this approach as long as they too follow the example below.

    File Path: 	\\server.contoso.com\website\css\main.css
    Web Path: 	  http://website.contoso.com/css/main.css

#### 2. IIS Logs ####

Ideal when the website is an application built from `.dll` files (e.g. MVC, WebAPI) since requests do not correlate to an actual file (as described above). The downside of this approach is every possible request needs to have been made in order to be included in the baseline. It is for this reason one should get more than a year's worth of logs to account for any peak traffic and rarely requested resources.

Additionally, only successful requests are processed. See "What are Successful Requests?" (further down) for details.

## Logparser Installation ##

A full installation of Microsoft Logparser is not required to run this module. It only needs access to `Logparser.exe` and `Logparser.dll`. 

`Invoke-IISRFBaseline` has a `-LogparserPath` switch to specify the folder where these two files reside.

## Large or Mixed Websites ##

Large or mixed websites may have directories of static content and applications residing in virtual directories. Note that Request Filtering settings can be placed at that level instead of the website root. This will be a far better approach then trying to enforce a one-size-fits-all baseline at the website root.

## Why s-sitename over cs-host ##

The IIS log field `s-sitename` is used because it identifies all content served by the target website. A website can be bound to multiple domain names which get logged in the `cs-host` IIS log field.

To illustrate this, the following Logparser query (after updating the IIS log location) will show if multiple `cs-host` values are bound to a single website.

    Logparser.exe -i:IISW3C "SELECT DISTINCT s-sitename, cs-host INTO Datagrid from D:\IIS-Log-Folder\u_ex*.log GROUP BY s-sitename, cs-host ORDER BY s-sitename"

Alternatively, run `GetIISSite` on the server running IIS to show website bindings.

## Reserved Characters ##

Robert McMurray has a great post referencing [RFC2396 section 2.2](https://tools.ietf.org/html/rfc2396#section-2.2) and explaining how IIS handles reserved characters. In short, avoid using these in characters in the `Path` (what is logged in the `cs-uri-stem` field).

    reserved    = ";" | "/" | "?" | ":" | "@" | "&" | "=" | "+" | "$" | ","

> Ref: https://blogs.iis.net/robert_mcmurray/bad-characters-to-use-in-web-based-filenames

## What are Successful Requests ##

Successful requests are deemed as anything with an HTTP response code in the range: 200-302. The most common is an HTTP `200` which signifies a successful request while an HTTP `301` or `302` are used for redirects. The Logparser query line for this is `sc-status<303 AND sc-status>=200`. Note that HTTP `300` response code is considered a successful request. This is done because it's use is extremely rare and it greatly simplifies the script logic.

A caveat to this approach is if the target website requires authentication and an internet scanner requests a nonexistent resource. The response will be a redirect to the login page even though the originally requested resource does not exist.

    Request:  GET /folder/index.php
    Response: HTTP 302 Found 
              Location: /Account/Login.aspx?ReturnUrl=/folder/index.php

Since the response code was an HTTP `302`, it will be considered a successful request. If this is the case, consider using the `-ExcludeRedirects` switch. Then only HTTP `200-299` responses will be processed. The following Logparser query line is used to achieve this: `sc-status<300 AND sc-status>=200`. However, taking this approach now means that a successful login will not show up in the results since the HTTP response code is `302`. Thus stressing the importance of knowing how the website functions and reviewing the results.

If the target application needs to account for additional HTTP response codes or one-off scenarios, consider taking an adhoc approach by updating the Logparser query file and then run the Logparser command according to the setting's documentation.

## Required Permissions ##

* Read & Write - Working Directory - this is where query files and results are saved.
* Read - IIS Logs and Website content directory.
* Read & Execute - Logparser needs to be able to function.

## Determine s-sitename ##

There are two ways to determine the `s-sitename` for a website: check IIS directly or check the IIS logs.

#### 1. Check IIS ####

1. Run `Get-IISSite` on the server running IIS. It will display all the websites, their bindings and most importantly the `id`.
2. Now append the ID to W3SVC to get the `s-sitename`.

> Example: a website ID of `3` would have an s-sitename of `W3SVC3`

#### 2. Check IIS logs ####

Run the following Logparser query against the IIS logs after updating the IIS log location (`D:\IIS-Log-Folder\u_ex*.log`). It will display all unique instances of `s-sitename` paired with `cs-host`.

```
    Logparser.exe -i:IISW3C "SELECT DISTINCT s-sitename, cs-host INTO Datagrid from D:\IIS-Log-Folder\u_ex*.log GROUP BY s-sitename, cs-host ORDER BY s-sitename, cs-host"
```

## Updating web.config ##

[Microsoft documentation](https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/requestfiltering/) provides examples using the following methods for updating settings.

* IIS Manager MMC
* XML
* AppCmd.exe
* PowerShell
* C#
* VB.NET
* JavaScript
* VBScript

## Microsoft Documentation ##

https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/requestfiltering/

## Manually Launching Logparser Query ##

When manually running Logparser queries consider excluding the `-stats:OFF` and `-q:ON` switches. This will return the stats back to the command line. 

```
Example: LogParser.exe -i:IISW3C -o:CSV file:D:\WorkingFolder\lp_query_RF-Setting.sql
```

## File Uploads or Large Requests ##

When accepting file uploads or large requests, the following settings may need to be adjusted. While they’re not part of the Request Filtering module, they are closely related to `maxAllowedContentLength`.

### httpRuntime ###

Configures the ASP.NET HTTP runtime and thus only applicable to application pools running .NET. While many settings are similar to Request Filtering, these thresholds are checked much later in the IIS request pipeline. The setting `MaxRequestLength` is an `Int32` specified in `KB`. Note the difference of this setting being in `KB` while most other settings are specified in bytes.

Default: 4096 KB (4 MB)

```xml
<system.web>
	<httpRuntime maxRequestLength="4096" />
</system.web>
```

Reference: https://docs.microsoft.com/en-us/dotnet/api/system.web.configuration.httpruntimesection

### Website Limits ###

The defaults are quite generous though the setting of concern is `connectionTimeout`. This is because `http.sys` will continue to accept the HTTP request payload (e.g. an uploaded file), that may even exceed size limits, until this timeout expires. Consider lowering to something more inline with the target demographic. This setting will not impact active connections as described in the following example. 

***Example:*** When a file (or large HTTP payload) exceeds the allowable size, IIS will respond with the appropriate HTTP status code (`404` or `413`) and set the `FIN` flag on the TCP connection. The `FIN` flag is what starts this timer. This is important because `http.sys` will continue to allow the upload until this timer expires. If the upload "completes", the client will see the HTTP response code (`404` or `413`). If the upload exceeds the timeout, IIS responds to the TCP connection using the `RST` flag which closes the TCP connection. The client will then see a broken connection error page.

This (mis)configuration could lead to a denial of service scenario where a large request payload is allowed for the duration of this timeout. The reason active connections are not impacted by this setting is because the timer is only triggered when one of the TCP endpoints attempts to close a connection.

See this [Stackoverflow post](https://stackoverflow.com/questions/55126110/does-iis-request-content-filtering-load-the-full-request-before-filter/59217102#59217102) for more.

Default: 2 minutes

```xml
<system.applicationHost>
   <sites>
      <siteDefaults>
         <limits connectionTimeout="00:02:00" />
      </siteDefaults>
   </sites>
</system.applicationHost>
```

Reference: https://docs.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/sitedefaults/limits
