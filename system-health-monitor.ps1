# Mostrar informacion del sistema operativo
Write-Host "Informacion del Sistema Operativo" -ForegroundColor Cyan
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber | Format-List

# Obtener eventos de Application y System (nivel 1 y 2)
Write-Host "`nEventos Criticos y de Error (Application y System)" -ForegroundColor Cyan
$logs = 'Application', 'System'
$startTime = (Get-Date).AddDays(-7)

foreach ($log in $logs) {
    Write-Host "`n--- Log: $log ---" -ForegroundColor Yellow
    Get-WinEvent -FilterHashtable @{
        LogName = $log
        StartTime = $startTime
        Level = 1, 2
    } |
    Select-Object Id, TimeCreated, LevelDisplayName, ProviderName |
    Sort-Object Id, ProviderName, TimeCreated -Descending |
    Group-Object Id, ProviderName |
    ForEach-Object {
        $first = $_.Group | Select-Object -First 1
        $first | Add-Member -MemberType NoteProperty -Name Count -Value $_.Count -Force
        $first
    } |
    Sort-Object TimeCreated -Descending |
    Format-Table TimeCreated, LevelDisplayName, Id, ProviderName, Count -AutoSize
}

# Eventos de Backup con error
Write-Host "`nErrores de Microsoft-Windows-Backup" -ForegroundColor Cyan
Get-WinEvent -LogName Microsoft-Windows-Backup |
    Where-Object { $_.LevelDisplayName -eq "Error" } |
    Select-Object TimeCreated, Message -First 10 |
    Format-Table -AutoSize

# Actualizaciones pendientes
Write-Host "`nActualizaciones Pendientes" -ForegroundColor Cyan
$session = New-Object -ComObject Microsoft.Update.Session
$updates = $session.CreateUpdateSearcher().Search("IsInstalled=0").Updates
$updates | ForEach-Object {
    [PSCustomObject]@{
        Title = $_.Title
        KBs   = ($_.KBArticleIDs -join ", ")
        Size  = "{0:N2} MB" -f ($_.MaxDownloadSize / 1MB)
    }
} | Format-Table -AutoSize

# Rendimiento del Sistema (CPU, Memoria, Disco)
Write-Host "`nRendimiento del Sistema (CPU, Memoria, Disco)" -ForegroundColor Cyan

Get-CimInstance -ClassName Win32_OperatingSystem | ForEach-Object {
    $totalMem = $_.TotalVisibleMemorySize
    $freeMem = $_.FreePhysicalMemory
    $usedMem = $totalMem - $freeMem
    $usedMemPercent = [math]::Round(($usedMem / $totalMem) * 100, 2)

    $cpuUsage = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

    [PSCustomObject]@{
        'Uso de CPU (%)'      = "$cpuUsage%"
        'Memoria Usada (MB)'  = "{0:N0}" -f ($usedMem / 1024)
        'Uso de Memoria (%)'  = "$usedMemPercent%"
    }
} | Format-Table -AutoSize

# Uso del Disco
Write-Host "`nUso del Disco" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, VolumeName,
    @{Name="Espacio Total (GB)";Expression={"{0:N1}" -f ($_.Size / 1GB)}},
    @{Name="Espacio Libre (GB)";Expression={"{0:N1}" -f ($_.FreeSpace / 1GB)}},
    @{Name="Uso (%)";Expression={"{0:N1}" -f ((($_.Size - $_.FreeSpace) / $_.Size) * 100)}} |
    Format-Table -AutoSize
