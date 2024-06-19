


function Set-AppVersionInfo  {  
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$True, Position=0)]
        [ValidateScript({Test-Path $_})]
        [string]$Path
    )

    $NewInternalName="sdelete pname"
    $ReadmeFile  = ""
    $NewDescription="My Personal Software"
    $VersionSring = "1.0.0.1"
    $Md5Hash=(Get-FileHash $Path).Hash

    &"$ENV:VersionPatcherPath" "$f" '/va' "$VersionSring" '/s' 'desc' "$NewDescription"   `
                     '/s' 'ProductName' "$NewInternalName" `
                     '/s' 'PrivateBuild' "$Md5Hash" `
                     '/pv' "$VersionSring"
    #                 '/rf' '#64' "$ReadmeFile" `
                     
}

