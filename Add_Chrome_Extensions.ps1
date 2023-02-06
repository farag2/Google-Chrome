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

	# Get the latest 7-Zip download URL
	$Parameters = @{
		Uri             = "https://sourceforge.net/projects/sevenzip/best_release.json"
		UseBasicParsing = $true
		Verbose         = $true
	}
	$bestRelease = (Invoke-RestMethod @Parameters).platform_releases.windows.filename.replace("exe", "msi")

	# Download the latest 7-Zip x64
	$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
	$Parameters = @{
		Uri             = "https://nchc.dl.sourceforge.net/project/sevenzip$($bestRelease)"
		OutFile         = "$DownloadsFolder\7-Zip.msi"
		UseBasicParsing = $true
		Verbose         = $true
	}
	Invoke-WebRequest @Parameters

	# Expand 7-Zip
	$Arguments = @(
		"/a `"$DownloadsFolder\7-Zip.msi`""
		"TARGETDIR=`"$DownloadsFolder\Extensions\7-zip`""
		"/qb"
	)
	Start-Process "msiexec" -ArgumentList $Arguments -Wait

	foreach ($ExtentionID in $ExtentionIDs)
	{
		# Downloading extension
		$Parameters = @{
			Uri             = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=49.0&acceptformat=crx3&x=id%3D$($ExtentionID)%26uc"
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

		$Arguments = @(
			"x",
			"$DownloadsFolder\Extensions\$ExtentionID.crx",
			"-o`"$DownloadsFolder\Extensions\$ExtentionID`"",
			"-y"
		)
		Start-Process "$DownloadsFolder\Extensions\7-zip\Files\7-Zip\7z.exe" -ArgumentList $Arguments -Wait

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

	# Set tp clipboard the full path to extention to paste
	"$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions\$ExtentionID" | Set-Clipboard
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
