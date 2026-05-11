<#
	.SYNOPSIS
	Add extensions to Chrome automatically

	.PARAMETER ExtentionIDs
	Extention ID from URL on Chrome Web Store

	.NOTES
	Enable Chrome Extensions Developer Mode first on chrome://extensions
	Open chrome://extensions to load unpacked extensions from "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions" folder
#>
function Add-ChromeExtension
{
	[CmdletBinding()]
	param
	(
		[string[]]
		$ExtentionIDs
	)

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	foreach ($ExtentionID in $ExtentionIDs)
	{
		# Create a folder to expand all files to
		if (-not (Test-Path -Path "$env:SystemDrive\Extensions\$ExtentionID"))
		{
			New-Item -Path "$env:SystemDrive\Extensions\$ExtentionID" -ItemType Directory -Force
		}

		# Downloading extension
		$Parameters = @{
			Uri             = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=138.0&acceptformat=crx3&x=id%3D$($ExtentionID)%26uc"
			OutFile         = "$env:SystemDrive\Extensions\$ExtentionID.crx"
			UseBasicParsing = $true
			Verbose         = $true
		}
		Invoke-WebRequest @Parameters

		# Expand extension
		& "$env:SystemRoot\System32\tar.exe" -xvf "$env:SystemDrive\Extensions\$ExtentionID.crx" -C "$env:SystemDrive\Extensions\$ExtentionID"

		# "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" is where all extensions are located
		if (-not (Test-Path -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"))
		{
			New-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" -ItemType Directory -Force
		}
		Copy-Item -Path "$env:SystemDrive\Extensions\$ExtentionID" -Destination "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" -Recurse -Force
	}

	Remove-Item -Path "$env:SystemDrive\Extensions" -Recurse -Force

	Invoke-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
}

$Parameters = @{
	ExtentionIDs = @(
		# https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh
		"ddkjiahejlhfcafbddmgiahcphecmpfh"
		# https://chrome.google.com/webstore/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone
		"mnjggcdmjocbbbhaepdhchncahnbgone"
	)
}
Add-ChromeExtension @Parameters
