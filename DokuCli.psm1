#region XmlRpc

Function Get-XmlRpcObject {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$False,Position=0)]
    [Object]$Object,
    [Parameter(Mandatory=$False,Position=1)]
    [Object[]]$Decorators = @("value"),
    [Parameter(Mandatory=$False,Position=2)]
    [String]$Prefix,
    [Parameter(Mandatory=$False,Position=3)]
    [String]$Suffix
  )

  Foreach ($Decorator in $Decorators) {
    $Prefix += "<$Decorator>"
    $Suffix = "</$Decorator>" + $Suffix
  }

  If ($Null -eq $Object) {
    Return "$Prefix<nil/>$Suffix"
  }

  Switch ($Object.GetType().Name) {
    "String" { Return "$Prefix<string>$([Security.SecurityElement]::Escape($Object))</string>$Suffix" }
    "Boolean" {
      If ($Object) {
        Return "$Prefix<boolean>1</boolean>$Suffix"
      }
      Else {
        Return "$Prefix<boolean>0</boolean>$Suffix"
      }
    }
    "Int32" { Return "$Prefix<i4>$Object</i4>$Suffix" }
    "Double" { Return "$Prefix<double>$Object</double>$Suffix" }
    "DateTime" {
      $iso8601dt = Get-Date -Date $Object -Format "o"
      Return "$Prefix<dateTime.iso8601>$iso8601dt</dateTime.iso8601>$Suffix"
    }
    "Object[]" {
      $ArrayString = "$Prefix<array><data>"
      Foreach ($Obj in $Object) {
        $ArrayString += Get-XmlRpcObject $Obj -Decorators @("value")
      }
      $ArrayString = "<data><array>$Suffix"
      Return $ArrayString
    }
    "HashTable" {
      $StructString = "$Prefix<struct>"
      Foreach ($Key in $Object.Keys) {
        $StructString += "<member><name>$Key</name>"
        $StructString += Get-XmlRpcObject $Object[$Key] -Decorators @("value")
        $StructString += "</member>"
      }
      $StructString += "</struct>$Suffix"
      Return $StructString
    }
    default { Write-Error "Unknown XmlRpcObject Type: $($Object.GetType().Name)" }
  }

}

Function Get-ObjectsFromXmlRpcChildNodes {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True,Position=0)]
    [Object]$XmlChildNodes,
    [Parameter(Mandatory=$False,Position=1)]
    [String]$Property
  )

  $Array = @()
  Foreach ($XmlElement in $XmlChildNodes) {
    If ($Property -ne "") {
      $Array += Get-ObjectFromXmlRpcElement $XmlElement.$Property
    }
    Else {
      $Array += Get-ObjectFromXmlRpcElement $XmlElement
    }
  }
  Return $array
}

Function Get-ObjectFromXmlRpcElement {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True,Position=0)]
    [System.Xml.XmlElement]$XmlElement
  )

  If ($Null -ne $XmlElement.value.boolean) {
    Return $XmlElement.value.boolean -eq 1
  }

  If ($Null -ne $XmlElement.value.string) {
    Return $XmlElement.value.string
  }

  If ($Null -ne $XmlElement.value.double) {
    Return [Double]$XmlElement.value.double
  }

  If ($Null -ne $XmlElement.value.int) {
    Return [Int32]$XmlElement.value.int
  }

  If ($Null -ne $XmlElement.value.i4) {
    Return [Int32]$XmlElement.value.i4
  }

  If ($Null -ne $XmlElement.value.array) {
    $Array = @()
    Foreach ($ArrayMember in $XmlElement.value.array.data) {
      $Array += Get-ObjectFromXmlRpcElement $ArrayMember
    }
    Return $Array
  }

  If ($Null -ne $XmlElement.value.struct) {
    $Struct = @{}
    Foreach ($StructMember in $XmlElement.value.struct.member) {
      $Struct[$StructMember.name] = Get-ObjectFromXmlRpcElement $StructMember
    }
    Return $Struct
  }

  Write-Error "Unable to create object from given XmlElement" -ErrorAction Stop

}

