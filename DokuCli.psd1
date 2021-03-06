﻿@{

    ModuleVersion = '0.1.1'
    GUID = '3c98c198-d8b2-4464-b30c-8a6ba2aa4ea5'

    Author = 'Dominic S.'
    CompanyName = 'ME'
    Copyright = '(c) 2018 ME'
    Description = 'A DokuWiki XmlRpc Api Client for PowerShell'

    RootModule = 'DokuCli.psm1'
    FunctionsToExport = @(
        "Connect-Dokuwiki",
        "Get-DokuVersion",
        "Get-DokuPage",
        "Set-DokuPage",
        "Invoke-DokuwikiXmlRpcMethod",
        "Invoke-XmlRpcMethod",
        "Get-XmlRpcObject",
        "Get-ObjectsFromXmlRpcChildNodes",
        "Get-ObjectFromXmlRpcElement",
        "Get-XmlRpcMethodCallBody"
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @("DokuWiki", "XmlRpc", "Api", "ApiClient", "Client")
            LicenseUri = 'https://raw.githubusercontent.com/DimeOne/DokuCli/master/LICENSE'
            ProjectUri = 'https://github.com/DimeOne/DokuCli'
            # IconUri = ''
            # ReleaseNotes = ''
        }
    }
    HelpInfoURI = 'https://github.com/DimeOne/DokuCli/blob/master/README.md'

    # CompatiblePSEditions = @()
    # PowerShellVersion = ''
    # PowerShellHostName = ''
    # PowerShellHostVersion = ''
    # DotNetFrameworkVersion = ''
    # CLRVersion = ''
    # ProcessorArchitecture = ''
    # RequiredModules = @()
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @()
    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''

}

