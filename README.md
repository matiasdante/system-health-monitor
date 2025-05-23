<h1 align="center">
  <br>
  <a href="https://github.com/matiasdante"><img src="https://upload.wikimedia.org/wikipedia/commons/2/2f/PowerShell_5.0_icon.png" alt="Proyectos DevOps" width="200"></a>
  <br>
  Monitor de Estado del Sistema Windows
  <br>
</h1>
<h4 align="center">Script de PowerShell para diagnóstico completo del estado del sistema Windows con métricas de rendimiento</h4>
<p align="center">
  <a href="#Funciones">Funciones</a> •
  <a href="#Prerequisitos">Prerequisitos</a> •
  <a href="#Como-usarlo">Cómo usarlo</a> •
  <a href="#Salida">Salida</a> •
  <a href="#Créditos">Créditos</a> 
</p>

## Funciones
Con este script podrás...
- **Información del Sistema**: Obtiene detalles del SO, versión y build number
- **Análisis de Eventos Críticos**: Examina logs de Application y System filtrando errores y eventos críticos de los últimos 7 días
- **Monitoreo de Backup**: Identifica errores específicos del servicio de Windows Backup
- **Verificación de Actualizaciones**: Consulta actualizaciones pendientes con información detallada de tamaño y KBs
- **Métricas de Rendimiento**: Monitorea uso de CPU, memoria RAM en tiempo real
- **Análisis de Almacenamiento**: Evalúa el uso del disco en todos los volúmenes del sistema
- **Consolidación de Reportes**: Genera un dashboard completo del estado del sistema para troubleshooting

## Prerequisitos
Antes de ejecutar este script, asegúrate de tener:
- **Windows PowerShell 5.1 o superior** (o PowerShell Core 6+)
- **Privilegios administrativos** (requerido para acceso completo a Event Logs y Windows Update)
- **Servicio de Windows Update** habilitado y en ejecución
- **Conexion a Internet** para obtención de metadatos de actualizaciones
- **Permisos de lectura** en Event Logs del sistema

## Cómo usarlo

1. **Navega al directorio del script**:
```powershell
cd system-health-monitor
```

2. **Establece la política de ejecución** (si es necesario):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. **Ejecuta el script**:
```powershell
.\system-health-check.ps1
```

### Alternativa: Ejecución directa
También puedes ejecutar el script directamente copiando y pegando el código completo en una sesión de PowerShell elevada.

