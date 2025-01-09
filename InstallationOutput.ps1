$xamlFileMain = "$global:appPathSource\InstallationMainWindow.xaml"
$xamlContentMain = Read-XamlFileContent $xamlFileMain
$formatedXamlFileMain = Format-XamlFile $xamlContentMain
$xamlDocMain = Convert-ToXmlDocument $formatedXamlFileMain
$XamlReaderMain = New-XamlReader $xamlDocMain
$windowMain = New-WPFWindowFromXaml $XamlReaderMain
$formControlsMain = Get-WPFControlsFromXaml $xamlDocMain $windowMain $sync

$script:jsonSettingsFilePath = "$global:appPathSource\InstallationSettings.JSON"
$script:jsonChkboxContent = Get-Content -Raw $script:jsonSettingsFilePath | ConvertFrom-Json

foreach ($property in $script:jsonChkboxContent.PSObject.Properties) {
    $checkboxName = $property.Name
    $checkboxStatus = $property.Value.Status
    $labelName = "lbl_$checkboxName"
    $label = $windowMain.FindName($labelName)

    if ($null -ne $label) 
    {
        if ($checkboxStatus -eq "1") 
        {
            $label.Foreground = 'White'
        } 
    } 
}

$formControlsMain.btnclose.Add_Click({
    $windowMain.Close()
    Exit
})
$formControlsMain.btnmin.Add_Click({
        $windowMain.WindowState = [System.Windows.WindowState]::Minimized
})
$formControlsMain.Titlebar.Add_MouseDown({
        $windowMain.DragMove()
})
 
$windowMain.add_Closed({
        Remove-Item -Path "$env:SystemDrive\_Tech\Applications\source\installation.lock" -Force 
        exit
})

$formControlsMain.richTxtBxOutput.add_Textchanged({
    $windowMain.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{}) #Refresh le Text
    $formControlsMain.richTxtBxOutput.ScrollToEnd() #scroll en bas
})

function Main
{
    $formControlsMain.lblProgress.content = "Préparation"
    Install-SoftwaresManager
    if ($script:jsonChkboxContent.chkboxMSStore.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Mises à jour du Microsoft Store"
        Update-MsStore
    }
    if ($script:jsonChkboxContent.chkboxDisque.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Renommage du disque"
        Rename-SystemDrive -NewDiskName $script:jsonChkboxContent.DiskName.status
    }
    if ($script:jsonChkboxContent.chkboxExplorer.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Configuration des paramètres de l'explorateur de fichiers"
        Set-ExplorerDisplay
    }
    if ($script:jsonChkboxContent.chkboxBitlocker.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Désactivation du bitlocker"
        Disable-Bitlocker
    }
    if ($script:jsonChkboxContent.chkboxStartup.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Desactivation du demarrage rapide"    
        Disable-FastBoot
    }
    if ($script:jsonChkboxContent.chkboxClavier.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Suppression du clavier $selectedLanguage"   
        Remove-EngKeyboard 'en-CA'
    }
    if ($script:jsonChkboxContent.chkboxConfi.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Paramètres de confidentialité"
        Set-Privacy
    }
    if ($script:jsonChkboxContent.chkboxIcone.status -eq 1)
    {
        $formControlsMain.lblProgress.Content = "Installation des icones systèmes sur le bureau"   
        Enable-DesktopIcon  
    }
    Add-Text -Text "`n"
    $formControlsMain.lblProgress.Content = "Installation des logiciels"
    Get-CheckBoxStatus
    Get-ActivationStatus
    if ($script:jsonChkboxContent.chkboxWindowsUpdate.status -eq 1)
    { 
        $formControlsMain.lblProgress.Content = "Mises à jour de Windows"
        Install-WindowsUpdate -UpdateSize $script:jsonChkboxContent.CbBoxSize.status
    }
    Complete-Installation
}
Start-WPFApp $windowMain
Main