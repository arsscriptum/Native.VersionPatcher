
function Invoke-IsAdministrator  {  
    (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}


function Get-ScriptDirectory {
    Split-Path -Parent $PSCommandPath
}

      try{
        $IsAdministrator = Invoke-IsAdministrator 
        $ErrorDetails=''
        $ErrorOccured=$False
        $Script:Configuration = "Debug"
        if(!([string]::IsNullOrEmpty($args[0]))){
            $Script:Configuration = $args[0]
            Write-Output "Configuration ==> $Script:Configuration"
        }else{
            throw "missing argument 0"
        }
        if(!([string]::IsNullOrEmpty($args[1]))){
            $RootPath = $args[1]
            Write-Output "RootPath ==> $RootPath"
        }else{
            throw "missing argument 1"
        }
        $SolutionDirectory = (Resolve-Path $RootPath).Path
        
        $ScriptsDirectory = (Resolve-Path "$SolutionDirectory\scripts").Path
        $OutputDirectory = (Resolve-Path "$SolutionDirectory\$Configuration").Path
        $BuiltExecutable = Join-Path "$OutputDirectory" "verpatch.exe"
        $ReadmeFile  = Join-Path "$SolutionDirectory" "usage.txt"
        Write-Output "=========================================================="
        Write-Output "SolutionDirectory ==> $SolutionDirectory"
        Write-Output "ScriptsDirectory  ==> $ScriptsDirectory"
        Write-Output "OutputDirectory   ==> $OutputDirectory"
        Write-Output "=========================================================="
        [string[]]$deps = . "$PSScriptRoot\dependencies\GetDependencies.ps1" -Path "$PSScriptRoot\dependencies"
        $depscount = $deps.Count
        $deps | % {
            . "$_"
        }
        $Test = Test-Dependencies -q
        if(! ($Test) ) { throw "dependencies error"} 

        Write-Output "`n`n"
        Write-Output "=========================================================="
        Write-Output "                POST-BUILD OPERATIONS"
        Write-Output "==========================================================`n`n"


        if([string]::IsNullOrEmpty($ENV:VersionPatcherPath)){
            Set-EnvironmentVariable -Name "VersionPatcherPath" -Value "$ENV:ToolsRoot\VersionPatcher\verpatch.exe" -Scope Session
            Write-Output "[warning] VersionPatcherPath is not setup in environment variables"
            if([string]::IsNullOrEmpty($ENV:VersionPatcherPath)){ throw "cannot configure verpathc path"}
        }

        $VersionPatcherPath = "$ENV:VersionPatcherPath"

        $inf = Get-Item -Path "$BuiltExecutable"
        [DateTime]$CreatedOn = $inf.CreationTime
        $BuildDateString = $CreatedOn.GetDateTimeFormats()[13]
        [TimeSpan]$ts = [datetime]::Now - [DateTime]$CreatedOn
        $Md5Hash = (Get-FileHash "$BuiltExecutable" -Algorithm MD5).Hash
        $NewInternalName = "{0}-{1}" -f $inf.Basename, $Configuration
        
        $Log = 'Built {0:d2} hours, {1:d2} minutes and {2:d2} seconds ago' -f $ts.Hours, $ts.Minutes, $ts.Seconds
        $NewDescription = "A command-line utility that reads and write, updates the version information in a Windows binary file."
        $BuildComment = '{2} build created on {0} using the pc {1}. MD5: {3}' -f $BuildDateString, "$ENV:COMPUTERNAME", $Configuration, $Md5Hash
        
        $VerPatchCompatible = Test-VerPatchCompatible "$BuiltExecutable"
        if($VerPatchCompatible -eq $False){
            Write-Output "[IMPORTANT] NEW BUILD `"$BuiltExecutable`" does not have binary embedded version information. Initializing version info..."
            $LogString = @"
Setting Version Values
    VersionSring $VersionSring
    Description  $NewDescription
    ProductName  $NewInternalName
    SpecialBuild True
    RESSOURCE    `"$ReadmeFile`"
"@
            Write-Output "$LogString"
            $VersionSring = "1.0.0.1"
            &"$ENV:VersionPatcherPath" "$BuiltExecutable" '/va' "$VersionSring" '/s' 'desc' "`"$NewDescription`""   `
                '/s' 'ProductName' "$NewInternalName" `
                '/s' 'PrivateBuild' "$Md5Hash" `
                '/rf' '#64' "$ReadmeFile" `
                '/pv' "$VersionSring" 

           $VerPatchCompatible = Test-VerPatchCompatible "$BuiltExecutable"

           [string[]]$VersionData = &"$ENV:VersionPatcherPath" "$BuiltExecutable"
            $LogString = @"
   === REPORT ===
File `"$BuiltExecutable`"
Enabled VerPatchCompatibility $VerPatchCompatible
Version Data 

"@
            $VersionData | % {
                $LogString += "`t$_`n"
            }
           Write-Output "$LogString"
           if(!($VerPatchCompatible)){
                throw "Error when updating version"
           }
        }else{
            [string[]]$VersionData = &"$VersionPatcherPath" "$BuiltExecutable"
            [Version]$CurrentVersion = Get-VerPatchProperty "$BuiltExecutable" 'Version'
            $NewBuildVersion = $CurrentVersion.Build + 1
            $NewVersion = [version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $NewBuildVersion, $CurrentVersion.Revision)
            [string]$VersionString = $NewVersion.ToString()
            &"$ENV:VersionPatcherPath" "$BuiltExecutable" "$VersionString" '/s' 'desc' "`"$NewDescription`""   `
                '/s' 'ProductName' "$NewInternalName" `
                '/s' 'PrivateBuild' "$Md5Hash" `
                '/rf' '#64' "$ReadmeFile" `
                '/pv' "$VersionSring" 
        }
        Write-Output "COPYING `"$BuiltExecutable`" => `"$VersionPatcherPath`""
        Copy-Item "$BuiltExecutable" "$VersionPatcherPath" -Force -ErrorAction Stop



        Write-Output "=========================================================="
        Write-Output "        POST-BUILD OPERATIONS COMPLETED SUCCESFULLY       "
        Write-Output "==========================================================`n`n"


    }catch{
        Write-Error "$_"
        $ErrorDetails= "$_"
        $ErrorOccured=$True
    }
    if($ErrorOccured){
        Start-Sleep 2
        throw "$ErrorDetails"
    }