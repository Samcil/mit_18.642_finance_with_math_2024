$prereqsDir = Join-Path $PSScriptRoot "..\Prerequisites"

# Function to move file to a subfolder
function Move-FileToFolder {
    param (
        [string]$FilePath,
        [string]$FolderName
    )
    $file = Get-Item $FilePath
    $destDir = Join-Path $file.Directory.FullName $FolderName
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir | Out-Null
    }
    $destPath = Join-Path $destDir $file.Name
    Move-Item -Path $FilePath -Destination $destPath -Force
    Write-Host "Moved $($file.Name) to $FolderName"
}

# 1. Organize 18.03 Differential Equations
$dir1803 = Join-Path $prereqsDir "18.03_Differential_Equations"
if (Test-Path $dir1803) {
    Write-Host "Organizing 18.03..."
    Get-ChildItem -Path $dir1803 -Directory | ForEach-Object { # Unit folders
        $unitDir = $_
        Get-ChildItem -Path $unitDir.FullName -Directory | ForEach-Object { # Session folders
            $sessionDir = $_
            Write-Host "  Processing Session: $($sessionDir.Name)"
            
            Get-ChildItem -Path $sessionDir.FullName -File | ForEach-Object {
                $name = $_.Name
                if ($name -match 'text\.pdf$' -or $name -match 'intro\.pdf$') {
                    Move-FileToFolder -FilePath $_.FullName -FolderName "Notes"
                }
                elseif ($name -match '^rec_') {
                    Move-FileToFolder -FilePath $_.FullName -FolderName "Recitations"
                }
                elseif ($name -match '^ps' -or $name -match 'quiz') {
                    Move-FileToFolder -FilePath $_.FullName -FolderName "Assignments"
                }
                elseif ($name -match '^ex' -or $name -match '^prex') {
                     Move-FileToFolder -FilePath $_.FullName -FolderName "Exams"
                }
                else {
                    # Assume multimedia or other resources if it has a weird name or doesn't fit
                    # But let's check if it's a known pattern.
                    # Hash-like names are likely multimedia transcripts/slides
                    Move-FileToFolder -FilePath $_.FullName -FolderName "Multimedia"
                }
            }
        }
    }
}

# 2. Organize 18.06 Linear Algebra
$dir1806 = Join-Path $prereqsDir "18.06_Linear_Algebra"
if (Test-Path $dir1806) {
    Write-Host "Organizing 18.06..."
    Get-ChildItem -Path $dir1806 -File | ForEach-Object {
        $name = $_.Name
        if ($name -match 'Ses(\d+\.\d+)') {
            $sessionNum = $Matches[1]
            $folderName = "Session_$sessionNum"
            Move-FileToFolder -FilePath $_.FullName -FolderName $folderName
        }
        elseif ($name -match '^ex' -or $name -match 'final') {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Exams"
        }
        else {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Resources"
        }
    }
}

# 3. Organize 18.05 Probability & Statistics
$dir1805 = Join-Path $prereqsDir "18.05_Probability_Statistics"
if (Test-Path $dir1805) {
    Write-Host "Organizing 18.05..."
    Get-ChildItem -Path $dir1805 -File | ForEach-Object {
        $name = $_.Name
        if ($name -match 'class(\d+)') {
            $classNum = $Matches[1]
            $folderName = "Class_$classNum"
            Move-FileToFolder -FilePath $_.FullName -FolderName $folderName
        }
        elseif ($name -match 'lec(\d+)') {
            $lecNum = $Matches[1]
            $folderName = "Class_$lecNum" # Group lectures with classes if numbers match, or separate?
            # Usually class prep and lectures go together.
            Move-FileToFolder -FilePath $_.FullName -FolderName $folderName
        }
        elseif ($name -match 'exam' -or $name -match 'practice-ex') {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Exams"
        }
        else {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Resources"
        }
    }
}

# 4. Organize 18.600 Probability & Random Variables
$dir18600 = Join-Path $prereqsDir "18.600_Probability_Random_Variables"
if (Test-Path $dir18600) {
    Write-Host "Organizing 18.600..."
    Get-ChildItem -Path $dir18600 -File | ForEach-Object {
        $name = $_.Name
        if ($name -match '^Pset') {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Problem_Sets"
        }
        elseif ($name -match 'mid' -or $name -match 'final' -or $name -match 'prc_final') {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Exams"
        }
        else {
            Move-FileToFolder -FilePath $_.FullName -FolderName "Resources"
        }
    }
}
