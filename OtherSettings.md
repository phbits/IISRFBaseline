# Other Settings #

This page provides additional documentation for other Request Filtering settings.

* [Hidden Segments](#hidden-segments)
* [alwaysAllowedUrls](#alwaysallowedurls)
* [denyUrlSequences](#denyurlsequences)
* [alwaysAllowedQueryStrings](#alwaysallowedquerystrings)
* [denyQueryStringSequences](#denyquerystringsequences)
* [requestLimits](#requestlimits)
* [filteringRules](#filteringrules)
* [removeServerHeader](#removeserverheader)
* [Microsoft Documentation](#microsoft-documentation)

## Hidden Segments ##

A great way to protect files and folders that should never be requested by a client though are part of the website/application. Any request referencing these locations will get an HTTP `404` response. 

Example uses for this setting include:

* `web.config`
* `bin`
* `app_code`
* `app_data`
* `.gitignore`
* `.git`
* `.vs`

## alwaysAllowedUrls ##

Allow specific URL Paths (`cs-uri-stem`) regardless of other Request Filtering settings.

For example, `maxUrl=0` could be set blocking all requests yet an explicitly allowed entry will still be returned.

## denyUrlSequences ##

Block specific URL Paths (`cs-uri-stem`) regardless of other Request Filtering settings.

## alwaysAllowedQueryStrings ##

Similar to the `alwaysAllowedUrls` setting (above) however this setting does not take precedence over other settings. 

For example, a specified query string added to this list cannot be used to bypass request filtering settings. Other settings take precedence.

## denyQueryStringSequences ##

Similar to the `denyUrlSequences` setting (above) however this setting does not take precedence over other settings.

## requestLimits ##

`requestLimits` includes three settings greatly documented by this module: `maxAllowedContentLength`, `maxUrl`, `maxQueryString` Additionally there is functionality to place size limits on headers. 

When a client request exceeds a header limit value an `HTTP 431 Request Header Fields Too Large` is returned. Not the typical Request Filtering response.

In the following example, the `User-Agent` header has a max size limit of `2048`.

```xml
<requestLimits>
    <headerLimits>
        <add header="User-Agent" sizeLimit="2048" />
    </headerLimits>
</requestLimits>
```

## filteringRules ##

Performs string matching on all or some of the following:

* `cs-uri-stem`
* `cs-uri-query`
* Specified Header Fields

#### Example 1 ####

Block requests with `User-Agent: InternetScanner`.

```xml
<filteringRules>
    <filteringRule name="BlockUserAgent" scanUrl="false" scanQueryString="false">
        <scanHeaders>
            <add requestHeader="User-Agent" />
        </scanHeaders>
        <denyStrings>
            <add string="InternetScanner" />
        </denyStrings>
    </filteringRule>
</filteringRules>
```

#### Example 2 ####

If your website utilizes query parameters for SQL commands (*not recommended*), there is a great Microsoft blog post by Wade Hilmo titled [Filtering for SQL Injection on IIS 7 and later](https://blogs.iis.net/wadeh/filtering-for-sql-injection-on-iis-7-and-later). Below is the `filteringRule` from that post showing how to filter SQL injection commands from the query string. Again, while this technique of interfacing with a database is not recommended it does illustrate a great way to leverage `filteringRules`.

```xml
<filteringRules>
    <filteringRule name="SQLInjection" scanQueryString="true">
        <appliesTo>
            <add fileExtension=".asp" />
            <add fileExtension=".aspx" />
        </appliesTo>
        <denyStrings>
            <add string="--" />
            <add string=";" />
            <add string="/*" />
            <add string="@" />
            <add string="char" />
            <add string="alter" />
            <add string="begin" />
            <add string="cast" />
            <add string="create" />
            <add string="cursor" />
            <add string="declare" />
            <add string="delete" />
            <add string="drop" />
            <add string="end" />
            <add string="exec" />
            <add string="fetch" />
            <add string="insert" />
            <add string="kill" />
            <add string="open" />
            <add string="select" />
            <add string="sys" />
            <add string="table" />
            <add string="update" />
        </denyStrings>
    </filteringRule>
</filteringRules>
```

## removeServerHeader ##

Only available on IIS 10+. Removes the `Server` response header.

```xml
<configuration>
    <system.webServer>
        <security>
            <requestFiltering removeServerHeader="true">
            </requestFiltering>
        </security>
    </system.webServer>
</configuration>
```

## Microsoft Documentation ##

https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/requestfiltering/
