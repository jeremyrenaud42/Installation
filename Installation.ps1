Import-Module "$applicationPath\installation\source\Installation.psm1"
$global:jsonSettingsFilePath = "$global:appPathSource\InstallationSettings.JSON"
$global:jsonChkboxContent = Get-Content -Raw $global:jsonSettingsFilePath | ConvertFrom-Json

function script:Update-CheckboxStatus
{
    $window.FindName("gridSettingsInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "chkbox*" } | 
    ForEach-Object {
        $checkbox = $_
        $checkboxName = $checkbox.Name
        $status = if ($checkbox.IsChecked) { 1 } else { 0 }
        $global:jsonChkboxContent.$checkboxName.status = $status
    }

    $window.FindName("gridInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.CheckBox] -and $_.Name -like "chkbox*" } | 
    ForEach-Object {
        $checkbox = $_
        $checkboxName = $checkbox.Name
        $status = if ($checkbox.IsChecked) { 1 } else { 0 }
        $global:jsonChkboxContent.$checkboxName.status = $status
    }

    $window.FindName("gridSettingsInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.ComboBox] -and $_.Name -like "CbBox*" } | 
    ForEach-Object {
        $comboBox = $_
        $comboBoxName = $comboBox.Name
        $selectedValue = $comboBox.SelectedItem.Content

        if ($selectedValue) 
        {
            $global:jsonChkboxContent.$comboBoxName.Status = $selectedValue
        } 
    }

    $window.FindName("gridSettingsInstallationConfig").Children | 
    Where-Object { $_ -is [System.Windows.Controls.TextBox] -and $_.Name -like "TxtBx*" } | 
    ForEach-Object {
        $textBox = $_
        $textBoxName = $textBox.Name
        $textValue = $textBox.Text

        if ($textValue) {
            $global:jsonChkboxContent.$textBoxName.Status = $textValue
        }
    }

    $global:jsonChkboxContent | ConvertTo-Json -Depth 10 | Set-Content $global:jsonSettingsFilePath
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
        $jsonGlobalSettinngsContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonGlobalSettinngsContent.RemoveDownloadFolder.Status = "1"
        $jsonGlobalSettinngsContent | ConvertTo-Json | Set-Content $jsonFilePath
    }
    elseif($formControls.chkboxDeleteFolder.IsChecked -eq $false)
    { 
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonGlobalSettinngsContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonGlobalSettinngsContent.RemoveDownloadFolder.Status = "0"
        $jsonGlobalSettinngsContent | ConvertTo-Json | Set-Content $jsonFilePath
    }

    if($formControls.chkboxDeleteBin.IsChecked)
    {
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonGlobalSettinngsContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonGlobalSettinngsContent.EmptyRecycleBin.Status = "1"
        $jsonGlobalSettinngsContent | ConvertTo-Json | Set-Content $jsonFilePath
    }
    elseif($formControls.chkboxDeleteBin.IsChecked -eq $false)
    { 
        $jsonFilePath = "$sourceFolderPath\Settings.JSON"
        $jsonGlobalSettinngsContent = Get-Content $jsonFilePath | ConvertFrom-Json
        $jsonGlobalSettinngsContent.EmptyRecycleBin.Status = "0"
        $jsonGlobalSettinngsContent | ConvertTo-Json | Set-Content $jsonFilePath
    }
    Remove-Item -Path "$env:SystemDrive\_Tech\Applications\source\Menu.lock" -Force 
    $lockFile = "$sourceFolderPath\Installation.lock"
    $Global:appIdentifier = "Installation.ps1"
    Test-ScriptInstance $lockFile $Global:appIdentifier
    $processCaff = get-process -name caffeine64 -ErrorAction SilentlyContinue
    if($processCaff -eq $false)
    {
        start-Process "$global:appPathSource\caffeine64.exe"
    }
    $window.Close()
    . $env:SystemDrive\_Tech\Applications\installation\source\InstallationOutput.ps1
})

$formControls.btnReturn_InstallationConfig.Add_Click({
    Open-Menu
})
$formControls.btnQuit_InstallationConfig.Add_Click({
    Remove-StoolboxApp
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
    $formControls.rtbOutput_InstallationConfig.AppendText("Vérification des mises à jour de Windows`r")
})
$formControls.btnDisque.Add_Click({
    script:Update-CheckboxStatus
    Rename-SystemDrive -NewDiskName $global:jsonChkboxContent.TxtBxDiskName.status
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