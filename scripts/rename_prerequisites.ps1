$prereqsDir = Join-Path $PSScriptRoot "..\Prerequisites"

Get-ChildItem -Path $prereqsDir -Directory | ForEach-Object {
    $courseDir = $_.FullName
    Write-Host "Processing $courseDir..."
    
    Get-ChildItem -Path $courseDir -Recurse -File | ForEach-Object {
        $newName = $_.Name
        
        # Remove hash prefix (32 hex chars + underscore)
        if ($newName -match '^[a-f0-9]{32}_(.+)$') {
            $newName = $Matches[1]
        }
        
        # Remove course code prefix (e.g., MIT18_06SCF11_, MIT18_05_S14_, etc.)
        # Pattern: MIT followed by anything until the first underscore after the course number part?
        # Or just look for common prefixes.
        # 18.03: MIT18_03SCF11_
        # 18.06: MIT18_06SCF11_
        # 18.05: MIT18_05S14_
        # 18.600: MIT18_600S19_ (maybe?)
        
        if ($newName -match '^(MIT18_\d+[A-Za-z0-9]*_)(.+)$') {
            $newName = $Matches[2]
        }
        
        if ($newName -ne $_.Name) {
            $newPath = Join-Path $_.Directory.FullName $newName
            try {
                Move-Item -Path $_.FullName -Destination $newPath -Force -ErrorAction Stop
                Write-Host "  Renamed $($_.Name) -> $newName"
            }
            catch {
                Write-Warning "  Failed to rename $($_.Name): $_"
            }
        }
    }
}
