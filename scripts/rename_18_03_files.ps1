$root = Join-Path $PSScriptRoot "Prerequisites\18.03_Differential_Equations"

Get-ChildItem -Path $root -Recurse -File | ForEach-Object {
    $newName = $_.Name -replace '^MIT18_03SCF11_', ''
    if ($newName -ne $_.Name) {
        $newPath = Join-Path $_.Directory.FullName $newName
        Move-Item -Path $_.FullName -Destination $newPath -Force
        Write-Host "Renamed $($_.Name) to $newName"
    }
}
