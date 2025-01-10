foreach ($property in $global:jsonChkboxContent.PSObject.Properties) {
    $checkboxName = $property.Name
    $checkboxStatus = $property.Value.Status
    $labelName = "lbl_$checkboxName"
    $label = $global:windowMain.FindName($labelName)

    if ($null -ne $label) 
    {
        if ($checkboxStatus -eq "1") 
        {
            $label.Foreground = 'White'
        } 
    } 
}

$global:formControlsMain.btnclose.Add_Click({
    $global:windowMain.Close()
    Exit
})
$global:formControlsMain.btnmin.Add_Click({
        $global:windowMain.WindowState = [System.Windows.WindowState]::Minimized
})
$global:formControlsMain.Titlebar.Add_MouseDown({
        $global:windowMain.DragMove()
})
 
$global:windowMain.add_Closed({
        Remove-Item -Path "$env:SystemDrive\_Tech\Applications\source\installation.lock" -Force 
        exit
})

$global:formControlsMain.richTxtBxOutput.add_Textchanged({
    $global:windowMain.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{}) #Refresh le Text
    $global:formControlsMain.richTxtBxOutput.ScrollToEnd() #scroll en bas
})

function Main
{
    Install-SoftwaresManager
    if ($global:jsonChkboxContent.chkboxMSStore.status -eq 1)
    { 
        Update-MsStore
    }
    if ($global:jsonChkboxContent.chkboxDisque.status -eq 1)
    { 
        Rename-SystemDrive -NewDiskName $global:jsonChkboxContent.TxtBxDiskName.status
    }
    if ($global:jsonChkboxContent.chkboxExplorer.status -eq 1)
    { 
        Set-ExplorerDisplay
    }
    if ($global:jsonChkboxContent.chkboxBitlocker.status -eq 1)
    { 
        Disable-Bitlocker
    }
    if ($global:jsonChkboxContent.chkboxStartup.status -eq 1)
    { 
        Disable-FastBoot
    }
    if ($global:jsonChkboxContent.chkboxClavier.status -eq 1)
    { 
        Remove-EngKeyboard 'en-CA'
    }
    if ($global:jsonChkboxContent.chkboxConfi.status -eq 1)
    { 
        Set-Privacy
    }
    if ($global:jsonChkboxContent.chkboxIcone.status -eq 1)
    { 
        Enable-DesktopIcon  
    }
    Add-Text -Text "`n"
    Get-CheckBoxStatus
    Get-ActivationStatus
    if ($global:jsonChkboxContent.chkboxWindowsUpdate.status -eq 1)
    { 
        Install-WindowsUpdate -UpdateSize $global:jsonChkboxContent.CbBoxSize.status
    }
    Complete-Installation
}
Start-WPFApp $global:windowMain
Main