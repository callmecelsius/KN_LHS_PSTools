$LHS_Regex = '10\.(((1)\.(19[2-9]|20[0-7]))|((3)\.(19[2-9]|20[0-7])))\.(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])'
$Admin_Regex = '10\.(((1)\.(6[4-9]|7[0-9]))|((3)\.(6[4-9]|7[0-9])))\.(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])'
$Sloan_Regex = '10\.(((1)\.(16[0-9]|17[0-5]))|((3)\.(16[0-9]|17[0-5])))\.(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])'
$Workstation_OU = "OU=Workstations,OU=LISD,DC=ad,DC=lovejoyisd,DC=net"
$Staff_OU = “OU=Staff,OU=Workstations,OU=LHS,OU=HS,OU=LISD,DC=ad,DC=lovejoyisd,DC=net”
$Building_IP = ''

$createdDate = Read-Host 'Enter time dd/mm/yyyy 00:00:00AM/PM'

$newPC = Get-ADComputer -SearchBase $Workstation_OU -Filter 'Created -gt '$createdDate'' | Resolve-DnsName
$newPC | ForEach-Object {
    if ($_.IPAddress -match $Building_IP) {
        Write-Output $_
    }
}

$check = Read-Host 'Does this look correct? [y/n]'
if ($check -match 'N' -or $check -match 'n') {
    exit
}
$OU_Select = Read-Host 'Select OU: Staff[1] Classroom[2]'
$OU_Destination = ''

if ($OU_Select -eq 1) {
    $OU_Destination = $Staff_OU
}
elseif ($OU_Select -eq 2) {
    $room = Read-Host 'Room Num'
    $OU_Destination = “OU=$room,OU=Workstations,OU=LHS,OU=HS,OU=LISD,DC=ad,DC=lovejoyisd,DC=net”
}
$newPC | ForEach-Object {
    if ($_.IPAddress -match $Building_IP) {
        Write-Output $_
        [String]$pcName = $_.Name[0..6] -join ''
        Get-ADComputer -Identity $pcName | Move-ADObject -TargetPath $OU_Destination
    }
}