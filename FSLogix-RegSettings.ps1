
param(
    [string]$sharepath=""
        
)

$registrypath = "HKLM:\SOFTWARE\FSLogix"
$regpathprofiles = "HKLM:\SOFTWARE\FSLogix\Profiles"


if (!(Test-Path $regpathprofiles)) {
    Write-Host "Creating 'Profiles' Key at $registrypath"
    New-Item -Path $registrypath -Name "Profiles" | Out-Null
} else {
    Write-Host "$regpathprofiles already exists"
}

New-ItemProperty -Path $regpathprofiles -Name Enabled -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $regpathprofiles -Name VHDLocations -Value $sharepath -PropertyType MultiString -Force
New-ItemProperty -Path $regpathprofiles -Name PreventLoginWithFailure -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $regpathprofiles -Name PreventLoginWithTempProfile -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path $regpathprofiles -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -PropertyType DWORD -Force