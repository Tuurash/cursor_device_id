$log_file = "$env:TEMP\cursor_device_id_update.log"

function Write-Log {
    param($Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -FilePath $log_file -Append
    Write-Host $Message
}
 
try {
    Write-Log "Device ID..."
    
    $new_machine_id = [guid]::NewGuid().ToString().ToLower()
    $new_dev_device_id = [guid]::NewGuid().ToString().ToLower()
    $new_mac_machine_id = -join ((1..32) | ForEach-Object { "{0:x}" -f (Get-Random -Max 16) })
    
    $machine_id_path = "$env:APPDATA\Cursor\machineid"
    $storage_json_path = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
    
    if (-not (Test-Path $machine_id_path) -or -not (Test-Path $storage_json_path)) {
        throw "No Custom Cursor Config found"
    }
    
    $backup_time = Get-Date -Format "yyyyMMddHHmmss"
    Copy-Item $machine_id_path "$machine_id_path.backup_$backup_time" -ErrorAction Stop
    Copy-Item $storage_json_path "$storage_json_path.backup_$backup_time" -ErrorAction Stop
    Write-Log "Configuration file backup created."
    
    $new_machine_id | Out-File -FilePath $machine_id_path -Encoding UTF8 -NoNewline
    Write-Log "Updated machineid"
    
    $content = Get-Content $storage_json_path -Raw | ConvertFrom-Json
    $content.'telemetry.devDeviceId' = $new_dev_device_id
    $content.'telemetry.macMachineId' = $new_mac_machine_id
    $content | ConvertTo-Json -Depth 100 | Out-File $storage_json_path -Encoding UTF8
    Write-Log "Updated storage.json"
    
    Write-Log "Update Complete"
    
    Write-Log "New Device ID:"
    Write-Log "Machine ID: $new_machine_id"
    Write-Log "Dev Device ID: $new_dev_device_id"
    Write-Log "Mac Machine ID: $new_mac_machine_id"
    
} catch {
    Write-Log "error: $_"
    
    $restore = Read-Host "restore backup? (Y/N)"
    if ($restore -eq 'Y') {
        try {
            Copy-Item "$machine_id_path.backup_$backup_time" $machine_id_path -ErrorAction Stop
            Copy-Item "$storage_json_path.backup_$backup_time" $storage_json_path -ErrorAction Stop
            Write-Log "restore successful"
        } catch {
            Write-Log "restoration failed: $_"
        }
    }
    exit 1
}
