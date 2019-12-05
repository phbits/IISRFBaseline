# allowHighBitCharacters_FS #

This Request Filtering (RF) setting checks if the URL Path (`cs-uri-stem`) contains a high bit (i.e. non-ASCII) character which is anything from `0x80` (128 decimal) and beyond. 

> Examples: €, ƒ, ©, ™, ®, Æ

If a request using a high bit character is denied by this setting, the client will receive an HTTP `404` and IIS will log an HTTP `404.12`.

If no results file is created (`lp_results_allowHighBitCharacters_FS.csv`), the target website is not using high bit characters in content file names.

STIG recommends disabling this functionality (https://stigviewer.com/stig/iis_8.5_site/2019-01-08/finding/V-76823).

## Identifying High Bit Characters ##

This technique is best for websites comprised of static content (e.g. .html, .css, .js, .jpg, .pdf, etc.). Microsoft Logparser is used to search the content directory and identify files/folders using a high bit character in their name. 

The following is an example of a company PDF using the Copyright sign (`©`) and how the URL correlates with the content share.

    Website URL   : http://www.contoso.com/docs/contoso©.pdf
    Encoded URL   : http://www.contoso.com/docs/contoso%A9.pdf
    Content Share : \\server.contoso.com\www.contoso.com\docs\contoso©.pdf

File System is used for this script. See ***File System vs. IIS Logs*** in the FAQ for details.

## LogParser Script ##

Each file name will be passed into the `URLESCAPE()` function to determine if a high bit (i.e. non-ASCII) character is being used.

Below is an example LogParser query to be used and explanation as to what it does.

```sql
--lp_query_allowHighBitCharacters_FS.sql--

SELECT 
    Path,
    Name,
    URLESCAPE(Name) AS EncodedName

INTO D:\WorkingFolder\lp_results_allowHighBitCharacters_FS.csv

FROM \\server.contoso.com\www.contoso.com\*

WHERE 
    EncodedName LIKE '%\%8%' OR
    EncodedName LIKE '%\%9%' OR
    EncodedName LIKE '%\%a%' OR
    EncodedName LIKE '%\%b%' OR
    EncodedName LIKE '%\%c%' OR
    EncodedName LIKE '%\%d%' OR
    EncodedName LIKE '%\%e%' OR
    EncodedName LIKE '%\%f%'
    
--lp_query_allowHighBitCharacters_FS.sql--
```

Selects the full path to the file/folder, the name, and the result of performing `URLESCAPE()` on the name.
```sql
SELECT 
    Path,
    Name,
    URLESCAPE(Name) AS EncodedName
```

Where results will be stored only if matches are found.
```sql
INTO D:\WorkingFolder\lp_results_allowHighBitCharacters_FS.csv
```

Location of website content directory.
```sql
FROM \\server.contoso.com\www.contoso.com\*
```

Since a high bit character (i.e. non-ASCII) is anything encoded as `%80` and above, the following identifies any such occurrence in the `EncodedName`.
```sql
WHERE 
    EncodedName LIKE '%\%8%' OR
    EncodedName LIKE '%\%9%' OR
    EncodedName LIKE '%\%a%' OR
    EncodedName LIKE '%\%b%' OR
    EncodedName LIKE '%\%c%' OR
    EncodedName LIKE '%\%d%' OR
    EncodedName LIKE '%\%e%' OR
    EncodedName LIKE '%\%f%' 
```

## Launch LogParser Script ##

The PowerShell Module launches the following command.

    LogParser.exe -stats:OFF -q:ON -i:FS -preserveLastAccTime:ON -o:CSV file:D:\WorkingFolder\lp_query_allowHighBitCharacters_FS.sql

## Results ##

Results file (`lp_results_allowHighBitCharacters-FS.csv`) will only be created if there is a file or folder in the website content directory using a high bit character in the name. If one is found, will it ever be requested by a client? If the answer is yes, then leave this setting enabled regardless of the `allowHighBitCharacters-IIS` results.
