function Get-RFLpQueryMaxUrlFS
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF maxUrl baseline using website content directory.
        .EXAMPLE
        Get-RFLpQueryMaxUrlFS -ContentDir \\server.domain.com\website -OutputDir D:\WorkingFolder\
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_maxUrl_FS.csv'

    $BaseDir = [System.IO.Path]::GetDirectoryName($ContentDir)

    return @"
--lp_query_maxUrl_FS.sql--

SELECT 
    Path AS FilePath,
    REPLACE_CHR(file-cs-uri-stem,'\\','/') AS PROPOSED-cs-uri-stem,
    STRLEN(PROPOSED-cs-uri-stem) AS maxUrl

USING
    REPLACE_STR(Path, `'$BaseDir`', '') as file-cs-uri-stem
    
INTO $ResultFile

FROM $ContentDir

WHERE
    Path NOT LIKE '%\\aspnet_client%' AND
    Path NOT LIKE '%.config' AND
    Path NOT LIKE '%.dll' AND
    Path NOT LIKE '%.cs' AND
    Path NOT LIKE '%\\..' AND
    Path NOT LIKE '%\\.'

ORDER BY maxUrl DESC

--lp_query_maxUrl_FS.sql--
"@

} # End function Get-RFLpQueryMaxUrlFS

function New-RFLpFileMaxUrlFS
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF verbs baseline using website content directory.
        .EXAMPLE
        New-RFLpFileMaxUrlFS -ContentDir \\server.domain.com\website -OutputDir D:\WorkingFolder\
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_maxUrl_FS.sql'

    Get-RFLpQueryMaxUrlFS -ContentDir $ContentDir -OutputDir $OutputDir | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileMaxUrlFS

Export-ModuleMember -Function 'Get-RFLpQueryMaxUrlFS','New-RFLpFileMaxUrlFS'
