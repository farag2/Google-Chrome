# https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
$LatestRelease = (Invoke-RestMethod -Uri "https://api.github.com/repos/gorhill/uBlock/releases/latest").tag_name
$Parameters = @{
	Uri     = "https://clients2.google.com/service/update2/crx?response=redirect&os=win&arch=x86-64&os_arch=x86-64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=unknown&prodversion=52.0.2743.116&acceptformat=crx2,crx3&x=id%3Dcjpalhdlnbpafiamejdnhcphjbkeiagm%26uc"
	OutFile = "$DownloadsFolder\uBlock_Origin_$($LatestRelease).crx"
	Verbose = [switch]::Present
}
Invoke-WebRequest @Parameters

# .crx cannot be expanded: neither with System.IO.Compression.FileSystem, nor with the Expand-Archive cmdlet
# https://www.chromium.org/administrators/pre-installed-extensions
# https://support.google.com/chrome/a/answer/187948
if (-not (Test-Path -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm))
{
	New-Item -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm -Force
}
# Move the .crx file to any folder and change the value
New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm -Name path -PropertyType String -Value "$DownloadsFolder\uBlock_Origin_$($LatestRelease).crx" -Force
New-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\cjpalhdlnbpafiamejdnhcphjbkeiagm -Name version -PropertyType String -Value $LatestRelease -Force
