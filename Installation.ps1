Import-Module "$applicationPath\installation\source\Installation.psm1"
function script:Update-CheckboxStatus
{
    $jsonSettingsFilePath = "$applicationPath\installation\source\InstallationSettings.JSON"
    $jsonContent = Get-Content -Raw $jsonSettingsFilePath | ConvertFrom-Json
    
    $window.FindName("gridSettingsInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "chkbox*" } | 
    ForEach-Object {
        $checkbox = $_
        $checkboxName = $checkbox.Name
        $status = if ($checkbox.IsChecked) { 1 } else { 0 }
        $jsonContent.$checkboxName.status = $status
    }

    $window.FindName("gridInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "chkbox*" } | 
    ForEach-Object {
        $checkbox = $_
        $checkboxName = $checkbox.Name
        $status = if ($checkbox.IsChecked) { 1 } else { 0 }
        $jsonContent.$checkboxName.status = $status
    }

    $window.FindName("gridSettingsInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.ComboBox] -and $_.Name -like "CbBox*" } | 
    ForEach-Object {
        $comboBox = $_
        $comboBoxName = $comboBox.Name
        $selectedValue = $comboBox.SelectedItem.Content

        if ($selectedValue) 
        {
            $jsonContent.$comboBoxName.Status = $selectedValue
        } 
    }

    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content $jsonSettingsFilePath
}

function script:Install-SoftwareMenuApp($softwareName)
{
    $jsonAppsFilePath = "$applicationPath\installation\source\InstallationApps.JSON"
    $jsonString = Get-Content -Raw $jsonAppsFilePath
    $appsInfo = ConvertFrom-Json $jsonString
    $appNames = $appsInfo.psobject.Properties.Name
    if ($appNames -contains $softwareName) 
    {
        $appsInfo.$softwareName.path64 = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.path64)
        $appsInfo.$softwareName.path32 = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.path32)
        $appsInfo.$softwareName.pathAppData = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.pathAppData)
        $appsInfo.$softwareName.RemoteName = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.RemoteName)
    }

    $status = Test-SoftwarePresence $appsInfo.$softwareName
    if ($status) 
    {
        $formControls.rtbOutput_InstallationConfig.AppendText("$softwareName est déja installé`r")
    }
    else 
    {
        Install-Software $appsInfo.$softwareName
        $status = Test-SoftwarePresence $appsInfo.$softwareName
        if ($status) 
        {
            $formControls.rtbOutput_InstallationConfig.AppendText("$softwareName a été installé`r")
        }
        else 
        {
            $formControls.rtbOutput_InstallationConfig.AppendText("$softwareName n'a pas été installé`r")
        }   
    }      
} 

#Logiciels à cocher automatiquement
$manufacturerBrand = Get-Manufacturer
if($manufacturerBrand -match 'LENOVO')
{
    $formControls.chkboxLenovoVantage.IsChecked = $true
    $formControls.chkboxLenovoSystemUpdate.IsChecked = $true
}
elseif($manufacturerBrand -match 'HP')
{        
    $formControls.chkboxHPSA.IsChecked = $true
}
elseif($manufacturerBrand -match 'DELL')
{
    $formControls.chkboxDellsa.IsChecked = $true
}
elseif($manufacturerBrand -like '*Micro-Star*')
{
    $formControls.chkboxMSICenter.IsChecked = $true
}
$videoController = Get-WmiObject win32_videoController | Select-Object -Property name
if($videoController -match 'NVIDIA')
{
    $formControls.chkboxGeForce.IsChecked = $true
}

