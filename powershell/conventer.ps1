#принимаю аргументы скрипта по порядку
$unit=$args[0] #аргумент для выбора конкретного формата данных
$value=$args[1] #аргумент колличества


switch ($unit) { #форматирую переменную value в зависимости от выбранного формата данных
    "B" {}            
    "KB" {$value *= 1024}            
    "MB" {$value *= 1024 * 1024}            
    "GB" {$value *= 1024 * 1024 * 1024}            
    "TB" {$value *= 1024 * 1024 * 1024 * 1024}                     
}

$table = @{ #создаю таблицу 
     "B" = $value ;
     "KB" = $value/1KB;
     "MB" = $value/1MB;
     "GB" = $value/1GB;
     "TB" = $value/1TB
 }
 
$table.GetEnumerator() | sort -Property value #сортирую и вывожу