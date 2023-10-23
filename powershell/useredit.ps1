$mode = Read-Host "[1] - Add User [2] - Del User [3] - Forgot password"

switch ( $mode ){ 
    1 { # добавление юзера
        $name = Read-Host "Enter Name"
        $pass = Read-Host "Enter Password" -AsSecureString
        $fname = Read-Host "Enter Fullname"
        New-LocalUser -Name $name -Password $pass -FullName $fname
    }
    2 { # удаление
        $name = Read-Host "Enter Name"
        Remove-LocalUser -Name $name
    }
    3 { # забыл пароль
        $name = Read-Host "Enter Name"
        $pass = Read-Host "Enter new Password" -AsSecureString
        Set-LocalUser -Name $name -Password $pass
    }
    default {echo "ERROR"}
}
