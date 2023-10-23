[array]$users = Get-LocalUser | Select -ExpandProperty Name # заношу все имена в коллекцию
foreach ($user in $users) {
    $name = Get-LocalUser | Where-Object Name -eq $user | Select -ExpandProperty Name 
    if(Get-LocalUser | Where-Object Name -eq $user | Select -ExpandProperty LastLogon){ # избегаю ошибки если нет даты
        $lastlogon = Get-LocalUser | Where-Object Name -eq $user | Select -ExpandProperty LastLogon
    }
    $lastpassset = Get-LocalUser | Where-Object Name -eq $user | Select -ExpandProperty PasswordLastSet
    
    Write-Host "Name: $name"
    if ($lastlogon -lt (Get-Date).AddMonths(-1) ){ Write-Host "LastLogon: $lastlogon" -ForegroundColor Green } #крашу в зеленый если дата меньше даты минус 1мес
    else { Write-Host "LastLogon: $lastlogon" } # не крашу
    Write-Host "LastPasswordSet: $lastpassset `n"
}
