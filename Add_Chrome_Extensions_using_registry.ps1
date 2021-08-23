<#
	.SYNOPSIS
	Install Chrome Extensions using the registry

	.PARAMETER ExtensionID
	String value of an extension ID taken from the Chrome Web Store URL for the extension

	.EXAMPLE Install uBlock Origin and Tampermonkey
	New-ChromeExtension -ExtensionID @("cjpalhdlnbpafiamejdnhcphjbkeiagm", "dhdgffkkebhmkfjojejmpbldmpobfkfo") -Verbose

	.NOTES
	In order extensions work you need to store the .crx files
#>
function New-ChromeExtension
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string[]]
		$ExtensionIDs
	)

	# Create a folder to expand all files to
	$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
	if (-not (Test-Path -Path "$DownloadsFolder\Extensions"))
	{
		New-Item -Path "$DownloadsFolder\Extensions" -ItemType Directory -Force
	}

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Download 7ZIP 21.03 x64 due to .crx cannot be expanded: neither with System.IO.Compression.FileSystem, nor with the Expand-Archive cmdlet
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

	foreach ($ExtensionID in $ExtensionIDs)
	{
		$Parameters = @{
			Uri     = "https://clients2.google.com/service/update2/crx?response=redirect&os=win&arch=x86-64&os_arch=x86-64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=unknown&prodversion=52.0.2743.116&acceptformat=crx2,crx3&x=id%3D$($ExtensionID)%26uc"
			OutFile = "$DownloadsFolder\Extensions\$ExtensionID.crx"
			Verbose = [switch]::Present
		}
		Invoke-WebRequest @Parameters

		# Copy file and rename it into .zip
		Get-Item -Path "$DownloadsFolder\Extensions\$ExtensionID.crx" -Force | Foreach-Object -Process {
			$NewName = $_.FullName -replace ".crx", ".zip"
			Copy-Item -Path $_.FullName -Destination $NewName -Force
		}

		$Arguments = @(
			"x",
			"$DownloadsFolder\Extensions\$ExtensionID.crx",
			"-o`"$DownloadsFolder\Extensions\$ExtensionID`"",
			"-y"
		)
		Start-Process "$DownloadsFolder\Extensions\7zip\Files\7-Zip\7z.exe" -ArgumentList $Arguments -Wait

		# Get the version
		$ExtensionVersion = (Get-Content -Path "$DownloadsFolder\Extensions\$ExtensionID\manifest.json" -Encoding Default -Force | ConvertFrom-Json).version

		# https://www.chromium.org/administrators/pre-installed-extensions
		# https://support.google.com/chrome/a/answer/187948
		if (-not (Test-Path -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID))
		{
			New-Item -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID -Force
		}
		New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID -Name path -PropertyType String -Value "$DownloadsFolder\Extensions\$ExtensionID.crx" -Force
		New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID -Name version -PropertyType String -Value $ExtensionVersion -Force

		Remove-Item -Path "$DownloadsFolder\Extensions\$ExtensionID.zip", "$DownloadsFolder\Extensions\$ExtensionID" -Recurse -Force
	}

	Remove-Item -Path "$DownloadsFolder\Extensions\7zip", "$DownloadsFolder\Extensions\7z2103-x64.msi" -Recurse -Force
}
New-ChromeExtension -ExtensionID @("cjpalhdlnbpafiamejdnhcphjbkeiagm", "dhdgffkkebhmkfjojejmpbldmpobfkfo") -Verbose
