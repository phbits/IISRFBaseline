function Get-RFLpQueryMaxQueryString
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF maxQueryString baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryMaxQueryString -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # IIS Sitename of target website.
        $Sitename
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # IIS log directory.
        $LogDir
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # Outut directory for writing files.
        $OutputDir
        ,
        [parameter(Mandatory=$true)]
        [System.Int32]
        # Max HTTP Status Code
        $MaxHttp
    )

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_maxQueryString.csv'

    return @"
--lp_query_maxQueryString.sql--

SELECT DISTINCT 
    cs-uri-stem,
    cs-uri-query,
    STRLEN(cs-uri-query) AS QueryLength

INTO $ResultFile

FROM $LogDir

WHERE
    s-sitename LIKE `'$Sitename`'
    AND cs-uri-query LIKE `'%`'
    AND (sc-status<$MaxHttp AND sc-status>=200)

GROUP BY cs-uri-stem, cs-uri-query

ORDER BY QueryLength DESC

--lp_query_maxQueryString.sql--
"@

} # End function Get-RFLpQueryMaxQueryString

function New-RFLpFileMaxQueryString
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF maxQueryString baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileMaxQueryString -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # IIS Sitename of target website.
        $Sitename
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # IIS log directory.
        $LogDir
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # Outut directory for writing files.
        $OutputDir
        ,
        [parameter(Mandatory=$true)]
        [System.Int32]
        # Max HTTP Status Code
        $MaxHttp
    )

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_maxQueryString.sql'

    Get-RFLpQueryMaxQueryString -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir -MaxHttp $MaxHttp | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileMaxQueryString

Export-ModuleMember -Function 'Get-RFLpQueryMaxQueryString','New-RFLpFileMaxQueryString'
