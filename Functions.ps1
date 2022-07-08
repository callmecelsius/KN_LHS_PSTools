# ------------------------------------------------------------------------------------------------------------------
# Ping Computer
# ------------------------------------------------------------------------------------------------------------------
function pingCheck { 

    $pcList2 = [System.Collections.Generic.List[string]]::new()
    # pings all computers simultaneously
    $jobList = Get-Content $pcList | ForEach-Object{
        Start-Job -ScriptBlock {Param($_) ping $_ -4} -ArgumentList $_
    }
    for ($i = 0; $i -le $jobList.Length; $i++ ){
        Write-Progress -Activity "Pinging" -Status "$i% Complete:" -PercentComplete $i
        Start-Sleep -Milliseconds 20
    }
    # mainly to avoid using hashtable
    Get-Content $pcList | ForEach-Object{
        $pcList2.Add($_)
    }
    # stalling so that the ping can complete
    for ($i = 0; $i -le $jobList.Length; $i++ ){
        Write-Progress -Activity "Receiving" -Status "$i% Complete:" -PercentComplete $i
        Start-Sleep -Milliseconds 10
    }


    Clear-Content .\TextFiles\Connected.txt
    # making a new list of connected pcs only
    for($i = 0; $i -lt $jobList.Length; $i++){
        $pingtest = Receive-Job $jobList[$i] -Wait -AutoRemoveJob
        if($pingtest -and -not($pingtest[3] -Match 'Request timed out') -and -not($pingtest[3] -Match 'Destination host unreachable.') -and -not($pingtest -like '*Ping request could not find host*')){
            Write-Host($pcList2[$i] + " is online")
            if ($i -eq 0) {
                $pcList2[$i] | Out-File -FilePath .\TextFiles\Connected.txt
            }
            else {
                $pcList2[$i] | Out-File -FilePath .\TextFiles\Connected.txt -Append
            }
         }
         elseif ($pingtest -like '*Ping request could not find host*') {
             Write-Host ("Check Spelling for " + $pcList2[$i])
         }
         else{
            Write-Host($pcList2[$i] + " is not reachable")
         }
    }

}
# ------------------------------------------------------------------------------------------------------------------
# App/Program utilities
# ------------------------------------------------------------------------------------------------------------------
function Start-AppUtil {
    $jobList = $slist | ForEach-Object{
        Invoke-Command -ScriptBlock {Get-Package -Provider Programs -IncludeWindowsInstaller | Select-Object Name,Status} -Session $_ -AsJob
    }
    
    for ($i = 1; $i -le 100; $i++ )
    {
    Write-Progress -Activity "Pull in Progress" -Status "$i% Complete:" -PercentComplete $i
    Start-Sleep -Milliseconds 25
    }

    # Writing list
    for($i = 0; $i -lt $slist.Length; $i++){
        if ($i -eq 0) {
            "Session No. $i Computer $($slist[$i].ComputerName)" | Out-File -FilePath .\TextFiles\Program_Info.txt
            Receive-Job $jobList[$i] -Wait -AutoRemoveJob| Format-Table Name,Status| Out-File -FilePath .\TextFiles\Program_Info.txt -Append
        }
        else {
            "Session No. $i Computer $($slist[$i].ComputerName)" | Out-File -FilePath .\TextFiles\Program_Info.txt -Append
            Receive-Job $jobList[$i] -Wait -AutoRemoveJob| Format-Table Name,Status | Out-File -FilePath .\TextFiles\Program_Info.txt -Append
        }
    }.\TextFiles\Program_Info.txt

    $done = $false
    while ($done -eq $false){

        $loopPrompt = Read-Host "[1]Add or [2]Remove Program? [3]View Extended Program List `n[4]Remove from Entended List [5]Switch PCs [0]Exit"

        if ($loopPrompt -eq 1) {
            $appPath = Read-Host 'Source file path'
            Copy-Item -Path $appPath -Destination 'C:\temp' -Recurse -ToSession $slist[$S_Ind]
            # improve below
            $remotePath = Read-Host '.EXE Path from C:\temp\'
            Invoke-Command -Session $sList[$S_Ind] -ScriptBlock {param($remotePath) Start-Process -FilePath "C:\temp\$remotePath" /silent} -ArgumentList $remotePath
            Write-Output 'Installing in background'
        }
        elseif ($loopPrompt -eq 2) {
            $removeApp = Read-Host 'C/P Program'
            $MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "$removeApp"}
            $MyApp.Uninstall()
        }
        elseif ($loopPrompt -eq 3) {
            Invoke-Command -ScriptBlock {Get-WmiObject -Class Win32_Product | Select-Object Name,Status} -Session $slist[$S_Ind]
        }
        elseif ($loopPrompt -eq 4) {
            $removeApp = Read-Host 'C/P Program'
            Invoke-Command -ScriptBlock {Uninstall-Package -Name "$removeApp"} -Session $slist[$S_Ind]
        }
        elseif ($loopPrompt -eq 5) {
            $S_Ind = Read-Host 'Select Session'
            $collectionWithItems[$S_Ind].ProgramList
        }
        elseif ($loopPrompt -eq 0) {
            $done = $true
        }
    }
}

