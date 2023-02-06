<#
	.SYNOPSIS
	Install Chrome Extensions using the registry

	.PARAMETER ExtensionIDs
	String value of an extension ID taken from the Chrome Web Store URL for the extension

	.PARAMETER Path
	A path where extensions will be stored

	.EXAMPLE Install uBlock Origin and Tampermonkey
	$Parameters = @{
		ExtensionID = @(
			"cjpalhdlnbpafiamejdnhcphjbkeiagm",
			"dhdgffkkebhmkfjojejmpbldmpobfkfo"
		)
		Path    = "C:\Users\test\Downloads\Extensions"
		Verbose = $true
	}
	Add-ChromeExtension @Parameters

	.NOTES
	In order extensions work you need to store the .crx files
#>
function Add-ChromeExtension
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string[]]
		$ExtensionIDs,

		[Parameter(Mandatory = $true)]
		[string]
		$Path
	)

	# Create a folder to expand all files to
	if (-not (Test-Path -Path $Path))
	{
		New-Item -Path $Path -ItemType Directory -Force
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
		"/a `"$Path\7-Zip.msi`""
		"TARGETDIR=`"$Path\7zip`""
		"/qb"
	)
	Start-Process "msiexec" -ArgumentList $Arguments -Wait

	foreach ($ExtensionID in $ExtensionIDs)
	{
		$Parameters = @{
			Uri     = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=49.0&acceptformat=crx3&x=id%3D$($ExtentionID)%26uc"
			OutFile = "$Path\$ExtensionID.crx"
			Verbose = $true
		}
		Invoke-WebRequest @Parameters

		# Copy file and rename it into .zip
		Get-Item -Path "$Path\$ExtensionID.crx" -Force | Foreach-Object -Process {
			$NewName = $_.FullName -replace ".crx", ".zip"
			Copy-Item -Path $_.FullName -Destination $NewName -Force
		}

		$Arguments = @(
			"x",
			"$Path\$ExtensionID.crx",
			"-o`"$Path\$ExtensionID`"",
			"-y"
		)
		Start-Process "$Path\7zip\Files\7-Zip\7z.exe" -ArgumentList $Arguments -Wait

		# Get the version
		$ExtensionVersion = (Get-Content -Path "$Path\$ExtensionID\manifest.json" -Encoding Default -Force | ConvertFrom-Json).version

		# https://www.chromium.org/administrators/pre-installed-extensions
		# https://support.google.com/chrome/a/answer/187948
		if (-not (Test-Path -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID))
		{
			New-Item -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID -Force
		}
		New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID -Name path -PropertyType String -Value "$Path\$ExtensionID.crx" -Force
		New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID -Name version -PropertyType String -Value $ExtensionVersion -Force

		Remove-Item -Path "$Path\$ExtensionID.zip", "$Path\$ExtensionID" -Recurse -Force
	}

	Remove-Item -Path "$Path\7zip", "$Path\7-Zip.msi" -Recurse -Force
}
$Parameters = @{
	ExtensionID = @(
		"cjpalhdlnbpafiamejdnhcphjbkeiagm",
		"dhdgffkkebhmkfjojejmpbldmpobfkfo"
	)
	Path        = "C:\Users\test\Downloads\Extensions"
	Verbose     = $true
}
Add-ChromeExtension @Parameters
