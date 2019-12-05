function Get-RFLpQueryFileExtensionsIIS
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF fileExtensions baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryFileExtensionsIIS -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_fileExtensions_IIS.csv'

    return @"
--lp_query_fileExtensions_IIS.sql--

SELECT DISTINCT 	
    cs-uri-stem,
    EXTRACT_EXTENSION(cs-uri-stem) AS Extension,
    COUNT(*) AS Hits

INTO $ResultFile

FROM $LogDir

WHERE 
    s-sitename LIKE `'$Sitename`'
    AND (sc-status<$MaxHttp AND sc-status>=200)

GROUP BY cs-uri-stem, Extension

ORDER BY Hits DESC

--lp_query_fileExtensions_IIS.sql--
"@

} # End function Get-RFLpQueryFileExtensionsIIS

function New-RFLpFileFileExtensionsIIS
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF fileExtensions baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileFileExtensionsIIS -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_fileExtensions_IIS.sql'

    Get-RFLpQueryFileExtensionsIIS -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir -MaxHttp $MaxHttp | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileFileExtensionsIIS

Export-ModuleMember -Function 'Get-RFLpQueryFileExtensionsIIS','New-RFLpFileFileExtensionsIIS'
