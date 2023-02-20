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
		Path    = "D:\Downloads\Extensions"
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

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	foreach ($ExtensionID in $ExtensionIDs)
	{
		$Parameters = @{
			Uri     = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=49.0&acceptformat=crx3&x=id%3D$($ExtensionID)%26uc"
			OutFile = "$Path\$ExtensionID.crx"
			Verbose = $true
		}
		Invoke-WebRequest @Parameters

		# Copy file and rename it into .zip
		Get-Item -Path "$Path\$ExtensionID.crx" -Force | Foreach-Object -Process {
			$NewName = $_.FullName -replace ".crx", ".zip"
			Copy-Item -Path $_.FullName -Destination $NewName -Force
		}

		# Create a folder to expand all files to
		if (-not (Test-Path -Path "$Path\$ExtensionID"))
		{
			New-Item -Path "$Path\$ExtensionID" -ItemType Directory -Force
		}

		# Expand extension
		& tar.exe -x -f "$Path\$ExtensionID.crx" -C "$Path\$ExtensionID" -v

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
}
$Parameters = @{
	ExtensionID = @(
		# https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
		"cjpalhdlnbpafiamejdnhcphjbkeiagm",
		# https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo
		"dhdgffkkebhmkfjojejmpbldmpobfkfo"
		# https://chrome.google.com/webstore/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone
		"mnjggcdmjocbbbhaepdhchncahnbgone"
		# https://chrome.google.com/webstore/detail/return-youtube-dislike/gebbhagfogifgggkldgodflihgfeippi
		"gebbhagfogifgggkldgodflihgfeippi"
	)
	Path    = "D:\Downloads\Extensions"
	Verbose = $true
}
Add-ChromeExtension @Parameters
