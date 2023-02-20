<#
	.SYNOPSIS
	Add extensions to Chrome automatically

	.PARAMETER ExtentionIDs
	Copy an ID from extention's URL on Chrome Web Store

	.EXAMPLE
	$Parameters = @{
		ExtentionIDs = @(
			"cjpalhdlnbpafiamejdnhcphjbkeiagm",
			"dhdgffkkebhmkfjojejmpbldmpobfkfo",
			"mnjggcdmjocbbbhaepdhchncahnbgone"
		)
	}
	Add-ChromeExtension @Parameters

	.NOTES
	Enable Chrome Extensions Developer Mode first

	.NOTES
	Enable extension manually by opening the chrome://extensions page to load unpacked extensions one by one
	by selecting their folders (where the manifest is) in "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions"
#>
function Add-ChromeExtension
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string[]]
		$ExtentionIDs
	)

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"

	foreach ($ExtentionID in $ExtentionIDs)
	{
		# Create a folder to expand all files to
		if (-not (Test-Path -Path "$DownloadsFolder\Extensions\$ExtentionID"))
		{
			New-Item -Path "$DownloadsFolder\Extensions\$ExtentionID" -ItemType Directory -Force
		}

		# Downloading extension
		$Parameters = @{
			Uri             = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=110.0&acceptformat=crx3&x=id%3D$($ExtentionID)%26uc"
			OutFile         = "$DownloadsFolder\Extensions\$ExtentionID.crx"
			UseBasicParsing = $true
			Verbose         = $true
		}
		Invoke-WebRequest @Parameters

		# Copy file and rename it into .zip
		Get-Item -Path "$DownloadsFolder\Extensions\$ExtentionID.crx" -Force | Foreach-Object -Process {
			$NewName = $_.FullName -replace ".crx", ".zip"
			Copy-Item -Path $_.FullName -Destination $NewName -Force
		}

		# Expand extension
		& tar.exe -x -f "$DownloadsFolder\Extensions\$ExtentionID.crx" -C "$DownloadsFolder\Extensions\$ExtentionID" -v

		# "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" is where all extensions are located
		if (-not (Test-Path -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"))
		{
			New-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" -ItemType Directory -Force
		}
		Copy-Item -Path "$DownloadsFolder\Extensions\$ExtentionID" -Destination "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" -Recurse -Force
	}

	if (Test-Path -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions\dhdgffkkebhmkfjojejmpbldmpobfkfo")
	{
		# Open https://greasyfork.org/ru/scripts/19993-ru-adlist-js-fixes
		Start-Process -FilePath "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" -ArgumentList "https://greasyfork.org/ru/scripts/19993-ru-adlist-js-fixes"
	}

	Remove-Item -Path "$DownloadsFolder\Extensions" -Recurse -Force

	Invoke-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
}

$Parameters = @{
	ExtentionIDs = @(
		# https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
		"cjpalhdlnbpafiamejdnhcphjbkeiagm",
		# https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo
		"dhdgffkkebhmkfjojejmpbldmpobfkfo",
		# https://chrome.google.com/webstore/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone
		"mnjggcdmjocbbbhaepdhchncahnbgone"
	)
}
Add-ChromeExtension @Parameters