### Ejecución en una línea:
```powershell
Write-Host "Informacion del Sistema Operativo" -ForegroundColor Cyan; Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber | Format-List; Write-Host "`nEventos Criticos y de Error (Application y System)" -ForegroundColor Cyan; $logs = 'Application','System'; $startTime = (Get-Date).AddDays(-7); foreach ($log in $logs) { Write-Host "`n--- Log: $log ---" -ForegroundColor Yellow; Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $startTime; Level = 1, 2 } | Select-Object Id, TimeCreated, LevelDisplayName, ProviderName | Sort-Object Id, ProviderName, TimeCreated -Descending | Group-Object Id, ProviderName | ForEach-Object { $first = $_.Group | Select-Object -First 1; $first | Add-Member -MemberType NoteProperty -Name Count -Value $_.Count -Force; $first } | Sort-Object TimeCreated -Descending | Format-Table TimeCreated, LevelDisplayName, Id, ProviderName, Count -AutoSize }; Write-Host "`nErrores de Microsoft-Windows-Backup" -ForegroundColor Cyan; Get-WinEvent -LogName Microsoft-Windows-Backup | Where-Object { $_.LevelDisplayName -eq "Error" } | Select-Object TimeCreated, Message -First 10 | Format-Table -AutoSize; Write-Host "`nActualizaciones Pendientes" -ForegroundColor Cyan; $session = New-Object -ComObject Microsoft.Update.Session; $updates = $session.CreateUpdateSearcher().Search("IsInstalled=0").Updates; $updates | ForEach-Object { [PSCustomObject]@{ Title = $_.Title; KBs = ($_.KBArticleIDs -join ", "); Size = ("{0:N2} MB" -f ($_.MaxDownloadSize / 1MB)) } } | Format-Table -AutoSize; Write-Host "`nRendimiento del Sistema (CPU, Memoria, Disco)" -ForegroundColor Cyan; Get-CimInstance -ClassName Win32_OperatingSystem | ForEach-Object { $totalMem = $_.TotalVisibleMemorySize; $freeMem = $_.FreePhysicalMemory; $usedMem = $totalMem - $freeMem; $usedMemPercent = [math]::Round(($usedMem / $totalMem) * 100, 2); $cpuUsage = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average; [PSCustomObject]@{ 'Uso de CPU (%)' = "$cpuUsage%"; 'Memoria Usada (MB)' = "{0:N0}" -f ($usedMem / 1024); 'Uso de Memoria (%)' = "$usedMemPercent%" } } | Format-Table -AutoSize; Write-Host "`nUso del Disco" -ForegroundColor Cyan; Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, VolumeName, @{Name="Espacio Total (GB)";Expression={"{0:N1}" -f ($_.Size / 1GB)}}, @{Name="Espacio Libre (GB)";Expression={"{0:N1}" -f ($_.FreeSpace / 1GB)}}, @{Name="Uso (%)";Expression={"{0:N1}" -f ((($_.Size - $_.FreeSpace) / $_.Size) * 100)}} | Format-Table -AutoSize
```

## Salida
El script genera un reporte estructurado dividido en las siguientes secciones:

### 1. Información del Sistema Operativo
```
WindowsProductName : Windows 11 Pro
WindowsVersion     : 22H2
OsBuildNumber      : 22621
```

### 2. Eventos Críticos y de Error (Application y System)
| Propiedad | Descripción | Ejemplo |
|-----------|-------------|---------|
| **TimeCreated** | Timestamp del evento | "2024-01-15 14:30:25" |
| **LevelDisplayName** | Nivel del evento | "Error", "Critical" |
| **Id** | ID del evento | "1000" |
| **ProviderName** | Fuente del evento | "Application Error" |
| **Count** | Número de ocurrencias | "5" |

### 3. Errores de Microsoft-Windows-Backup
```
TimeCreated          Message
-----------          -------
2024-01-15 12:00:00  El backup falló debido a un error de E/S...
```

### 4. Actualizaciones Pendientes
| Propiedad | Descripción | Ejemplo |
|-----------|-------------|---------|
| **Title** | Nombre de la actualización | "Actualización Acumulativa 2024-01 para Windows 11" |
| **KBs** | IDs de Knowledge Base | "KB5034203, KB5034204" |
| **Size** | Tamaño de descarga | "512.00 MB" |

### 5. Rendimiento del Sistema
| Métrica | Descripción | Ejemplo |
|---------|-------------|---------|
| **Uso de CPU (%)** | Porcentaje de uso promedio del procesador | "15%" |
| **Memoria Usada (MB)** | RAM utilizada en megabytes | "8,192" |
| **Uso de Memoria (%)** | Porcentaje de RAM utilizada | "65.25%" |

### 6. Uso del Disco
| Propiedad | Descripción | Ejemplo |
|-----------|-------------|---------|
| **DeviceID** | Letra de unidad | "C:" |
| **VolumeName** | Nombre del volumen | "Windows" |
| **Espacio Total (GB)** | Capacidad total del disco | "500.0" |
| **Espacio Libre (GB)** | Espacio disponible | "150.5" |
| **Uso (%)** | Porcentaje de uso | "69.9" |

## Creditos
* Desarrollado para administración de sistemas Windows y monitoreo de infraestructura
* Optimizado para automatización de operaciones IT
* Basado en APIs nativas de Windows: WMI, Event Log, Windows Update Session

