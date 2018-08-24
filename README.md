# DokuCli - A DokuWiki XmlRpc Client for PowerShell


## Example

```powershell
Install-Module -Name DokuCli -Force

If (Connect-Dokuwiki -BaseUri "https://wiki.example.com" -Credential $(Get-Credential)) {

    # Request wiki version
    $Version = Get-DokuVersion

    # Request doku page
    $ExamplePage = Get-DokuPage -Page "start"
    
    # Set doku page
    $Content = "This is a new page."
    Set-DokuPage -Page "start-new" -Content $content -Comment "Demo Page Update"
}
```

With multiple Sessions:

```powershell
Install-Module -Name DokuCli -Force

If (Connect-Dokuwiki -BaseUri "https://wiki.example.com" -Credential $(Get-Credential) -SessionName wiki1) {

    # Request wiki version
    $VersionWiki1 = Get-DokuVersion -SessionName wiki1

}

If (Connect-Dokuwiki -BaseUri "https://wiki.example.com" -Credential $(Get-Credential) -SessionName wiki2) {

    # Request wiki version
    $VersionWiki2 = Get-DokuVersion -SessionName wiki2

}

$PageWiki1 = Get-DokuPage -Page "start" -SessionName wiki1
$PageWiki2 = Get-DokuPage -Page "start" -SessionName wiki2

```


## Setup

### Compatibility

DokuCli has been tested on the following Platforms:
  - Windows 10.0.17134 - PowerShell 5.1.17134.228
  - Ubuntu 16.04 - PowerShell Core 6.0.4
  - ~~Ubuntu 18.04 - PowerShell Core 6.1.0-rc.1~~ ( Invoke-WebRequest POST throws errors )