$baseUrl = "https://ocw.mit.edu"
$courseUrl = "https://ocw.mit.edu/courses/18-642-topics-in-mathematics-with-applications-in-finance-fall-2024"
$workspacePath = "c:\Users\samoh\OneDrive - Hymans Robertson\me\Personal\Personal Study\mit_18.642_finance_with_math_2024\Course_Materials"

# Ensure directories exist
$directories = @("Syllabus", "Calendar", "Assignments", "Lectures")
foreach ($dir in $directories) {
    $path = Join-Path $workspacePath $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

function Download-Resource {
    param (
        [string]$Url,
        [string]$DestinationPath
    )
    try {
        Write-Host "Downloading $Url to $DestinationPath"
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to download $Url : $_"
    }
}

function Get-PageLinks {
    param (
        [string]$PageUrl
    )
    try {
        $response = Invoke-WebRequest -Uri $PageUrl -UseBasicParsing
        $links = $response.Links | Where-Object { $_.href -like "*resources/*" -and ($_.href -like "*_pdf*" -or $_.href -like "*_zip*") }
        return $links
    }
    catch {
        Write-Error "Failed to fetch page $PageUrl : $_"
        return @()
    }
}

function Get-FileLinkFromResourcePage {
    param (
        [string]$ResourcePageUrl
    )
    try {
        $response = Invoke-WebRequest -Uri $ResourcePageUrl -UseBasicParsing
        # Look for the download link which usually ends in .pdf or .zip and is not the resource page itself
        $link = $response.Links | Where-Object { ($_.href -match "\.pdf$" -or $_.href -match "\.zip$") -and $_.href -notmatch "resources" } | Select-Object -First 1
        return $link.href
    }
    catch {
        Write-Error "Failed to fetch resource page $ResourcePageUrl : $_"
        return $null
    }
}

# 1. Assignments
$assignmentsPage = "$courseUrl/pages/problem-sets/"
$assignmentLinks = Get-PageLinks -PageUrl $assignmentsPage
foreach ($link in $assignmentLinks) {
    $resourcePageUrl = if ($link.href -match "^http") { $link.href } else { "$baseUrl$($link.href)" }
    $fileHref = Get-FileLinkFromResourcePage -ResourcePageUrl $resourcePageUrl
    
    if ($fileHref) {
        $fileUrl = if ($fileHref -match "^http") { $fileHref } else { "$baseUrl$($fileHref)" }
        $fileName = $fileUrl.Split('/')[-1]
        $dest = Join-Path $workspacePath "Assignments\$fileName"
        Download-Resource -Url $fileUrl -DestinationPath $dest
    }
}

# 2. Lectures (Weeks 1-15)
for ($i = 1; $i -le 15; $i++) {
    $weekPage = "$courseUrl/pages/week-$i/"
    $weekDir = Join-Path $workspacePath "Lectures\Week_$i"
    if (-not (Test-Path $weekDir)) {
        New-Item -ItemType Directory -Path $weekDir | Out-Null
    }

    $links = Get-PageLinks -PageUrl $weekPage
    foreach ($link in $links) {
        $resourcePageUrl = if ($link.href -match "^http") { $link.href } else { "$baseUrl$($link.href)" }
        $fileHref = Get-FileLinkFromResourcePage -ResourcePageUrl $resourcePageUrl
        
        if ($fileHref) {
            $fileUrl = if ($fileHref -match "^http") { $fileHref } else { "$baseUrl$($fileHref)" }
            $fileName = $fileUrl.Split('/')[-1]
            $dest = Join-Path $weekDir $fileName
            Download-Resource -Url $fileUrl -DestinationPath $dest
        }
    }
}
