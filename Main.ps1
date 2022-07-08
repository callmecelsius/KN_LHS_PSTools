$pcList =  '.\TextFiles\PC_List.txt'
. .\Functions.ps1
$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText;

pingCheck

$cont = Read-Host 'Continue?[Y/N]'
if ($cont -eq 'N' -or $cont -eq 'n') {
    exit 0
}

else{
    #creates an arraylist of sessions
    $sList = Get-Content '.\TextFiles\Connected.txt' | New-PSSession
    $utilTool
    Clear-Content .\TextFiles\Connected.txt

    while ($utilTool -ne 0) {
            $utilTool = Read-Host 'Pick Utility [0]Exit [1]Printers [2]Programs [3]Batch Programs'
            $S_Ind = 0

            if ($utilTool -eq 1) {
                Start-PrintUtility
            }

            elseif($utilTool -eq 2) {
                Start-AppUtil
            }

            elseif($utilTool -eq 3) {
                Start-AppUtil2
            }

            else {
                if ($utilTool -ne 0) {
                    Write-Output 'Invalid choice'
                }
            }
        }#end remoting
}

Write-Output 'bye bye'
Remove-PSSession $sList