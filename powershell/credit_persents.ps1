function First(){
    [int]$deposit = Read-Host "Enter deposit"
    [int]$persent = Read-Host "Enter persent(1-100)"
    [int]$months = Read-Host "Enter months"
    [int]$years = Read-Host "Enter years"

    echo ([Math]::Round($deposit * [Math]::Pow(1 + ($persent/100) / $months, $months*$years), 0))
}
function Second(){
    [int]$deposit = Read-Host "Enter deposit"
    [int]$persent = Read-Host "Enter persent(1-100)"
    [int]$months = Read-Host "Enter months"
    [int]$wanted = Read-Host "Enter wanted deposit"

    for($year = 1;$result -le $wanted;$year++){
        $result = ([Math]::Round($deposit * [Math]::Pow(1 + ($persent/100) / $months, $months*$year), 0))
        Write-Host "Year: $year - $result"
    }
}
function Third(){
    [int]$deposit = Read-Host "Enter credit"
    [double]$persent = Read-Host "Enter persent(1-100)"
    [int]$months = Read-Host "Enter months"
    $persent /= 100

    Write-Host "You have to pay each month" ([Math]::Round($deposit*($persent+$persent/(([Math]::Pow((1+$persent),$months)-1))),0))
}
# Все формулы находил в интернете и переводил их в код

#First
#Second
#Third
