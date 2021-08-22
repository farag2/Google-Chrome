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

	# Create a folder to expand all files to
	$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
	if (-not (Test-Path -Path "$DownloadsFolder\Extensions"))
	{
		New-Item -Path "$DownloadsFolder\Extensions" -ItemType Directory -Force
	}

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Download 7ZIP 21.03 x64 due to .crx cannot be expanded: neither with System.IO.Compression.FileSystem, nor with the Expand-Archive cmdlet
	$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
	$Parameters = @{
		Uri = "https://www.7-zip.org/a/7z2103-x64.msi"
		OutFile = "$DownloadsFolder\Extensions\7z2103-x64.msi"
		Verbose = [switch]::Present
	}
	Invoke-WebRequest @Parameters

	# Expand 7z2103-x64.msi to 7zip folder
	$Arguments = @(
		"/a `"$DownloadsFolder\Extensions\7z2103-x64.msi`""
		"TARGETDIR=`"$DownloadsFolder\Extensions\7zip`""
		"/qb"
	)
	Start-Process "msiexec" -ArgumentList $Arguments -Wait

	foreach ($ExtentionID in $ExtentionIDs)
	{
		# Downloading extension
		$Parameters = @{
			Uri     = "https://clients2.google.com/service/update2/crx?response=redirect&os=win&arch=x86-64&os_arch=x86-64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=unknown&prodversion=52.0.2743.116&acceptformat=crx2,crx3&x=id%3D$($ExtentionID)%26uc"
			OutFile = "$DownloadsFolder\Extensions\$ExtentionID.crx"
			Verbose = [switch]::Present
		}
		Invoke-WebRequest @Parameters

		# Copy file and rename it into .zip
		Get-Item -Path "$DownloadsFolder\Extensions\$ExtentionID.crx" -Force | Foreach-Object -Process {
			$NewName = $_.FullName -replace ".crx", ".zip"
			Copy-Item -Path $_.FullName -Destination $NewName -Force
		}

		$Arguments = @(
			"x"
			"$DownloadsFolder\Extensions\$ExtentionID.crx"
			"-o`"$DownloadsFolder\Extensions\$ExtentionID`""
		)
		Start-Process "$DownloadsFolder\Extensions\7zip\Files\7-Zip\7z.exe" -ArgumentList $Arguments -Wait

		# "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" is where all extensions are located
		if (-not (Test-Path -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"))
		{
			New-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" -ItemType Directory -Force
		}
		Copy-Item -Path "$DownloadsFolder\Extensions\$ExtentionID" -Destination "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions" -Recurse -Force
	}

	# Open the chrome://extensions page in a new tab to activate all installed extensions manually
	# Start-Process -FilePath "$env:ProgramFiles\Google\Chrome\Application\chrome.exe" -ArgumentList "-new-tab chrome://extensions/"

	Remove-Item -Path "$DownloadsFolder\Extensions" -Recurse -Force
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
