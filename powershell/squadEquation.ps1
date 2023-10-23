Write-Host "ax^2 + bx + c = 0"
[int]$a = Read-Host "Enter a"
[int]$b = Read-Host "Enter b"
[int]$c = Read-Host "Enter c"

$discr = ([Math]::Pow($b,2) - 4 * ($a * $c)) # нахожу дискриминант по формуле
if($discr -gt 0){ # проверяю значение дискриминанта и определяю кол-во корней
    $x1 = [Math]::Round((-$b + [Math]::Sqrt($discr)) / (2 * $a),5) # нахожу корень
    $x2 = [Math]::Round((-$b - [Math]::Sqrt($discr)) / (2 * $a),5)
    Write-Host "x1 = $x1`nx2 = $x2"
}
elseif($discr -eq 0){ # 1 корень
    $x = [Math]::Round(-$b / (2 * $a),5)
    echo "x = $x"
}
else{ echo "No solution" } # нет корней