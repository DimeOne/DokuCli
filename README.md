# DokuCli - A DokuWiki XmlRpc Client for PowerShell


## Example

```powershell
Install-Module -Name DokuCli -Force

If (Connect-Dokuwiki -Uri "https://wiki.example.com" -Credential $(Get-Credential)) {

    # Request wiki version
    $Version = Get-DokuVersion

    # Request doku page
    $ExamplePage = Get-DokuPage -Page "start"
    
    # Set doku page
    $Content = "This is a new page."
    Set-DokuPage -Page "start-new" -Content $content -Comment "Demo Page Update"
}
```
