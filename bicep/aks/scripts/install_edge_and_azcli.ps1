$ProgressPreference = 'SilentlyContinue'
mkdir -Path $env:temp\azcli -erroraction SilentlyContinue | Out-Null
mkdir -Path $env:temp\git -erroraction SilentlyContinue | Out-Null
mkdir -Path $env:temp\edgeinstall -erroraction SilentlyContinue | Out-Null
$edge = join-path $env:temp\edgeinstall MicrosoftEdgeEnterpriseX64.msi -erroraction SilentlyContinue 
$azcli = join-path $env:temp\azcli azcli.msi -erroraction SilentlyContinue
$git = join-path $env:temp\git git.exe -erroraction SilentlyContinue
Invoke-WebRequest 'https://aka.ms/installazurecliwindows' -OutFile $azcli
Invoke-WebRequest 'https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/a2662b5b-97d0-4312-8946-598355851b3b/MicrosoftEdgeEnterpriseX64.msi' -OutFile $edge
Start-Process "$edge" -ArgumentList "/quiet /passive" -erroraction SilentlyContinue | Out-Null
Start-Sleep 120
Start-Process "$azcli" -ArgumentList "/quiet /passive" -erroraction SilentlyContinue | Out-Null
Start-Sleep 120 
Invoke-WebRequest 'https://github.com/git-for-windows/git/releases/download/v2.36.0.windows.1/Git-2.36.0-32-bit.exe' -OutFile $git
Start-Process "$git" -ArgumentList "/VERYSILENT /NORESTART" -erroraction SilentlyContinue | Out-Null