Function Get-XmlRpcMethodCallBody {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True,Position=0)]
    [String]$Name,
    [Parameter(Mandatory=$False,Position=1)]
    [Object[]]$Params
  )

  $XmlBody = '<?xml version="1.0" encoding="UTF-8"?>'
  $XmlBody += "<methodCall><methodName>$Name</methodName>"
  If ($Params.Count -gt 0) {
    $XmlBody += "<params>"
    foreach ($Param in $Params) {
      $XmlBody += Get-XmlRpcObject $Param -Decorators "param","value"
    }
    $XmlBody += '</params>'
  }
  $XmlBody += '</methodCall>'
  Return $XmlBody

}

Function Invoke-XmlRpcMethod {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True,Position=0)]
    [String]$Uri,
    [Parameter(Mandatory=$True,Position=1)]
    [String]$Name,
    [Parameter(Mandatory=$False,Position=2)]
    [Object[]]$Params,
    [Parameter(Mandatory=$False,Position=3)]
    [String]$SessionVariable = "XmlRpcDefaultSession",
    [Parameter(Mandatory=$False,Position=4)]
    [Switch]$NewSession
  )

  $Body = Get-XmlRpcMethodCallBody -Name $Name -Params $Params

  $RequestParams = @{
    Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
    UseBasicParsing = $True
    Method = "Post"
    ContentType = "text/xml"
    Uri = $Uri
    ErrorAction = "Stop"
  }

  If (Test-Path "variable:global:$SessionVariable") {
    $WebSession = Get-Variable -Name $SessionVariable -Scope Global -ValueOnly
  }

  # Create new session if the
  If ($NewSession -or ($Null -eq $WebSession)) {
    $RequestParams["SessionVariable"] = $SessionVariable
  }
  Else {
    $RequestParams["WebSession"] = $WebSession
  }

  # Perform request
  $Response = Invoke-WebRequest @RequestParams

  # Store Session Variable as global
  $WebSession = Get-Variable -Name $SessionVariable -ValueOnly
  Set-Variable -Name $SessionVariable -Scope Global -Value $WebSession

  # Response content as xml
  $ResponseXml = [xml]$Response.Content

  Return $ResponseXml.methodResponse

}

#endregion XmlRpc
#region DokuWiki

Function Invoke-DokuwikiXmlRpcMethod {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True,Position=0)]
    [String]$BaseUri,
    [Parameter(Mandatory=$True,Position=1)]
    [String]$Name,
    [Parameter(Mandatory=$False,Position=2)]
    [Object[]]$Params,
    [Parameter(Mandatory=$False,Position=3)]
    [String]$SessionVariable = "DokuWikiXmlRpcSession",
    [Parameter(Mandatory=$False,Position=4)]
    [Switch]$NewSession
  )

  $XmlRpcParams = @{
    Uri = $BaseUri.trim("/") + "/lib/exe/xmlrpc.php"
    Name = $Name
    Params = $Params
    SessionVariable = $SessionVariable
    NewSession = $NewSession
  }

  $XmlResponse = Invoke-XmlRpcMethod @XmlRpcParams

  If ($XmlResponse.fault) {
    $Fault = Get-ObjectFromXmlRpcElement -XmlElement $XmlResponse.fault
    $ErrorMessage = "DokuWiki XmlRpc method call: $Name failed. [{0}]: {1}" -f $Fault["faultCode"], $Fault["faultString"]
    Write-Error $ErrorMessage
  }

  If ($XmlResponse.params) {
    Return @{Response = Get-ObjectsFromXmlRpcChildNodes $XmlResponse.params.ChildNodes}
  }

}

