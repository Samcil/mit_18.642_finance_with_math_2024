$workspacePath = "c:\Users\samoh\OneDrive - Hymans Robertson\me\Personal\Personal Study\mit_18.642_finance_with_math_2024\Prerequisites"

# Configuration for each course
$courses = @(
    @{
        Name = "18.03_Differential_Equations"
        Url = "https://ocw.mit.edu/courses/18-03sc-differential-equations-fall-2011"
        Pages = @("pages/syllabus", "pages/unit-i-first-order-differential-equations", "pages/unit-ii-second-order-constant-coefficient-linear-equations", "pages/unit-iii-fourier-series-and-laplace-transform", "pages/unit-iv-first-order-systems", "pages/final-exam")
    },
    @{
        Name = "18.05_Probability_Statistics"
        Url = "https://ocw.mit.edu/courses/18-05-introduction-to-probability-and-statistics-spring-2022"
        Pages = @("pages/syllabus", "pages/calendar", "pages/readings", "pages/class-slides", "pages/assignments", "pages/exams")
    },
    @{
        Name = "18.600_Probability_Random_Variables"
        Url = "https://ocw.mit.edu/courses/18-600-probability-and-random-variables-fall-2019"
        Pages = @("pages/syllabus", "pages/calendar", "pages/lecture-slides", "pages/assignments", "pages/exams")
    },
    @{
        Name = "18.06_Linear_Algebra"
        Url = "https://ocw.mit.edu/courses/18-06sc-linear-algebra-fall-2011"
        Pages = @("pages/syllabus", "pages/resource-index", "pages/ax-b-and-the-four-subspaces", "pages/least-squares-determinants-and-eigenvalues", "pages/positive-definite-matrices-and-applications", "pages/final-exam")
    }
)

function Get-PageLinks {
    param (
        [string]$PageUrl
    )
    try {
        $response = Invoke-WebRequest -Uri $PageUrl -UseBasicParsing
        # Find links that look like resources (pdf, zip) or links to resource pages
        $links = $response.Links | Where-Object { $_.href -like "*resources/*" }
        return $links
    }
    catch {
        Write-Warning "Failed to fetch page $PageUrl : $_"
        return @()
    }
}

function Get-FileLinkFromResourcePage {
    param (
        [string]$ResourcePageUrl,
        [string]$BaseUrl
    )
    try {
        $fullUrl = if ($ResourcePageUrl -match "^http") { $ResourcePageUrl } else { "$BaseUrl$($ResourcePageUrl)" }
        $response = Invoke-WebRequest -Uri $fullUrl -UseBasicParsing
        
        # Look for the download link which usually ends in .pdf or .zip and is not the resource page itself
        # Exclude links that are just back to the resource page or other html pages
        $link = $response.Links | Where-Object { ($_.href -match "\.pdf$" -or $_.href -match "\.zip$") -and $_.href -notmatch "pages" } | Select-Object -First 1
        
        if ($link) {
            return $link.href
        }
        return $null
    }
    catch {
        Write-Warning "Failed to fetch resource page $ResourcePageUrl : $_"
        return $null
    }
}

function Download-Resource {
    param (
        [string]$Url,
        [string]$DestinationPath
    )
    if (Test-Path $DestinationPath) {
        Write-Host "Skipping existing file: $DestinationPath"
        return
    }
    try {
        Write-Host "Downloading $Url..."
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to download $Url : $_"
    }
}

foreach ($course in $courses) {
    Write-Host "Processing $($course.Name)..."
    $courseDir = Join-Path $workspacePath $course.Name
    if (-not (Test-Path $courseDir)) {
        New-Item -ItemType Directory -Path $courseDir | Out-Null
    }

    $baseUrl = "https://ocw.mit.edu"

    foreach ($page in $course.Pages) {
        $pageUrl = "$($course.Url)/$page/"
        Write-Host "  Scanning $pageUrl..."
        
        $links = Get-PageLinks -PageUrl $pageUrl
        
        foreach ($link in $links) {
            # Check if it's a direct file link or a resource page
            $fileUrl = $null
            
            if ($link.href -match "\.pdf$" -or $link.href -match "\.zip$") {
                $fileUrl = if ($link.href -match "^http") { $link.href } else { "$baseUrl$($link.href)" }
            }
            else {
                # It's likely a resource page, fetch the actual file link
                $fileHref = Get-FileLinkFromResourcePage -ResourcePageUrl $link.href -BaseUrl $baseUrl
                if ($fileHref) {
                    $fileUrl = if ($fileHref -match "^http") { $fileHref } else { "$baseUrl$($fileHref)" }
                }
            }

            if ($fileUrl) {
                $fileName = $fileUrl.Split('/')[-1]
                # Clean filename of query parameters if any
                if ($fileName -match "\?") { $fileName = $fileName.Split('?')[0] }
                
                $dest = Join-Path $courseDir $fileName
                Download-Resource -Url $fileUrl -DestinationPath $dest
            }
        }
    }
}
