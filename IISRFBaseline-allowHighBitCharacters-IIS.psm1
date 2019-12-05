function Get-RFLpQueryAllowHighBitCharactersIIS
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF allowHighBitCharacters baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryAllowHighBitCharactersIIS -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_allowHighBitCharacters_IIS.csv'

    return @"
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

INTO $ResultFile

FROM $LogDir

WHERE 
    s-sitename LIKE `'$Sitename`'
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
"@

} # End function Get-RFLpQueryAllowHighBitCharactersIIS

function New-RFLpFileAllowHighBitCharactersIIS
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF allowHighBitCharacters baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileAllowHighBitCharactersIIS -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_allowHighBitCharacters_IIS.sql'

    Get-RFLpQueryAllowHighBitCharactersIIS -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileAllowHighBitCharactersIIS

Export-ModuleMember -Function 'Get-RFLpQueryAllowHighBitCharactersIIS','New-RFLpFileAllowHighBitCharactersIIS'
