<#
	.SYNOPSIS
	Install Chrome Extensions using the registry

	.PARAMETER ExtensionIDs
	String value of an extension ID taken from the Chrome Web Store URL for the extension

	.LINKS
 	https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions
#>
function Add-ChromeExtension
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string[]]
		$ExtensionIDs
	)

	foreach ($ExtensionID in $ExtensionIDs)
	{
		if (-not (Test-Path -Path "HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID"))
		{
			New-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID" -Force
		}
		New-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$ExtensionID" -Name update_url -PropertyType String -Value "https://clients2.google.com/service/update2/crx" -Force
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
