function Get-RFLpQueryMaxAllowedContentLength
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF maxAllowedContentLength baseline using IIS logs.
        .EXAMPLE
        Get-RFLpQueryMaxAllowedContentLength -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_maxAllowedContentLength.csv'

    return @"
--lp_query_maxAllowedContentLength.sql--

SELECT 
    cs-bytes,
    SUB(cs-bytes,STRLEN(ReqLine4)) AS Adjusted-cs-bytes

USING	
    STRCAT(cs-uri-stem, REPLACE_IF_NOT_NULL(cs-uri-query, STRCAT('?',cs-uri-query))) AS ClientRequest, 
    STRCAT(cs-method, STRCAT(' ', STRCAT(ClientRequest, STRCAT(' ', STRCAT(cs-version, 'rn'))))) AS ReqLine0, 
    STRCAT(ReqLine0, REPLACE_IF_NOT_NULL(cs(Cookie), STRCAT('Cookie: ', STRCAT(cs(Cookie),'rn')))) AS ReqLine1, 
    STRCAT(ReqLine1, REPLACE_IF_NOT_NULL(cs(Referer), STRCAT('Referer: ', STRCAT(cs(Referer),'rn')))) AS ReqLine2, 
    STRCAT(ReqLine2, REPLACE_IF_NOT_NULL(cs(User-Agent), STRCAT('User-Agent: ', STRCAT(cs(User-Agent),'rn')))) AS ReqLine3, 
    STRCAT(ReqLine3, STRCAT('Host: ', STRCAT(cs-host, 'rnrn'))) AS ReqLine4
    
INTO $ResultFile

FROM $LogDir

WHERE 
    s-sitename LIKE `'$Sitename`'
    AND (sc-status<$MaxHttp AND sc-status>=200)
    AND (cs-method='POST' OR cs-method='PUT')

ORDER BY Adjusted-cs-bytes ASC

--lp_query_maxAllowedContentLength.sql--
"@

} # End function Get-RFLpQueryMaxAllowedContentLength

function New-RFLpFileMaxAllowedContentLength
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF maxAllowedContentLength baseline using IIS logs.
        .EXAMPLE
        New-RFLpFileMaxAllowedContentLength -Sitename W3SVC1 -LogDir D:\inetpub\Logs\ex*.log -OutputDir D:\WorkingFolder\ -MaxHttp 303
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_maxAllowedContentLength.sql'

    Get-RFLpQueryMaxAllowedContentLength -Sitename $Sitename -LogDir $LogDir -OutputDir $OutputDir -MaxHttp $MaxHttp | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileMaxAllowedContentLength

Export-ModuleMember -Function 'Get-RFLpQueryMaxAllowedContentLength','New-RFLpFileMaxAllowedContentLength'
