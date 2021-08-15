$creds = Get-Credential

#Get vCenter Name
$VCServer = Read-Host "Enter the vCenter server name"

#Connect to vCenter
Connect-VIServer $VCServer -Credential $creds

#Get Snapshots over 30 days (Can't pass to for-each loop with details)
$OldSnaps = Get-VM | Get-Snapshot | Where-Object {$_.Created -lt (Get-Date).AddDays(-30)}

#Get Snapshots over 30 days with details
$OldSnapsDetails = Get-VM | Get-Snapshot | Where-Object {$_.Created -lt (Get-Date).AddDays(-30)} | Select-Object VM, Name, Created
$OldSnapsstr = Out-String -InputObject $OldSnapsDetails -Width 100

#Loop through $OldSnaps and remove them
Foreach ($snapshot in $OldSnaps)
{
   $tasks =  $snapshot | Remove-Snapshot -RunAsync -Confirm:$false
   #Wait for removal before proceeding
   Wait-Task $tasks
}

#Re-Check for Snaps over 30 days with details
$PostSnaps = Get-VM | Get-Snapshot | Where-Object {$_.Created -lt (Get-Date).AddDays(-30)} | Select-Object VM, Name, Created
$PostSnapsstr = Out-String -InputObject $PostSnaps

#If - If no remaining 30+ Snapshots output Details of removed Snaps
If ($null -eq $PostSnaps)
{
    $output = "The following VM's had snapshots older than 30 days, they have been deleted. `n $OldSnapsstr"
}

#Else - Show all VM's with snaps over 30 days, and list the ones that were unable to be deleted.
else
{
    $output = "These VM's had snapshots over 30 days `n $OldSnapsstr  `n but the following were unable to be deleted `n $PostSnapsstr "
}

$output

#Send E-mail with $output in the body
$From = "klittera@gmail.com"
$To = "klittera@gmail.com"
$Subject = "Snapshot Removal - > 30 days"
$Body = "$output"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Subject $Subject `
-Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
-Credential (Get-Credential)