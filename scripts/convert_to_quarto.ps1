$files = Get-ChildItem -Path . -Recurse -Filter *.Rmd

foreach ($file in $files) {
    Write-Host "Converting $($file.FullName)..."
    
    $content = Get-Content -Path $file.FullName -Raw
    
    # Basic YAML conversion
    # Replace 'output:' with 'format:'
    $content = $content -replace "^output:", "format:"
    
    # Replace common RMarkdown formats with Quarto formats in YAML
    # We use regex to ensure we match the keys in YAML
    $content = $content -replace "html_document:", "html:"
    $content = $content -replace "pdf_document:", "pdf:"
    $content = $content -replace "word_document:", "docx:"
    
    # Save as .qmd
    $newPath = [System.IO.Path]::ChangeExtension($file.FullName, ".qmd")
    Set-Content -Path $newPath -Value $content
    
    # Remove old file
    Remove-Item -Path $file.FullName
    
    Write-Host "Created $newPath"
}