Function Connect-Dokuwiki {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True,Position=0)]
    [String]$BaseUri,
    [Parameter(Mandatory=$True,Position=1)]
    [PSCredential]$Credential,
    [Parameter(Mandatory=$False,Position=2)]
    [String]$SessionName = "DokuWikiXmlRpcDefaultSession"
  )

  $DokuSession = @{
    BaseUri = $BaseUri
    Connected = $False
    WebSessionName = "$($SessionName)_WebSession"
  }
  Set-Variable -Name $SessionName -Value $DokuSession -Scope Global

  $XmlRpcParams = @{
    BaseUri = $DokuSession.BaseUri
    Name = "dokuwiki.login"
    Params =  $Credential.UserName,$Credential.getnetworkcredential().password
    SessionVariable = $DokuSession.WebSessionName
    NewSession = $True
  }

  $Response = Invoke-DokuwikiXmlRpcMethod @XmlRpcParams

  If ($Response.Response) {
    $DokuSession.Connected = $True
    Set-Variable -Name $SessionName -Value $DokuSession -Scope Global
  }

  Return $Response.Response

}

Function Get-DokuVersion {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$False,Position=0)]
    [String]$SessionName = "DokuWikiXmlRpcDefaultSession"
  )

  If (Test-Path "variable:global:$SessionName") {
    $DokuSession = Get-Variable -Name $SessionName -Scope Global -ValueOnly
  }
  If (-not ($DokuSession.Connected)) {
    Write-Error "Unable to Get-DokuVersion - Please use Connect-Dokuwiki first." -ErrorAction Stop
  }

  $XmlRpcParams = @{
    BaseUri = $DokuSession.BaseUri
    Name = "dokuwiki.getVersion"
    Params =  @()
    SessionVariable = $DokuSession.WebSessionName
    NewSession = $False
  }

  $Response = Invoke-DokuwikiXmlRpcMethod @XmlRpcParams

  Return $Response.Response

}

Function Get-DokuPage {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True,Position=0)]
    [String]$Page,
    [Parameter(Mandatory=$False,Position=1)]
    [String]$SessionName = "DokuWikiXmlRpcDefaultSession"
  )

  If (Test-Path "variable:global:$SessionName") {
    $DokuSession = Get-Variable -Name $SessionName -Scope Global -ValueOnly
  }
  If (-not ($DokuSession.Connected)) {
    Write-Error "Unable to Get-DokuPage - Please use Connect-Dokuwiki first." -ErrorAction Stop
  }

  $XmlRpcParams = @{
    BaseUri = $DokuSession.BaseUri
    Name = "wiki.getPage"
    Params =  @($Page)
    SessionVariable = $DokuSession.WebSessionName
    NewSession = $False
  }

  $Response = Invoke-DokuwikiXmlRpcMethod @XmlRpcParams

  Return $Response.Response

}

Function Set-DokuPage {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True,Position=0)]
    [String]$Page,
    [Parameter(Mandatory=$True,Position=1)]
    [String]$Content,
    [Parameter(Mandatory=$False,Position=2)]
    [String]$Comment,
    [Parameter(Mandatory=$False,Position=3)]
    [Switch]$MinorChange,
    [Parameter(Mandatory=$False,Position=4)]
    [String]$SessionName = "DokuWikiXmlRpcDefaultSession"
  )

  If (Test-Path "variable:global:$SessionName") {
    $DokuSession = Get-Variable -Name $SessionName -Scope Global -ValueOnly
  }
  If (-not ($DokuSession.Connected)) {
    Write-Error "Unable to Set-DokuPage - Please use Connect-Dokuwiki first." -ErrorAction Stop
  }

  $XmlRpcParams = @{
    BaseUri = $DokuSession.BaseUri
    Name = "wiki.putPage"
    Params = $Page, $Content, @{sum=$Comment;minor=$($MinorChange -eq $True)}
    SessionVariable = $DokuSession.WebSessionName
    NewSession = $False
  }

  $Response = Invoke-DokuwikiXmlRpcMethod @XmlRpcParams

  Return $Response.Response

}

#endregion DokuWiki