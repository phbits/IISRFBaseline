function Get-RFLpQueryMaxUrlIIS
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF verbs baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryMaxUrlIIS -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_maxUrl_IIS.csv'

    return @"
--lp_query_maxUrl_IIS.sql--

SELECT DISTINCT 
    cs-uri-stem as Path,
    STRLEN(cs-uri-stem) AS PathLength

INTO $ResultFile

FROM $LogDir

WHERE 
    s-sitename LIKE `'$sitename`'
    AND (sc-status<$MaxHttp AND sc-status>=200)

GROUP BY Path

ORDER BY PathLength DESC

--lp_query_maxUrl_IIS.sql--
"@

} # End function Get-RFLpQueryMaxUrlIIS

function New-RFLpFileMaxUrlIIS
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF maxUrl baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileMaxUrlIIS -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_maxUrl_IIS.sql'

    Get-RFLpQueryMaxUrlIIS -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir -MaxHttp $MaxHttp | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileMaxUrlIIS

Export-ModuleMember -Function 'Get-RFLpQueryMaxUrlIIS','New-RFLpFileMaxUrlIIS'
