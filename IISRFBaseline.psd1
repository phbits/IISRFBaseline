﻿@{

RootModule = 'IISRFBaseline.psm1'

ModuleVersion = '1.0'

GUID = 'b6887c47-6101-45c7-bb11-120159a3111a'

Author = 'phbits'

CompanyName = 'phbits'

Copyright = '(c) 2019 phbits. All rights reserved.'

Description = @'
PowerShell module to help establish an IIS Request Filtering baseline. Builds Logparser query files based on input parameters and stores them in the WorkingDirectory as lp_query_RF-Setting.sql. Logparser query files are then launched with the results stored in the WorkingDirectory as lp_results_RF-Setting.csv. Output files are in CSV allowing easy import to spreadsheets, scripting languages, or charting apps. .md files correspond to each setting providing details.
'@

PowerShellVersion = '5.1'

NestedModules = 'IISRFBaseline-allowDoubleEscaping.psm1',
                'IISRFBaseline-allowHighBitCharacters-FS.psm1',
                'IISRFBaseline-allowHighBitCharacters-IIS.psm1',
                'IISRFBaseline-fileExtensions-FS.psm1',
                'IISRFBaseline-fileExtensions-IIS.psm1',
                'IISRFBaseline-maxAllowedContentLength.psm1',
                'IISRFBaseline-maxQueryString.psm1',
                'IISRFBaseline-maxUrl-FS.psm1',
                'IISRFBaseline-maxUrl-IIS.psm1',
                'IISRFBaseline-verbs.psm1'

FunctionsToExport = 'Invoke-IISRFBaseline','Get-IISRFBaselineHelp'

FileList =  'IISRFBaseline-allowDoubleEscaping.md',
            'IISRFBaseline-allowDoubleEscaping.psm1',
            'IISRFBaseline-allowHighBitCharacters-FS.md',
            'IISRFBaseline-allowHighBitCharacters-FS.psm1',
            'IISRFBaseline-allowHighBitCharacters-IIS.md',
            'IISRFBaseline-allowHighBitCharacters-IIS.psm1',
            'IISRFBaseline-fileExtensions-FS.md',
            'IISRFBaseline-fileExtensions-FS.psm1',
            'IISRFBaseline-fileExtensions-IIS.md',
            'IISRFBaseline-fileExtensions-IIS.psm1',
            'IISRFBaseline-maxAllowedContentLength.md',
            'IISRFBaseline-maxAllowedContentLength.psm1',
            'IISRFBaseline-maxQueryString.md',
            'IISRFBaseline-maxQueryString.psm1',
            'IISRFBaseline-maxUrl-FS.md',
            'IISRFBaseline-maxUrl-FS.psm1',
            'IISRFBaseline-maxUrl-IIS.md',
            'IISRFBaseline-maxUrl-IIS.psm1',
            'IISRFBaseline-verbs.md',
            'IISRFBaseline-verbs.psm1',
            'IISRFBaseline.psd1',
            'IISRFBaseline.psm1',
            'FAQ.md',
            'OtherSettings.md',
            'README.md'

PrivateData = @{

    PSData = @{

        Tags = 'Microsoft','IIS','RequestFiltering','Logparser','website','security','HTTP'

        ProjectUri = 'https://github.com/phbits/IISRFBaseline'

        LicenseUri = 'https://github.com/phbits/IISRFBaseline/blob/master/LICENSE'

    } # End of PSData hashtable
} # End of PrivateData hashtable
}