function Start-AppUtil2 {
    $collectData = Read-Host 'List Programs?[Y/N]'
    if ($collectData -eq 'Y' -or $collectData -eq 'y') {
        $jobList = $slist | ForEach-Object{
            Invoke-Command -ScriptBlock {Get-Package -Provider Programs -IncludeWindowsInstaller | Select-Object Name,Status} -Session $_ -AsJob
        }
        
        for ($i = 1; $i -le 100; $i++ )
        {
        Write-Progress -Activity "Pull in Progress" -Status "$i% Complete:" -PercentComplete $i
        Start-Sleep -Milliseconds 25
        }
    
        # Writing list
        for($i = 0; $i -lt $slist.Length; $i++){
            if ($i -eq 0) {
                "Session No. $i Computer $($slist[$i].ComputerName)" | Out-File -FilePath .\TextFiles\Program_Info.txt
                Receive-Job $jobList[$i] -Wait -AutoRemoveJob| Format-Table Name,Status| Out-File -FilePath .\TextFiles\Program_Info.txt -Append
            }
            else {
                "Session No. $i Computer $($slist[$i].ComputerName)" | Out-File -FilePath .\TextFiles\Program_Info.txt -Append
                Receive-Job $jobList[$i] -Wait -AutoRemoveJob| Format-Table Name,Status | Out-File -FilePath .\TextFiles\Program_Info.txt -Append
            }
        }.\TextFiles\Program_Info.txt
    }

    $done = $false
    $appPath = Read-Host 'Source file path'
    $remotePath = Read-Host 'Path to install command C:\temp\'
    $uninstallPath = Read-Host 'Path to uninstall command C:\temp\'

    do{
        $loopPrompt = Read-Host '[1]Transfer [2]Install [3]Uninstall [0]Exit'
        if ($loopPrompt -eq 1) {
            $i = 0
            $sList | foreach-object -parallel{
                Write-Output "Transferring to computer $($_.ComputerName)"
                Copy-Item -Path $using:appPath -Destination 'C:\temp' -Recurse -ToSession $_
            }
        }
        elseif ($loopPrompt -eq 2) {
            $sList | foreach-object -parallel{
                Invoke-Command -Session $_ -ScriptBlock {param($remotePath) Start-Process -FilePath "C:\temp\$remotePath" /silent} -ArgumentList $using:remotePath
                Write-Output "Installing on computer $($_.ComputerName)"
            }
            Start-Sleep -Seconds 2
        }
        elseif ($loopPrompt -eq 3) {
            for ($i = 0; $i -lt $sList.Length; $i++) {
                Invoke-Command -Session $sList[$i] -ScriptBlock {param($uninstallPath) Start-Process -FilePath "C:\temp\$uninstallPath" /silent} -ArgumentList $uninstallPath
                Write-Output "Uninstalling on computer $($i+1)/$($sList.Length)"
                Start-Sleep -Seconds 2
            }
        }
        elseif ($loopPrompt -eq 0) {
            $done = $true
        }
    } while ($done -eq $false)

    $sList | foreach-object -parallel{
        Write-Output "Removing files from $($_.ComputerName)"
        Invoke-Command -Session $_ -ScriptBlock {Remove-Item -Path 'C:\temp' -Recurse -force}
    }

    $removeToshiba = Read-Host '[1] Remove Toshibas?'
    if ($removeToshiba -eq 1) {
        $printerName = Read-Host 'C/P Printer Name'
        $newTime = New-TimeSpan -minutes 10
        $time = (get-date) + $newTime
        Write-Output "Starting removal at $time" 
        Start-Sleep 600
        for ($i = 0; $i -lt $sList.Length; $i++) {
            Invoke-Command -ScriptBlock {param ($PrinterName) Remove-Printer -Name "$printerName"} $sList[$i] -ArgumentList $printerName
        }
    }
}
# ------------------------------------------------------------------------------------------------------------------
# Printer Utility
# ------------------------------------------------------------------------------------------------------------------
function Start-PrintUtility {
    $collectionWithItems = New-Object System.Collections.ArrayList
    for($i = 0; $i -lt $sList.Length; $i++){
        Write-Output "Writing computer $($i+1)/$($sList.Length)"
        $temp = New-Object System.Object
        $temp | Add-Member -MemberType NoteProperty -Name "Session" -Value $i
        $temp | Add-Member -MemberType NoteProperty -Name "HostName" -Value $sList[$i].ComputerName
        $temp | Add-Member -MemberType NoteProperty -Name "ID" -Value $sList[$i].Id
        $printTemp = Invoke-Command -ScriptBlock {Get-Printer | Format-Table Name,PrinterStatus,DriverName,PortName,JobCount | Out-String} -Session $sList[$i]
        $temp | Add-Member -MemberType NoteProperty -Name "Printers List" -Value $printTemp
        $printTemp = Invoke-Command -ScriptBlock {Get-PrinterPort | Select-Object Name,PrinterHostAddress | Out-String} -Session $sList[$i]
        $temp | Add-Member -MemberType NoteProperty -Name "Port List" -Value $printTemp
        $printTemp = Invoke-Command -ScriptBlock {Get-PrinterDriver | Select-Object Name | Out-String} -Session $sList[$i]
        $temp | Add-Member -MemberType NoteProperty -Name "Driver List" -Value $printTemp
        $collectionWithItems.Add($temp) | Out-Null
    }$collectionWithItems | Out-File -FilePath .\TextFiles\Printer_Info.txt 

    .\TextFiles\Printer_Info.txt 

    $done = $false
    $printerName
    $printerIP
    $printDriver
    $portName

    Write-Output "Current Session $S_Ind"
    $printerIP = Read-Host 'Printer IP to connect'
    while ($done -eq $false) {
        Write-Output "Current Session $S_Ind"
        $loopPrompt = Read-Host "[0:exit] [1]Select PC [2]Get Updated Info `n[3]Add Driver [4]Add Printer [5]Add Port  `n[6]Remove Printer [7]Remove Port [8]Remove Driver `n[9]Add Batch [10]Remove Batch"
        #Select PC
        if ($loopPrompt -eq 1) {
            $S_Ind = Read-Host 'Session Index'
            $printerIP = Read-Host 'Printer IP to connect'
        }
        #Get updated Info
        elseif ($loopPrompt -eq 2) {
            Write-Output "Current Session $S_Ind"
            Write-Output "Current Computer" $collectionWithItems[$S_Ind].Hostname
            Invoke-Command -ScriptBlock {Get-Printer | Select-Object Name,PrinterStatus,PortName | Out-String} -Session $sList[$S_Ind]
            Invoke-Command -ScriptBlock {Get-PrinterPort | Select-Object Name,PrinterHostAddress | Out-String} -Session $sList[$S_Ind]
            Invoke-Command -ScriptBlock {Get-PrinterDriver | Select-Object Name | Out-String} -Session $sList[$S_Ind]
        }
        #adds Driver
        elseif ($loopPrompt -eq 3) {
            # Must transfer file remotely, cannot install from print server
            $driverPath = Read-Host 'File path to driver FOLDER'
            Copy-Item -Path $driverPath -Destination 'C:\temp' -Recurse -ToSession $sList[$S_Ind]
            # Address remote file path
            $driverPath = Read-Host 'File path to driver .EXE (starting from driver parent folder)'
            Invoke-Command -ScriptBlock {Start-Process -FilePath "C:\temp\$driverPath"/silent} -Session $sList[$S_Ind]
            Start-Sleep -Seconds 3
        }
        #add Printer
        elseif ($loopPrompt -eq 4) {
            $printerName = Read-Host 'C/P Assign Printer Name'
            $portName = Read-Host 'C/P Chose Existing Port'
            $printDriver = Read-Host 'C/P Choose Driver'
            Invoke-Command -ScriptBlock {param ($PrinterName,$PortName,$PrintDriver) Add-Printer -Name $printerName -PortName $portName -DriverName $printDriver} -Session $sList[$S_Ind] -ArgumentList $printerName,$portName,$printDriver
        }
        #Add Printer Port
        elseif ($loopPrompt -eq 5) {
            $portName = Read-Host 'Name the Port'
            Invoke-Command -ScriptBlock {param ($PortName,$PrinterIP) Add-PrinterPort -Name "$portName" -PrinterHostAddress "$printerIP"} -Session $sList[$S_Ind] -ArgumentList $portName,$printerIP
        }
        #Remove Printer
        elseif ($loopPrompt -eq 6) {
            $printerName = Read-Host 'C/P Printer Name'
            $printerName2 = 'NULL'
            Invoke-Command -ScriptBlock {param ($PrinterName, $PrinterName2) Rename-Printer -Name "$printerName" -NewName "$printerName2"} $sList[$S_Ind] -ArgumentList $printerName,$printerName2
            Invoke-Command -ScriptBlock {param ($PrinterName2) Remove-Printer -Name "$printerName2"} $sList[$S_Ind] -ArgumentList $printerName2
        }
        #remove port
        elseif ($loopPrompt -eq 7) {
            $portName = Read-Host 'C/P Port Name'
            Invoke-Command -ScriptBlock {param ($PortName) Remove-PrinterPort -Name "$portName"} $sList[$S_Ind] -ArgumentList $portName
        }
        #remove Driver
        elseif ($loopPrompt -eq 8) {
            $printDriver = Read-Host 'C/P Driver Name'
            Invoke-Command -ScriptBlock {param ($PrintDriver) Remove-PrinterDriver -Name "$printDriver"} $sList[$S_Ind] -ArgumentList $printDriver
        }

        elseif ($loopPrompt -eq 9) {
            $portName = Read-Host 'Name the Port'
            Invoke-Command -ScriptBlock {param ($PortName,$PrinterIP) Add-PrinterPort -Name "$portName" -PrinterHostAddress "$printerIP"} -Session $sList -ArgumentList $portName,$printerIP
            $printerName = Read-Host 'C/P Assign Printer Name'
            $printDriver = Read-Host 'C/P Choose Driver'
            Invoke-Command -ScriptBlock {param ($PrinterName,$PortName,$PrintDriver) Add-Printer -Name $printerName -PortName $portName -DriverName $printDriver} -Session $sList -ArgumentList $printerName,$portName,$printDriver
        }

        elseif ($loopPrompt -eq 10) {
            $printerName = Read-Host 'C/P Printer Name'
            $printerName2 = 'NULL'
            Invoke-Command -ScriptBlock {param ($PrinterName, $PrinterName2) Rename-Printer -Name "$printerName" -NewName "$printerName2"} $sList -ArgumentList $printerName,$printerName2
            Invoke-Command -ScriptBlock {param ($PrinterName2) Remove-Printer -Name "$printerName2"} $sList -ArgumentList $printerName2
        }


        #exits loop
        elseif ($loopPrompt -eq 0) {
            $done = $true
            Write-Output 'Exited tool'
        }
        else {
            Write-Output 'Invalid choice'
        }
    }
#End Printer utility
}