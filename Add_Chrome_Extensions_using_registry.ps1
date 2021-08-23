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
		Path        = "C:\Users\test\Downloads\Extensions"
		Verbose     = [switch]::Present
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

	# Download 7ZIP 21.03 x64 due to .crx cannot be expanded: neither with System.IO.Compression.FileSystem, nor with the Expand-Archive cmdlet
	$Parameters = @{
		Uri = "https://www.7-zip.org/a/7z2103-x64.msi"
		OutFile = "$Path\7z2103-x64.msi"
		Verbose = [switch]::Present
	}
	Invoke-WebRequest @Parameters

	# Expand 7z2103-x64.msi to 7zip folder
	$Arguments = @(
		"/a `"$Path\7z2103-x64.msi`""
		"TARGETDIR=`"$Path\7zip`""
		"/qb"
	)
	Start-Process "msiexec" -ArgumentList $Arguments -Wait

	foreach ($ExtensionID in $ExtensionIDs)
	{
		$Parameters = @{
			Uri     = "https://clients2.google.com/service/update2/crx?response=redirect&os=win&arch=x86-64&os_arch=x86-64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=unknown&prodversion=52.0.2743.116&acceptformat=crx2,crx3&x=id%3D$($ExtensionID)%26uc"
			OutFile = "$Path\$ExtensionID.crx"
			Verbose = [switch]::Present
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

	Remove-Item -Path "$Path\7zip", "$Path\7z2103-x64.msi" -Recurse -Force
}
$Parameters = @{
	ExtensionID = @(
		"cjpalhdlnbpafiamejdnhcphjbkeiagm",
		"dhdgffkkebhmkfjojejmpbldmpobfkfo"
	)
	Path        = "C:\Users\test\Downloads\Extensions"
	Verbose     = [switch]::Present
}
Add-ChromeExtension @Parameters
