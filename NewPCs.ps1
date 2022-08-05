$LHS_Regex = 'Campus1_Regex'
$Admin_Regex = 'AdminBuilding_Regex'
$Sloan_Regex = 'Campus2_Regex'
$Workstation_OU = "Workstations_Path"
$Staff_OU = 'Staff_Path'
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
    $OU_Destination = “OU=$room, $Workstaion_OU”
}
$newPC | ForEach-Object {
    if ($_.IPAddress -match $Building_IP) {
        Write-Output $_
        [String]$pcName = $_.Name[0..6] -join ''
        Get-ADComputer -Identity $pcName | Move-ADObject -TargetPath $OU_Destination
    }
}
