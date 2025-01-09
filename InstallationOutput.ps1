$xamlFileMain = "$global:appPathSource\InstallationMainWindow.xaml"
$xamlContentMain = Read-XamlFileContent $xamlFileMain
$formatedXamlFileMain = Format-XamlFile $xamlContentMain
$xamlDocMain = Convert-ToXmlDocument $formatedXamlFileMain
$XamlReaderMain = New-XamlReader $xamlDocMain
$windowMain = New-WPFWindowFromXaml $XamlReaderMain
$formControlsMain = Get-WPFControlsFromXaml $xamlDocMain $windowMain $sync

$jsonAppsFilePath = "$global:appPathSource\InstallationApps.JSON"
$jsonString = Get-Content -Raw $jsonAppsFilePath
$appsInfo = ConvertFrom-Json $jsonString
$appNames = $appsInfo.psobject.Properties.Name
$appNames | ForEach-Object {
    $softwareName = $_
    $appsInfo.$softwareName.path64 = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.path64)
    $appsInfo.$softwareName.path32 = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.path32)
    $appsInfo.$softwareName.pathAppData = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.pathAppData)
    $appsInfo.$softwareName.RemoteName = $ExecutionContext.InvokeCommand.ExpandString($appsInfo.$softwareName.RemoteName)
    }

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

$windowMain.add_Loaded({
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
    })    
$windowMain.add_Closed({
        Remove-Item -Path "$env:SystemDrive\_Tech\Applications\source\installation.lock" -Force 
        exit
})

$formControlsMain.richTxtBxOutput.add_Textchanged({
    $WindowMain.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{}) #Refresh le Text
    $formControlsMain.richTxtBxOutput.ScrollToEnd() #scroll en bas
})

function Main
{
    Install-SoftwaresManager
    if ($script:jsonChkboxContent.chkboxMSStore.status -eq 1)
    { 
        Update-MsStore
    }
    if ($script:jsonChkboxContent.chkboxDisque.status -eq 1)
    { 
        Rename-SystemDrive -NewDiskName $formControlsMenuApp.TxtBkDiskName.Text
    }
    if ($script:jsonChkboxContent.chkboxExplorer.status -eq 1)
    { 
        Set-ExplorerDisplay
    }
    if ($script:jsonChkboxContent.chkboxBitlocker.status -eq 1)
    { 
        Disable-Bitlocker
    }
    if ($script:jsonChkboxContent.chkboxStartup.status -eq 1)
    { 
        Disable-FastBoot
    }
    if ($script:jsonChkboxContent.chkboxClavier.status -eq 1)
    { 
        Remove-EngKeyboard 'en-CA'
    }
    if ($script:jsonChkboxContent.chkboxConfi.status -eq 1)
    { 
        Set-Privacy
    }
    if ($script:jsonChkboxContent.chkboxIcone.status -eq 1)
    {
        Enable-DesktopIcon  
    }
    Add-Text -Text "`n"
    Get-CheckBoxStatus
    Get-ActivationStatus
    if ($script:jsonChkboxContent.chkboxWindowsUpdate.status -eq 1)
    { 
        Install-WindowsUpdate -UpdateSize $script:jsonChkboxContent.CbBoxSize.status
    }
    Complete-Installation
}
Start-WPFApp $windowMain
Main