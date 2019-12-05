function Get-RFLpQueryFileExtensionsFS
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF fileExtensions baseline using website content directory.
        .EXAMPLE
        Get-RFLpQueryFileExtensionsFS -ContentDir \\server.domain.com\website -OutputDir D:\WorkingFolder\
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # Website content directory.
        $ContentDir
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # Outut directory for writing files.
        $OutputDir
    )

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_fileExtensions_FS.csv'

    return @"
--lp_query_fileExtensions_FS.sql--

SELECT DISTINCT 	
    EXTRACT_EXTENSION(Name) AS Extension,
    COUNT(*) AS TotalFiles

INTO $ResultFile

FROM $ContentDir

WHERE Attributes NOT LIKE 'D%'

GROUP BY Extension

ORDER BY TotalFiles DESC

--lp_query_fileExtensions_FS.sql--
"@

} # End function Get-RFLpQueryFileExtensionsFS

function New-RFLpFileFileExtensionsFS
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF fileExtensions baseline using website content directory.
        .EXAMPLE
        New-RFLpFileFileExtensionsFS -ContentDir \\server.domain.com\website -OutputDir D:\WorkingFolder\
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # Website content directory.
        $ContentDir
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # Outut directory for writing files.
        $OutputDir
    )

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_fileExtensions_FS.sql'

    Get-RFLpQueryFileExtensionsFS -ContentDir $ContentDir -OutputDir $OutputDir | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileFileExtensionsFS

Export-ModuleMember -Function 'Get-RFLpQueryFileExtensionsFS','New-RFLpFileFileExtensionsFS'
