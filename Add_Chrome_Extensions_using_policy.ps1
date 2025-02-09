<#
	.SYNOPSIS
	Install Chrome Extensions using the registry policy

	.PARAMETER ExtensionID
	String value of an extension ID taken from the Chrome Web Store URL for the extension

	.EXAMPLE Install uBlock Origin
	Add-ChromeExtension -ExtensionID @("cjpalhdlnbpafiamejdnhcphjbkeiagm") -Hive HKLM -Verbose

	.NOTES
	if you remove the HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist key all extensions will be uninstalled

	.LINK
	https://chromeenterprise.google/policies/#ExtensionInstallForcelist
#>
function Add-ChromeExtension
{
	[cmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[String[]]
		$ExtensionIDs
	)

	foreach ($ExtensionID in $ExtensionIDs)
	{
		if (-not (Test-Path -Path "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist"))
		{
			[int]$Count = 0
			New-Item -Path "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist" -Force
		}
		else
		{
			[int]$Count = (Get-Item -Path "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist").Property.Count
		}

		$Name = $Count + 1
		New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist" -Name $Name -Value "$ExtensionID;https://clients2.google.com/service/update2/crx" -PropertyType String -Force
	}
}
Add-ChromeExtension -ExtensionIDs @(
	# https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh
	"ddkjiahejlhfcafbddmgiahcphecmpfh",
	# https://chrome.google.com/webstore/detail/sponsorblock-for-youtube/mnjggcdmjocbbbhaepdhchncahnbgone
	"mnjggcdmjocbbbhaepdhchncahnbgone"
	# https://chrome.google.com/webstore/detail/return-youtube-dislike/gebbhagfogifgggkldgodflihgfeippi
	"gebbhagfogifgggkldgodflihgfeippi"
)
