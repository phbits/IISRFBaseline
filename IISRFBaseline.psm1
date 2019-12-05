function Invoke-IISRFBaseline
{
    <#
        .SYNOPSIS
        
        Invokes the IIS Request Filtering Baseline module.

        .DESCRIPTION

        Builds Logparser query files based on input parameters and stores them in the WorkingDirectory as lp_query_RF-Setting.sql. Logparser query files are then launched with the results stored in the WorkingDirectory as lp_results_RF-Setting.csv. Output files are in CSV allowing easy import to spreadsheets, scripting languages, or charting apps. .md files correspond to each setting providing details.

        .EXAMPLE
        
        Invoke-IISRFBaseline -WorkingDirectory 'D:\WorkingFolder\' -IISLogPath 'D:\inetpub\Logfiles\logs\' -WebsiteContentPath '\\server.contoso.com\website\' -Sitename 'W3SVC3'

        .EXAMPLE

        Invoke-IISRFBaseline -LogparserPath 'C:\Program Files (x86)\Log Parser 2.2\' -WorkingDirectory 'D:\WorkingFolder\' -IISLogPath 'D:\inetpub\Logfiles\logs\' -WebsiteContentPath '\\server.contoso.com\website\' -Sitename 'W3SVC3'

        .INPUTS

        None.

        .LINK

        https://github.com/phbits/IISRFBaseline
    #>

    [CmdletBinding()]
    [OutputType('System.IO.File')]
    param(
        [parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -LiteralPath $_})]
        [System.String]
        # Path to working directory (Read/Write Access).
        $WorkingDirectory
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # Path to IIS logs (Read Access).
        $IISLogPath
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # Path to Website Content (Read Access)
        $WebsiteContentPath
        ,
        [parameter(Mandatory=$true)]
        [System.String]
        # IIS Website Sitename (Example: W3SVC). See FAQ for details.
        $Sitename
        ,
        [parameter(Mandatory=$false)]
        [Switch]
        # Exclude HTTP response codes 300, 301, and 302 from results.
        $ExcludeRedirects
        ,
        [parameter(Mandatory=$false)]
        [System.String]
        # Folder where Logparser.exe and Logparser.dll resides (Read/Exec).
        $LogparserPath
    )

    Write-Verbose -Message 'Begin input validation'

    $InputOK = $false

    if(Validate-WorkingDirectory -WorkingDir $WorkingDirectory)
    {
        if(Validate-LogParser -Path $LogparserPath)
        {
            if(Validate-Sitename -Sitename $Sitename)
            {
                if(Validate-WebsiteContentPath -Path $WebsiteContentPath)
                {
                    $InputOK = Validate-IISLogs -Path $IISLogPath
                }
            }
        }
    }

    if($InputOK)
    {
        Write-Verbose -Message 'Input validation succeeded.'

        Write-Verbose -Message 'Variables set:'

        if($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent)
        {
            $GlobalVariables = Get-Variable -Name "IISRFB_*" | Format-Table -AutoSize | Out-String

            [string[]]$GlobalVariablesArray = $GlobalVariables.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)

            foreach($item in $GlobalVariablesArray)
            {
                Write-Verbose -Message "    $($item.TrimEnd())"
            }
        }
        
        [int]$global:IISRFB_MaxStatusCode = 303

        if($ExcludeRedirects -eq $true){ $global:IISRFB_MaxStatusCode = 300 }

        $n = 0

        do {

            $n++
            
            switch($n)
            {
                1 {
                    Write-Verbose -Message 'Building allowDoubleEscaping query file.'

                    $QueryFile = New-RFLpFileAllowDoubleEscaping -Sitename $global:IISRFB_Sitename -LogDir $global:IISRFB_IISLogPath -OutputDir $global:IISRFB_WorkingDirectory
                    
                    Write-Verbose -Message 'Building allowDoubleEscaping results file.'

                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                2 { 
                    Write-Verbose -Message 'Building allowHighBitCharacters-FS query file.'
                
                    $QueryFile = New-RFLpFileAllowHighBitCharactersFS -ContentDir $global:IISRFB_WebsiteContentPath -OutputDir $global:IISRFB_WorkingDirectory

                    Write-Verbose -Message 'Building allowHighBitCharacters-FS results file.'

                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:FS -preserveLastAccTime:ON -o:CSV file:$($QueryFile)
                }

                3 { 
                    Write-Verbose -Message 'Building allowHighBitCharacters-IIS query file.'
                
                    $QueryFile = New-RFLpFileAllowHighBitCharactersIIS -Sitename $global:IISRFB_Sitename -LogDir $global:IISRFB_IISLogPath -OutputDir $global:IISRFB_WorkingDirectory
                
                    Write-Verbose -Message 'Building allowHighBitCharacters-IIS results file.'
                    
                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                4 { 
                    Write-Verbose -Message 'Building fileExtensions-FS query file.'

                    $QueryFile = New-RFLpFileFileExtensionsFS -ContentDir $global:IISRFB_WebsiteContentPath -OutputDir $global:IISRFB_WorkingDirectory
                
                    Write-Verbose -Message 'Building fileExtensions-FS results file.'
                    
                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:FS -preserveLastAccTime:ON -o:CSV file:$($QueryFile)
                }

                5 { 
                    Write-Verbose -Message 'Building fileExtensions-IIS query file.'

                    $QueryFile = New-RFLpFileFileExtensionsIIS -Sitename $global:IISRFB_Sitename `
                                                                -LogDir $global:IISRFB_IISLogPath `
                                                                -OutputDir $global:IISRFB_WorkingDirectory `
                                                                -MaxHttp $global:IISRFB_MaxStatusCode
                
                    Write-Verbose -Message 'Building fileExtensions-IIS results file.'
                    
                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                6 { 
                    Write-Verbose -Message 'Building maxAllowedContentLength query file.'

                    $QueryFile = New-RFLpFileMaxAllowedContentLength -Sitename $global:IISRFB_Sitename `
                                                                    -LogDir $global:IISRFB_IISLogPath `
                                                                    -OutputDir $global:IISRFB_WorkingDirectory `
                                                                    -MaxHttp $global:IISRFB_MaxStatusCode

                    Write-Verbose -Message 'Building maxAllowedContentLength results file.'
                    
                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                7 { 
                    Write-Verbose -Message 'Building maxQueryString query file.'

                    $QueryFile = New-RFLpFileMaxQueryString	-Sitename $global:IISRFB_Sitename `
                                                                -LogDir $global:IISRFB_IISLogPath `
                                                                -OutputDir $global:IISRFB_WorkingDirectory `
                                                                -MaxHttp $global:IISRFB_MaxStatusCode

                    Write-Verbose -Message 'Building maxQueryString results file.'

                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                8 { 
                    Write-Verbose -Message 'Building maxUrl-FS query file.'

                    $QueryFile = New-RFLpFileMaxUrlFS -ContentDir $global:IISRFB_WebsiteContentPath -OutputDir $global:IISRFB_WorkingDirectory
                
                    Write-Verbose -Message 'Building maxUrl-FS results file.'

                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:FS -preserveLastAccTime:ON -o:CSV file:$($QueryFile)
                }

                9 { 
                    Write-Verbose -Message 'Building maxUrl-IIS query file.'

                    $QueryFile = New-RFLpFileMaxUrlIIS -Sitename $global:IISRFB_Sitename `
                                                        -LogDir $global:IISRFB_IISLogPath `
                                                        -OutputDir $global:IISRFB_WorkingDirectory `
                                                        -MaxHttp $global:IISRFB_MaxStatusCode

                    Write-Verbose -Message 'Building maxUrl-IIS results file.'

                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                10 {
                    Write-Verbose -Message 'Building verbs query file.'

                    $QueryFile = New-RFLpFileVerbs -Sitename $global:IISRFB_Sitename `
                                                    -LogDir $global:IISRFB_IISLogPath `
                                                    -OutputDir $global:IISRFB_WorkingDirectory `
                                                    -MaxHttp $global:IISRFB_MaxStatusCode

                    Write-Verbose -Message 'Building verbs results file.'

                    & $global:IISRFB_LogparserPath -stats:OFF -q:ON -i:IISW3C -o:CSV file:$($QueryFile)
                }

                default { 
                    Write-Verbose -Message "Writing output files to console."
                    
                    $lpFiles = Get-ChildItem -LiteralPath $global:IISRFB_WorkingDirectory -Filter "lp_*" -File

                    Write-Host "LogParser Query Files:" -fore Green
                    $lpFiles | ?{ $_.Name.ToString().StartsWith('lp_query_') -eq $true } | %{ Write-Host "`t$($_.FullName)"}

                    Write-Host "Result Files:" -fore Green
                    $lpFiles | ?{ $_.Name.ToString().StartsWith('lp_results_') -eq $true } | %{ Write-Host "`t$($_.FullName)"}

                    Write-Host "IISRFBaseline finished." -fore Green

                    $n = 0 
                }
            }

        } while($n -ne 0)

    } else {
    
        Write-Verbose -Message 'Input validation failed.'
    }

} # End function Invoke-IISRFBaseline

function Validate-Sitename
{
    <#
        .SYNOPSIS
        Validates IIS Website Sitename.
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # IIS Website Sitename
        $Sitename
    )

    Write-Verbose -Message "Begin function Validate-Sitename."

    if($Sitename -notmatch "^(?i)(w3svc)[0-9]{1,12}$")
    {
        Write-Error -Message "Invalid Sitename." `
                    -RecommendedAction 'Example: W3SVC99' -Category NotSpecified -ErrorId 120
        return $false
    
    } else {

        Write-Verbose -Message "$Sitename is a valid sitename."

        $global:IISRFB_Sitename = $Sitename.ToUpper()

        return $true
    }

} # End function Validate-Sitename

function Validate-WebsiteContentPath
{
    <#
        .SYNOPSIS
        Validates Website Content Path input parameter.
        .EXAMPLE
        Validate-WebsiteContentPath -Path D:\WorkingFolder\
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # Path to Website Content Path
        $Path
    )

    Write-Verbose -Message 'Begin function Validate-WebsiteContentPath'

    $HasErrors = $false

    $global:IISRFB_WebsiteContentPath = [System.IO.Path]::GetDirectoryName($Path) + '\*'
    
    $lpResult = ''

    try {

        $lpQuery = "SELECT COUNT(*) FROM $global:IISRFB_WebsiteContentPath"

        Write-Verbose -Message "Using Logparser query: $lpQuery"

        [string]$lpResult = & $global:IISRFB_LogparserPath -e:-1 -recurse:-1 -preserveLastAccTime:ON -iw:ON -headers:OFF -q:ON -i:FS -o:NAT $lpQuery

        if($lpResult.Trim() -eq 'Task aborted.')
        {
            Write-Error -Message "Failed to query Website Content Path with Logparser.exe" `
                        -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:FS -o:NAT $lpQuery" `
                        -Category NotSpecified -ErrorId 150
            $HasErrors = $true

        } else {

            [int]$Records = 0

            if([System.Int32]::TryParse($lpResult.Trim(), [ref]$Records) -eq $false)
            {
                Write-Error -Message "Failed to query Website Content Path with Logparser.exe" `
                        -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:FS -o:NAT $lpQuery" `
                        -Category NotSpecified -ErrorId 151
                $HasErrors = $true

            } else {

                if($Records -gt 0)
                {
                    Write-Verbose -Message "$Records files/folders found in $global:IISRFB_WebsiteContentPath"

                } else {

                    Write-Error -Message "Failed to query files/folders from Website Content Path with Logparser.exe" `
                            -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:FS -o:NAT $LpQuery" `
                            -Category NotSpecified -ErrorId 152
                    return $false
                }
            }
        }

    } catch {

        $e = $_

        Write-Error -Message "Failed to query Website Content Path with Logparser.exe. $e.Exception.Message" `
                    -RecommendedAction 'Review exception.' -Category $e.CategoryInfo.Category -ErrorId 153
        $HasErrors = $true
    }

    if($HasErrors)
    {
        return $false

    } else {
    
        return $true
    }

} # End function Validate-WebsiteContentPath

function Validate-IisLogs
{
    <#
        .SYNOPSIS
        Validates IIS logs input parameter.
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # Path to IIS logs
        $Path
    )

    Write-Verbose -Message 'Begin function Validate-IisLogs'

    $i = 0

    $HasErrors = $false

    $global:IISRFB_IISLogPath = $Path
    
    $lpResult = ''

    do{

        $i++

        switch($i)
        {
            1 { # add asterisk if not present.

                if($global:IISRFB_IISLogPath.ToString().Contains('*') -eq $false)
                {
                    Write-Verbose -Message "Adding suffix to path: $global:IISRFB_IISLogPath"

                    try {

                        $global:IISRFB_IISLogPath = [System.IO.Path]::GetDirectoryName($Path) + '\*.log'

                    } catch {

                        $e = $_

                        Write-Error -Message "Failed to update IIS log path. $e.Exception.Message" `
                                    -RecommendedAction 'Review exception.' -Category $e.CategoryInfo.Category -ErrorId 140
                        $HasErrors = $true
                    }
                }
            }

            2 { # run logparser against

                Write-Verbose -Message "Running Logparser.exe against IIS log path: $global:IISRFB_IISLogPath"

                try {

                    $LpQuery = "SELECT COUNT(*) FROM $global:IISRFB_IISLogPath WHERE s-sitename LIKE `'$global:IISRFB_Sitename`'"

                    Write-Verbose -Message "Using Logparser query: $LpQuery"

                    [string]$lpResult = & $global:IISRFB_LogparserPath -e:-1 -iw:ON -headers:OFF -q:ON -i:IISW3C -o:NAT $lpQuery

                    if($lpResult.Trim() -eq 'Task aborted.')
                    {
                        Write-Error -Message "Failed to query IIS logs with Logparser.exe" `
                                    -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:IISW3C -o:NAT $LpQuery" `
                                    -Category NotSpecified -ErrorId 141
                        return $false

                    } else {

                        [int]$IisRecords = 0

                        if([System.Int32]::TryParse($lpResult.Trim(), [ref]$IisRecords) -eq $false)
                        {
                            Write-Error -Message "Failed to query IIS logs with Logparser.exe" `
                                    -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:IISW3C -o:NAT $LpQuery" `
                                    -Category NotSpecified -ErrorId 142
                            return $false

                        } else {

                            if($IisRecords -gt 0)
                            {
                                Write-Verbose -Message "$IisRecords IIS log records found for $global:IISRFB_Sitename"

                            } else {

                                Write-Error -Message "Failed to return IIS logs with Logparser.exe" `
                                        -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:IISW3C -o:NAT $LpQuery" `
                                        -Category NotSpecified -ErrorId 143
                                return $false
                            }
                        }
                    }

                } catch {
                
                    $e = $_

                    Write-Error -Message "Failed to get file details. $e.Exception.Message" `
                                -RecommendedAction 'Review exception.' -Category $e.CategoryInfo.Category -ErrorId 144
                    $HasErrors = $true
                }
            }

            default { return $true }
        }

        if($HasErrors -eq $true)
        {
            return $false
        }

    }while($i -lt 10)

} # End function Validate-IisLogs

function Validate-Logparser
{
    <#
        .SYNOPSIS
        Validates Logparser version and that it can be launched.
        .EXAMPLE
        Validate-Logparser -Path D:\WorkingFolder\logparser.exe
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [System.String]
        # Path to Logparser
        $Path
    )

    Write-Verbose -Message 'Begin function Validate-Logparser'
    
    $i = 0

    $global:IISRFB_LogparserPath = $Path

    $LpExeObj = ''

    $HasErrors = $false
 
    do{

        $i++

        switch($i)
        {
            1 { # Search for Logparser.exe if not provided.

                if([System.String]::IsNullOrEmpty($global:IISRFB_LogparserPath))
                {
                    Write-Verbose -Message 'Searching for Logparser.exe'

                    [string]$SearchFolders = $env:Path + ';' + $pwd.Path

                    $lpProgramFilesx86 = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Log Parser 2.2'

                    if(Test-Path -LiteralPath $lpProgramFilesx86)
                    {
                        $SearchFolders = $lpProgramFilesx86 + ';' + $SearchFolders
                    }

                    $lpProgramFiles = Join-Path -Path $env:ProgramFiles -ChildPath 'Log Parser 2.2'

                    if(Test-Path -LiteralPath $lpProgramFiles)
                    {
                        $SearchFolders = $lpProgramFiles + ';' + $SearchFolders
                    }

                    if([System.String]::IsNullOrEmpty($global:IISRFB_WorkingDirectory) -eq $false)
                    {
                        $SearchFolders = $global:IISRFB_WorkingDirectory + ';' + $SearchFolders
                    }

                    [string[]]$SearchFoldersArray = $SearchFolders.Split(';')

                    for($n=0; $n -lt $SearchFoldersArray.Count; $n++)
                    {
                        if([System.String]::IsNullOrEmpty($SearchFoldersArray[$n]) -eq $false)
                        {
                            $TestLpLocation = Join-Path -Path $SearchFoldersArray[$n] -ChildPath 'Logparser.exe'

                            Write-Verbose -Message "Checking $TestLpLocation"

                            if(Test-Path -LiteralPath $TestLpLocation)
                            {
                                $global:IISRFB_LogparserPath = $TestLpLocation

                                $n = $SearchFoldersArray.Count

                                Write-Verbose -Message "Found $TestLpLocation"
                            }
                        }
                    }
                }

                if([System.String]::IsNullOrEmpty($global:IISRFB_LogparserPath))
                {
                    Write-Error -Message 'Cannot find Logparser.exe.' -RecommendedAction 'Use -LogparserPath switch.' `
                                -Category ObjectNotFound -ErrorId 130
                    $HasErrors = $true
                }
            }

            2 { # get file details of Logparser.exe

                Write-Verbose -Message "Getting file details for $global:IISRFB_LogparserPath"

                try {

                    $LpObj = Get-Item -LiteralPath $global:IISRFB_LogparserPath -ErrorAction Stop

                    if($LpObj.PSIsContainer)
                    {
                        $LpPath = Join-Path -Path $global:IISRFB_LogparserPath -ChildPath 'LogParser.exe'

                        $LpExeObj = Get-Item -LiteralPath $LpPath -ErrorAction Stop

                        $global:IISRFB_LogparserPath = $LpExeObj.FullName

                    } else {

                        $LpExeObj = $LpObj
                    }

                    if([System.String]::IsNullOrEmpty($LpExeObj) -eq $true)
                    {
                        Write-Error -Message 'Failed to get file details for Logparser.exe.' `
                                    -RecommendedAction 'Use -LogparserPath switch.' -Category ObjectNotFound -ErrorId 131
                        $HasErrors = $true
                    }

                } catch {
                                
                    $e = $_

                    Write-Error -Message $('Failed to get file details. {0}' -f $e.Exception.Message) `
                                -RecommendedAction 'Use -LogparserPath switch.' -Category $e.CategoryInfo.Category -ErrorId 132
                    $HasErrors = $true
                }
            }

            3 { # verify file details of Logparser.exe

                Write-Verbose -Message "Verifying file details of $global:IISRFB_LogparserPath"

                try {

                    if($LpExeObj.VersionInfo.FileVersion -ne '2.2.10.0')
                    {
                        Write-Error -Message $('Invalid Log Parser Version {0}' -f $LpExeObj.VersionInfo.FileVersion) `
                                    -RecommendedAction 'Get Log Parser Version 2.2.10' -Category InvalidResult -ErrorId 133
                        $HasErrors = $true
                    
                    } else {

                        $global:IISRFB_LogparserPath = $LpExeObj.FullName
                    }

                } catch {
                                
                    $e = $_

                    Write-Error -Message $('Error getting Logparser.exe file details. {0}' -f $e.Exception.Message) `
                                -RecommendedAction 'Check exception message.' -Category $e.CategoryInfo.Category -ErrorId 134
                    $HasErrors = $true
                }
            }

            4 { # test launch of Logparser.exe

                Write-Verbose -Message "Test launch of $global:IISRFB_LogparserPath"

                try{

                    $lpQuery = "`"SELECT FileVersion FROM `'$($global:IISRFB_LogparserPath)`'`""

                    Write-Verbose -Message "Using Logparser query: $lpQuery"

                    [string]$lpFileVersion = & $global:IISRFB_LogparserPath -e:-1 -iw:ON -headers:OFF -q:ON -i:FS -o:NAT $lpQuery

                    if([System.String]::IsNullOrEmpty($lpFileVersion) -eq $false)
                    {                    
                        if($lpFileVersion.Trim() -eq 'Task aborted.')
                        {
                            Write-Error -Message "Failed to launch $global:IISRFB_LogparserPath" `
                                        -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:FS -o:NAT $lpQuery" `
                                        -Category NotSpecified -ErrorId 135
                            $HasErrors = $true

                        } elseif($lpFileVersion.Trim().StartsWith('2.2.10') -eq $false){

                            Write-Error -Message $('Invalid Log Parser Version {0}' -f $lpFileVersion) `
                                        -RecommendedAction 'Install Log Parser Version 2.2.10' -Category InvalidResult -ErrorId 136
                            $HasErrors = $true
                        }

                    } else {

                        Write-Error -Message "Failed to launch $global:IISRFB_LogparserPath" `
                                    -RecommendedAction "Manually run this query: & $global:IISRFB_LogparserPath -i:FS -o:NAT $lpQuery" `
                                    -Category NotSpecified -ErrorId 137
                        $HasErrors = $true
                    }

                } catch {

                    $e = $_

                    Write-Error -Message $('Failed to launch Logparser.exe. {0}' -f $e.Exception.Message) `
                                -RecommendedAction 'Check exception message.' -Category $e.CategoryInfo.Category -ErrorId 138
                    $HasErrors = $true
                }
            }

            default { return $true }
        }

        if($HasErrors -eq $true)
        {
            return $false
        }

    }while($i -lt 10)

} # End function Validate-Logparser

function Get-IISRFBaselineHelp
{
    <#
        .SYNOPSIS
        
        Outputs markdown help file for the specified setting.

        .DESCRIPTION

        Best viewed on GitHub. Acceptable values are:

        allowDoubleEscaping
        allowHighBitCharacters-FS
        allowHighBitCharacters-IIS
        FAQ
        fileExtensions-FS
        fileExtensions-IIS
        maxAllowedContentLength
        maxQueryString
        maxUrl-FS
        maxUrl-IIS
        OtherSettings
        README
        verbs

        .INPUTS

        None

        .OUTPUTS

        System.String[]

        .EXAMPLE
        
        PS> Get-IISRFBaselineHelp -Setting allowHighBitCharacters-IIS

        .EXAMPLE

        PS> Get-IISRFBaselineHelp -Setting maxAllowedContentLength

        .LINK

        https://github.com/phbits/IISRFBaseline
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [ValidateSet('allowDoubleEscaping','allowHighBitCharacters-FS','allowHighBitCharacters-IIS','fileExtensions-FS','fileExtensions-IIS','maxAllowedContentLength','maxQueryString','maxUrl-FS','maxUrl-IIS','verbs','FAQ','OtherSettings','README')]
        [System.String]
        # IISRFBaseline Help File
        $HelpFile
    )
        $HelpFileLocation = ''

        switch ($Setting.ToUpper())
        {
            'ALLOWDOUBLEESCAPING'        { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-allowDoubleEscaping.md' }
            'ALLOWHIGHBITCHARACTERS-FS'  { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-allowHighBitCharacters-FS.md' }
            'ALLOWHIGHBITCHARACTERS-IIS' { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-allowHighBitCharacters-IIS.md' }
            'FAQ'                        { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'FAQ.md' }
            'FILEEXTENSIONS-FS'          { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-fileExtensions-FS.md' }
            'FILEEXTENSIONS-IIS'         { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-fileExtensions-IIS.md' }
            'MAXALLOWEDCONTENTLENGTH'    { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-maxAllowedContentLength.md' }
            'MAXQUERYSTRING'             { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-maxQueryString.md' }
            'MAXURL-FS'                  { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-maxUrl-FS.md' }
            'MAXURL-IIS'                 { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-maxUrl-IIS.md' }
            'OTHERSETTINGS'              { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'OtherSettings.md' }
            'README'                     { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'README.md' }
            'VERBS'                      { $HelpFileLocation = Join-Path -Path $global:IISRFB_BasePath -ChildPath 'IISRFBaseline-verbs.md' }
            default                      { Write-Error 'Unknown `"-Setting`" parameter. Try, Get-Help Get-IISRFBaselineHelp -Full' }
        }
    
    if([System.String]::IsNullOrEmpty($HelpFileLocation) -eq $false)
    {
        try 
        {		
            [string[]]$HelpFileContent = Get-Content -LiteralPath $HelpFileLocation

            return $HelpFileContent

        } catch {
            
            $e = $_

            Write-Error -Message "$($e.Exception.Message)"
        }
    }

} # End function Get-IISRFBaselineHelp

function Validate-WorkingDirectory
{
    <#
        .SYNOPSIS
        Validates Read/Write Access to Working Directory
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String]
        # Path to Working Directory
        $WorkingDir
    )

    Write-Verbose -Message 'Begin function Validate-WorkingDirectory'

    Write-Verbose -Message "Validating IsFolder: $WorkingDir"

    $WorkingDirItem = Get-Item -LiteralPath $WorkingDir

    if($WorkingDirItem.PSIsContainer -eq $false)
    {
        Write-Error -Message "`"$WorkingDir`" is not a valid Working Directory." `
                                    -RecommendedAction "Specify a folder for the `'-WorkingDirectory`' switch." `
                                    -Category NotSpecified -ErrorId 161
        return $false
    }

    Write-Verbose -Message "Validating Read/Write access to $WorkingDir"

    $TestFilePath = Join-Path -Path $WorkingDir -ChildPath 'tmp-test-write.txt'

    if(Test-Path -LiteralPath $TestFilePath)
    {
        Write-Error -Message "$TestFilePath already exists. Must delete before proceeding." `
                    -Category NotSpecified -ErrorId 162
        return $false
    }

    try {

        Write-Verbose -Message "Writing temp file to $TestFilePath"

        $TestFile = New-Item -Path $WorkingDir -Name 'tmp-test-write.txt' -ItemType File -Value 'TestWrite' -ErrorAction Stop

        Write-Verbose -Message "Reading temp file at $TestFilePath"

        $TestFileContent = Get-Content -LiteralPath $TestFilePath -ErrorAction Stop

        if($TestFileContent -ne 'TestWrite')
        {
            Write-Error -Message "Failed to read temp file $TestFilePath" `
                                    -RecommendedAction "Verify a minimum of Read/Write permission on $WorkingDir" `
                                    -Category NotSpecified -ErrorId 163
            return $false
        }

    } catch {
    
        $e = $_

        Write-Error -Message "$($e.Exception.Message)"

        return $false
    }

    Write-Verbose -Message "Validated Read/Write access to $WorkingDir"

    if(Test-Path -LiteralPath $TestFilePath)
    {
        try {

            Write-Verbose -Message "Removing temp file $TestFilePath"

            Remove-Item -LiteralPath $TestFilePath

        } catch {

            Write-Verbose -Message "Failed to remove temp file $TestFilePath. Not critical. Continuing."
        }
    }

    Write-Verbose -Message "Valid working directory $WorkingDir"

    $global:IISRFB_WorkingDirectory = [System.IO.Path]::GetDirectoryName($WorkingDir) + '\'

    return $true

} # End function Validate-WorkingDirectory

# set module root to variable
$global:IISRFB_BasePath = [System.IO.Path]::GetDirectoryName($psscriptroot) + '\'
