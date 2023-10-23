    #Принимаю аргументы: 1 - число, 2 - нижняя грань, 3 - верхняя грань
$Num=$args[0]
$L=$args[1]
$U=$args[2]

    #Проверяю входит ли число в грани отрезка
if($Num -lt $L -or $Num -gt $U) { 
    echo "Number is out of range"
    exit 0 
}

    #Перевел формулу нахождения значения в алгоритм A = (U - L) / 2 + L
$Ans=[math]::Truncate(($U/2)) #Поделил на 2 $U и убрал дробную часть ф-цией Truncate
while($Ans -ne $Num){
    if($Ans -gt $Num){$U=$Ans}
    elseif($Ans -lt $Num){$L=$Ans}

    $D1=$U-$L
    $D2=[math]::Truncate(($D1/2))
    $Ans=$D2+$L
    $i++
    echo "`#$i : Answer:$Ans"
}
echo "`nGame is over!`nAnswer:$Ans`nNumber of tries:$i"
Read-Host "`n`nPress enter to close"