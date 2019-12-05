function Get-RFLpQueryAllowHighBitCharactersFS
{
    <#
        .SYNOPSIS
        Creates Logparser query for RF allowHighBitCharacters baseline using website content directory.
        .EXAMPLE
        Get-RFLpQueryAllowHighBitCharacters -ContentDir \\server.domain.com\website -OutputDir D:\WorkingFolder\
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

    $ResultFile = Join-Path -Path $OutputDir -ChildPath 'lp_results_allowHighBitCharacters_FS.csv'

    return @"
--lp_query_allowHighBitCharacters_FS.sql--

SELECT
    Path,
    Name,
    URLESCAPE(Name) AS EncodedName

INTO $ResultFile

FROM $ContentDir

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
"@

} # End function Get-RFLpQueryAllowHighBitCharactersFS

function New-RFLpFileAllowHighBitCharactersFS
{
    <#
        .SYNOPSIS
        Creates Logparser file for RF allowHighBitCharacters baseline using website content directory.
        .EXAMPLE
        New-RFLpFileAllowHighBitCharactersFS -ContentDir \\server.domain.com\website -OutputDir D:\WorkingFolder\
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

    $FileLocation = Join-Path -Path $OutputDir -ChildPath 'lp_query_allowHighBitCharacters_FS.sql'

    Get-RFLpQueryAllowHighBitCharactersFS -ContentDir $ContentDir -OutputDir $OutputDir | Out-File -LiteralPath $FileLocation -Force -Encoding ascii

    return $FileLocation

} # End function New-RFLpFileAllowHighBitCharactersFS

Export-ModuleMember -Function 'Get-RFLpQueryAllowHighBitCharactersFS','New-RFLpFileAllowHighBitCharactersFS'
