function Get-RFLpQueryAllowDoubleEscaping
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF allowDoubleEscaping baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryAllowDoubleEscaping -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\
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
    )

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_allowDoubleEscaping.csv'

    return @"
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

INTO $ResultFile

FROM $LogDir

WHERE 
    s-sitename LIKE `'$Sitename`'
    AND (Normalized1<>Normalized2 
        OR (sc-status=404 AND sc-substatus=11))
    AND NOT ((sc-status=400 AND sc-substatus=0)
        OR (sc-status=404 AND sc-substatus=0))

--lp_query_allowDoubleEscaping.sql--
"@

} # End function Get-RFLpQueryAllowDoubleEscaping

function New-RFLpFileAllowDoubleEscaping
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF allowDoubleEscaping baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileAllowDoubleEscaping -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\
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
    )

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_allowDoubleEscaping.sql'

    Get-RFLpQueryAllowDoubleEscaping -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileAllowDoubleEscaping

Export-ModuleMember -Function 'Get-RFLpQueryAllowDoubleEscaping','New-RFLpFileAllowDoubleEscaping'
