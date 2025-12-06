$workspacePath = "c:\Users\samoh\OneDrive - Hymans Robertson\me\Personal\Personal Study\mit_18.642_finance_with_math_2024\Course_Materials"

Get-ChildItem -Path $workspacePath -Recurse -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName
    $extractPath = Join-Path $_.Directory.FullName $_.BaseName
    
    Write-Host "Extracting $zipPath to $extractPath..."
    
    # Create the directory if it doesn't exist (Expand-Archive does this, but good to be explicit or if we wanted to check something)
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    
    Write-Host "Deleting $zipPath..."
    Remove-Item -Path $zipPath -Force
}
