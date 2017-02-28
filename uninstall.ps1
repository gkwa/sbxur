<#

* TODO Kill off parent processes that have open handles on folders

Use handle.exe to detect open file in filder I want to delete and kill
parent process.

* TODO deal with write protect, currently script doesn't check it

Parse this
#+BEGIN_SRC
C:\Windows>fbwfmgr
File-based write filter configuration for the current session:
    filter state: disabled.

File-based write filter configuration for the next session:
    filter state: disabled.

C:\Windows>
#+END_SRC

** powershell clean whitespace

powershell
powershell clean whitespace

* TODO deal with 9400 by getting one-off shortcuts
* TODO deal with Streambox folder, mabye zip it up
* TODO deal with Apache_old.zip, Apache_old1.zip

#>

Function Test-RegistryValue($regkey, $name) {
	Get-ItemProperty $regkey $name -ErrorAction SilentlyContinue | Out-Null
	$?
}


$uninstallers = `
  'C:\ABN\Uninstall.exe',
'C:\Streambox\SLS_Decoder\Uninstall.exe',
'C:\Program Files\Streambox\Streambox WebUI\Uninstall.exe',
'C:\Program Files (x86)\Streambox\Streambox WebUI\Uninstall.exe'

$deletelist = 'C:\Streambox\AJA Diagnostics',
'C:\Streambox\Xena2Driver',
'C:\Streambox\XenaHDDriver',
'C:\Streambox\XenaHDDriver',
"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Streambox\AJA Diagnostic tools.lnk",
"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Streambox\Disable Write Protect.lnk",
"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Streambox\Enable Write Protect.lnk",
"$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Streambox\Streambox ACT-L3.lnk",
"$env:PUBLIC\Desktop\Streambox ACT-L3.lnk"

# SBT3-9400: Apache must run as console app, so start it from shortcut
$deletelist += "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Apache HTTP Server.lnk"

# fixme: how to remove this?
# C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Streambox

# remove-itemproperty -path hklm:\Software\Microsoft\Windows\CurrentVersion\Run -name 'sleep_before_startup' | Out-Null
$key = 'hklm:\Software\Microsoft\Windows\CurrentVersion\Run'
$name = 'sleep_before_startup'
if(Test-RegistryValue($key, $name)){
	remove-itemproperty -path $key -name $name | Out-Null
}

# remove-itemproperty -path hklm:\Software\Microsoft\Windows\CurrentVersion\Run -name 'Streambox ACT-L3' | Out-Null
$key = 'hklm:\Software\Microsoft\Windows\CurrentVersion\Run'
$name = 'Streambox ACT-L3'
if(Test-RegistryValue($key, $name)){
	remove-itemproperty -path $key -name $name | Out-Null
}


# Kill cmd.exe if its the parent of transport or encoder
Get-Process | Where-Object {
	$_.Name -like '*transport*' -or
	$_.Name -like '*encoder*' -or
	$_.Name -like 'httpd.exe' -or
	$_.Path -like '*streambox*'
} | ForEach-Object {
    $p = $_;
    $mypid = $p.Id
    $filter = 'processid = {0}' -f $p.Id
    $parentpid=(gwmi win32_process -Filter $filter).parentprocessid
    if($parentpid) {
        $filter = 'processid = {0}' -f $parentpid
        $grandparentpid=(gwmi win32_process -Filter $filter).parentprocessid
        write-host "pid=$mypid parentpid=$parentpid parentbatpid=$parentbatpid grandparentpid=$grandparentpid "

        # Kill parent process only if its cmd.exe
        Get-Process -id $parentpid -EA 0 |
          Where-Object {
              $_.Name -like 'cmd*'
          } | Stop-Process -force
    }
    Stop-Process -force $mypid
}

# Kill processes before delete
Get-Process |
  where-object {
	  $_.Name -like '*transport*' -or
	  $_.Name -like '*encoder*' -or
	  $_.Name -like 'httpd' -or
	  $_.Path -like '*streambox*'
  } | % { try{ $_.Kill() }catch{} }

foreach ($uninstaller in $uninstallers) {
	if(Test-Path $uninstaller){
		Start-Process $uninstaller /S
	}
}

Set-Location $env:temp
foreach ($filedir in $deletelist) {
	if(Test-Path $filedir){
		remove-item $filedir -recurse
	}
}

# #############################
# TODO
# #############################
# remove this
# HKEY_LOCAL_MACHINE\SOFTWARE\Apache Software Foundation\Apache\2.2.18

# #############################
# Remove \Run values from registry
# #############################
$key = "hklm:\Software\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -ea SilentlyContinue -Path $key -Name "Streambox ACT-L3"
Remove-ItemProperty -ea SilentlyContinue -Path $key -Name sleep_before_startup

# Save license, but delete all other files
Get-ChildItem -Path  'C:\Streambox' -Recurse -exclude '*.lic' |
  Select -ExpandProperty FullName | Remove-Item -force
