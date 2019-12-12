# IISRFBaseline #

PowerShell module to help establish an IIS Request Filtering baseline. It leverages the following three components to create Logparser query files which are then used to create `.CSV` result files.

* Website IIS logs
* Website Content Directory
* Microsoft Logparser - see ***Logparser Installation*** in the FAQ for details about this requirement.

## Functions ##

There are two functions exported by this module: `Invoke-IISRFBaseline` and `Get-IISRFBaselineHelp`

### Invoke-IISRFBaseline ###

Invokes the IIS Request Filtering Baseline module.

#### Input ####

No inputs other than the provided parameters.

#### Output ####

Writes Logparser query files (`lp_query_RF-Setting.sql`) and CSV results files (`lp_results_RF-Setting.csv`) to the working directory.

### Get-IISRFBaselineHelp ###

Returns documentation pages (`.md`) to the commandline as a `string[]`. See ***Documentation*** below for details.

## No Results File? ##

They will only be created if there are results. Result files appear in the working directory with the format `lp_results_RF-Setting.csv`. 

***Example***: if no requests have been made to the target website using the double escaping technique, there will be ***no results file*** for that setting (`lp_results_allowDoubleEscaping.csv`). The same is true for `allowHighBitCharacters`. If they are not being used, there will be ***no results file*** (`lp_results_allowHighBitCharacters.csv`).

## Why have CSV results? ##

Logparser can output graphs though it requires installation of Microsoft Office 2003 Web Components. Instead of making yet another prerequisite, the output is standardized as CSV. The results can then be imported into the anything (e.g. Excel, Cloud Spreadsheets, PowerShell, Python, etc). For settings establishing a limit (e.g. `maxAllowedContentLength`, `maxQueryString`, `maxUrl`), it is most useful to chart the results while others should be reviewed via a spreadsheet to omit invalid requests.

Each results file must be reviewed since every website/application is different and there is no way to account for all possible variations. Invalid requests can often be omitted at a glance when having knowledge of how the website works.

## Documentation ##

The documentation for this module is best viewed on Github though also available via the `Get-IISRFBaselineHelp` cmdlet.

Each Request Filtering setting below has a corresponding `.md` file providing details about the setting. Note the `IIS` and `FS` suffix denotes the resource used to build the baseline: IIS logs (`IIS`) or the website content directory (`FS`). `FS` is the Logparser configuration parameter for File System. 

See the FAQ entry ***File System vs IIS Logs*** for details about the difference between these two methods as they greatly impact how the results are created.

Below is each RF setting that has a help file.

* `allowDoubleEscaping`
* `allowHighBitCharacters-FS`
* `allowHighBitCharacters-IIS`
* `fileExtensions-FS`
* `fileExtensions-IIS`
* `maxAllowedContentLength`
* `maxQueryString`
* `maxUrl-FS`
* `maxUrl-IIS`
* `verbs`

The following are additional `.md` documentation files providing more information about this module as well as other Request Filtering settings.

* `FAQ`
* `OtherSettings`
* `README`

Microsoft Request Filtering documentation can be found at the following link:

* https://docs.microsoft.com/en-us/iis/configuration/system.webserver/security/requestfiltering/