#Boutons
$formControls.chkboxRemove.Add_Checked({
    $formControls.chkboxDeleteFolder.IsChecked = $true
    $formControls.chkboxDeleteBin.IsChecked = $true
})
$formControls.chkboxRemove.Add_Unchecked({
    $formControls.chkboxDeleteFolder.IsChecked = $false
    $formControls.chkboxDeleteBin.IsChecked = $false
})
$formControls.btnGo_InstallationConfig.Add_Click({
    script:Update-CheckboxStatus

    if($formControls.chkboxDeleteFolder.IsChecked)
    {
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonContent.RemoveDownloadFolder.Status = "1"
        $jsonContent | ConvertTo-Json | Set-Content $jsonFilePath
    }
    elseif($formControls.chkboxDeleteFolder.IsChecked -eq $false)
    { 
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonContent.RemoveDownloadFolder.Status = "0"
        $jsonContent | ConvertTo-Json | Set-Content $jsonFilePath
    }

    if($formControls.chkboxDeleteBin.IsChecked)
    {
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonContent.EmptyRecycleBin.Status = "1"
        $jsonContent | ConvertTo-Json | Set-Content $jsonFilePath
    }
    elseif($formControls.chkboxDeleteBin.IsChecked -eq $false)
    { 
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonContent.EmptyRecycleBin.Status = "0"
        $jsonContent | ConvertTo-Json | Set-Content $jsonFilePath
    }
    Remove-Item -Path "$env:SystemDrive\_Tech\Applications\source\Menu.lock" -Force 
    start-Process "$global:appPathSource\caffeine64.exe"
    $window.Close()
    . $env:SystemDrive\_Tech\Applications\installation\source\InstallationOutput.ps1
})

$formControls.btnReturn_InstallationConfig.Add_Click({
    Open-Menu #changé
})
$formControls.btnQuit_InstallationConfig.Add_Click({
    Remove-StoolboxApp #changé
})
$formControls.btnAdobe.Add_Click({
    script:Install-SoftwareMenuApp "Adobe Reader"
})
$formControls.btnGoogleChrome.Add_Click({
    script:Install-SoftwareMenuApp "Google Chrome"
})
$formControls.btnTeamviewer.Add_Click({
    script:Install-SoftwareMenuApp "TeamViewer"
})
$formControls.btnVLC.Add_Click({
    script:Install-SoftwareMenuApp "VLC"
})
$formControls.btn7zip.Add_Click({
    script:Install-SoftwareMenuApp "7Zip"
})
$formControls.btnMacrium.Add_Click({
    script:Install-SoftwareMenuApp "Macrium"
})
$formControls.btnGeForce.Add_Click({
    script:Install-SoftwareMenuApp "GeForce Experience"
})
$formControls.btnLenovoVantage.Add_Click({
    script:Install-SoftwareMenuApp "Lenovo Vantage"
})
$formControls.btnLenovoSystemUpdate.Add_Click({
    script:Install-SoftwareMenuApp "Lenovo System Update"
})
$formControls.btnHPSA.Add_Click({
    script:Install-SoftwareMenuApp "HP Support Assistant"
})
$formControls.btnMSICenter.Add_Click({
    script:Install-SoftwareMenuApp "MSI Center"
})
$formControls.btnMyAsus.Add_Click({
    script:Install-SoftwareMenuApp "MyAsus"
})
$formControls.btnDellsa.Add_Click({
    script:Install-SoftwareMenuApp "Dell Command Update"
})
$formControls.btnIntel.Add_Click({
    script:Install-SoftwareMenuApp "Intel Drivers Support"
})
$formControls.btnSteam.Add_Click({
    script:Install-SoftwareMenuApp "Steam"
})
$formControls.btnZoom.Add_Click({
    script:Install-SoftwareMenuApp "Zoom"
})
$formControls.btnDiscord.Add_Click({
    script:Install-SoftwareMenuApp "Discord"
})
$formControls.btnFirefox.Add_Click({
    script:Install-SoftwareMenuApp "Firefox"
})
$formControls.btnLibreOffice.Add_Click({
    script:Install-SoftwareMenuApp "Libre Office"
})
$formControls.btnWindowsUpdate.Add_Click({
    start-Process "ms-settings:windowsupdate"
    $formControls.richTextBxOutput.AppendText("Vérification des mises à jour de Windows`r")
})
$formControls.btnDisque.Add_Click({
    Rename-SystemDrive -NewDiskName $formControls.TxtBkDiskName.Text
})
$formControls.btnMSStore.Add_Click({
    Update-MsStore
})
$formControls.btnBitlocker.Add_Click({
    Disable-BitLocker
})
$formControls.btnStartup.Add_Click({
    Disable-FastBoot
})
$formControls.btnClavier.Add_Click({
    Remove-EngKeyboard 'en-CA'
})
$formControls.btnExplorer.Add_Click({
    Set-ExplorerDisplay
})
$formControls.btnIcone.Add_Click({
    Enable-DesktopIcon 
})
$formControls.btnConfi.Add_Click({
    Set-Privacy
})