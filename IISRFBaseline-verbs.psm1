function Get-RFLpQueryVerbs
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF verbs baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryVerbs -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_verbs.csv'

    return @"
--lp_query_verbs.sql--

SELECT DISTINCT 
    cs-method AS verb,
    cs-uri-stem,
    COUNT(*) AS Hits

INTO $ResultFile

FROM $LogDir

WHERE 
    s-sitename LIKE `'$sitename`'
    AND (sc-status<$MaxHttp AND sc-status>=200)

GROUP BY verb, cs-uri-stem

ORDER BY cs-uri-stem, Hits

--lp_query_verbs.sql--
"@

} # End function Get-RFLpQueryVerbs

function New-RFLpFileVerbs
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF verbs baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileVerbs -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_verbs.sql'

    Get-RFLpQueryVerbs -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir -MaxHttp $MaxHttp | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileVerbs

Export-ModuleMember -Function 'Get-RFLpQueryVerbs','New-RFLpFileVerbs'
