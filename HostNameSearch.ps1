$PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText;

$LHS_ParentOU = 'OU=LHS,OU=HS,OU=LISD,DC=ad,DC=lovejoyisd,DC=net'
$OU_Base = ',OU=Workstations,OU=LHS,OU=HS,OU=LISD,DC=ad,DC=lovejoyisd,DC=net'

$utilTool
while ($utilTool -ne 0) {
    $utilTool = Read-Host 'Search by: [1]Name [2]Location [3]OU [4]Teacher Room'
    $S_Ind = 0

    if ($utilTool -eq 1) {
        $name = Read-Host 'Name'
        Get-ADComputer -SearchBase $LHS_ParentOU -Filter "Name -like '*$name*'" | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
        .\TextFiles\DNS_Names.txt
    }

    elseif($utilTool -eq 2) {
        $roomNum = Read-Host 'Room #'
        Get-ADComputer -SearchBase $LHS_ParentOU -Filter "Location -like '*$roomNum*'" | Select-Object DNSHostName | Out-File -Filepath .\TextFiles\DNS_Names.txt
        Get-ADComputer -SearchBase $LHS_ParentOU -Filter "Name -like '*$roomNum*'" | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt -Append
        .\TextFiles\DNS_Names.txt
    }

    elseif($utilTool -eq 3) {
        $ouSelection = Read-Host '[1]B228 [2]Lib Desk [3]B232 [4]B122 [5]B119 Cart [6]B115'

        if ($ouSelection -eq 1) {
            $temp = "OU=B228" + $OU_Base
            Get-ADComputer -SearchBase  $temp -Filter * | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
            .\TextFiles\DNS_Names.txt
        }

        elseif ($ouSelection -eq 2) {
            $temp = "OU=Lib" + $OU_Base
            Get-ADComputer -SearchBase $temp  -Filter "Description -like 'Desktop'" | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
            .\TextFiles\DNS_Names.txt
        }
        elseif ($ouSelection -eq 3) {
            $temp = "OU=B232" + $OU_Base
            Get-ADComputer -SearchBase  $temp -Filter * | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
            .\TextFiles\DNS_Names.txt
        }
        elseif ($ouSelection -eq 4) {
            $temp = "OU=B122" + $OU_Base
            Get-ADComputer -SearchBase  $temp -Filter * | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
            .\TextFiles\DNS_Names.txt
        }
        elseif ($ouSelection -eq 5) {
            $temp = "OU=B119" + $OU_Base
            Get-ADComputer -SearchBase  $temp -Filter "Name -like '*3310*'" | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
            .\TextFiles\DNS_Names.txt           
        }
        elseif ($ouSelection -eq 6) {
            $temp = "OU=B115" + $OU_Base
            Get-ADComputer -SearchBase  $temp -Filter "Name -like '*3310*'" | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt
            .\TextFiles\DNS_Names.txt
        }

    }
    
    elseif ($utilTool -eq 4) {
        $roomNum = Read-Host 'Room #'
        $temp = "OU=Staff" + $OU_Base
        Get-ADComputer -SearchBase $temp -Filter "Location -like '*$roomNum*'" | Select-Object DNSHostName |Out-File -Filepath .\TextFiles\DNS_Names.txt
        $temp = "OU=Lib" + $OU_Base
        Get-ADComputer -SearchBase $temp -Filter "Name -like '*$roomNum*'" | Select-Object DNSHostNAme | Out-File -Filepath .\TextFiles\DNS_Names.txt -Append
        .\TextFiles\DNS_Names.txt
    }

    else {
        if ($utilTool -ne 0) {
            Write-Output 'Invalid choice'
        }
    }
}