$baseUrl = "https://ocw.mit.edu"
$courseUrl = "https://ocw.mit.edu/courses/18-03sc-differential-equations-fall-2011"
$outputDir = Join-Path $PSScriptRoot "Prerequisites\18.03_Differential_Equations"

# Ensure output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Units to process
$units = @(
    @{ Name = "Unit_I"; Url = "$courseUrl/pages/unit-i-first-order-differential-equations" },
    @{ Name = "Unit_II"; Url = "$courseUrl/pages/unit-ii-second-order-constant-coefficient-linear-equations" },
    @{ Name = "Unit_III"; Url = "$courseUrl/pages/unit-iii-fourier-series-and-laplace-transform" },
    @{ Name = "Unit_IV"; Url = "$courseUrl/pages/unit-iv-first-order-systems" }
)

function Get-Links {
    param (
        [string]$Url,
        [string]$Pattern
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
        $content = $response.Content
        
        # Find all matches
        $matches = [regex]::Matches($content, $Pattern)
        return $matches
    }
    catch {
        Write-Error "Failed to fetch $Url : $_"
        return @()
    }
}

function Clean-Filename {
    param (
        [string]$Filename
    )
    # Remove hash prefix (e.g., 32c874bb..._filename.pdf -> filename.pdf)
    if ($Filename -match '^[a-f0-9]{32}_(.+)$') {
        return $Matches[1]
    }
    return $Filename
}

foreach ($unit in $units) {
    Write-Host "Processing $($unit.Name)..."
    $unitDir = Join-Path $outputDir $unit.Name
    if (-not (Test-Path $unitDir)) {
        New-Item -ItemType Directory -Path $unitDir | Out-Null
    }

    # Fetch Unit page to find Sessions
    # Pattern to find links like: <a href="/courses/18-03sc.../pages/unit-i.../session-name/">Session Name</a>
    # The links in the "Additional Links" section or the "Next" buttons might be useful, but iterating through the "Additional Links" sidebar is safer if we can target it.
    # However, the sidebar links are often relative or absolute.
    # Let's try to find links that look like session pages.
    
    # A better approach for this specific site structure:
    # The Unit page lists sessions in the "Additional Links" or just in the content?
    # Actually, the "Additional Links" sidebar seems to contain all sessions for the Unit?
    # Let's look at the fetched content again.
    # The "Additional Links" section has:
    # - [Conventions](.../conventions-and-preliminary-material/)
    # - [Basic DE's](.../basic-de-and-separable-equations/)
    # ...
    
    # So we can fetch the Unit page, look for the "Additional Links" section, and grab those links.
    
    $unitPageResponse = Invoke-WebRequest -Uri $unit.Url -UseBasicParsing
    $unitPageContent = $unitPageResponse.Content
    
    # Extract links from the "Additional Links" section.
    # This is a bit tricky with regex.
    # Let's look for hrefs that start with the unit path.
    
    $unitPath = $unit.Url.Replace($baseUrl, "")
    # Remove trailing slash if present
    if ($unitPath.EndsWith("/")) { $unitPath = $unitPath.Substring(0, $unitPath.Length - 1) }
    
    # Regex to find links that are sub-pages of the unit
    $sessionLinkPattern = "href=`"($unitPath/[^`"]+/)`""
    $sessionMatches = [regex]::Matches($unitPageContent, $sessionLinkPattern)
    
    $processedSessions = @()

    foreach ($match in $sessionMatches) {
        $sessionRelUrl = $match.Groups[1].Value
        $sessionUrl = "$baseUrl$sessionRelUrl"
        
        # Extract session name from URL
        $sessionName = $sessionRelUrl.Split('/')[-2]
        
        if ($processedSessions -contains $sessionName) { continue }
        $processedSessions += $sessionName
        
        Write-Host "  Processing Session: $sessionName"
        $sessionDir = Join-Path $unitDir $sessionName
        if (-not (Test-Path $sessionDir)) {
            New-Item -ItemType Directory -Path $sessionDir | Out-Null
        }
        
        # Fetch Session page
        try {
            $sessionResponse = Invoke-WebRequest -Uri $sessionUrl -UseBasicParsing
            $sessionContent = $sessionResponse.Content
            
            # Find PDF links
            # Pattern: href=".../resources/filename" ... (PDF)
            # Or just any link to /resources/ that ends in nothing (since they are download links) or .pdf
            # The example showed: href=".../resources/mit18_03scf11_s1_0intro/"
            
            $resourcePattern = "href=`"(/courses/18-03sc-differential-equations-fall-2011/resources/[^`"]+)`""
            $resourceMatches = [regex]::Matches($sessionContent, $resourcePattern)
            
            foreach ($resMatch in $resourceMatches) {
                $resRelUrl = $resMatch.Groups[1].Value
                $resUrl = "$baseUrl$resRelUrl"
                
                # We need to resolve the actual file URL because these might be pages wrapping the file.
                # But OCW usually links directly to the resource page which then links to the file, OR links to the file directly.
                # In the example: .../resources/mit18_03scf11_s1_0intro/
                # This looks like a resource page.
                # Let's check if it ends in .pdf or if it's a directory.
                
                if ($resRelUrl -match "\.pdf$") {
                    # Direct PDF link
                    $filename = $resRelUrl.Split('/')[-1]
                    $cleanFilename = Clean-Filename $filename
                    $filePath = Join-Path $sessionDir $cleanFilename
                    
                    if (-not (Test-Path $filePath)) {
                        Write-Host "    Downloading $cleanFilename..."
                        Invoke-WebRequest -Uri $resUrl -OutFile $filePath
                    }
                }
                else {
                    # Likely a resource page. Need to fetch it to get the actual file.
                    # However, sometimes these are just download links that don't end in PDF.
                    # Let's try to fetch the resource page and look for a download link.
                    
                    try {
                        $resPageResponse = Invoke-WebRequest -Uri $resUrl -UseBasicParsing
                        $resPageContent = $resPageResponse.Content
                        
                        # Look for a link that ends in .pdf inside this page
                        $pdfLinkPattern = "href=`"([^`"]+\.pdf)`""
                        $pdfMatch = [regex]::Match($resPageContent, $pdfLinkPattern)
                        
                        if ($pdfMatch.Success) {
                            $pdfRelUrl = $pdfMatch.Groups[1].Value
                            if ($pdfRelUrl.StartsWith("/")) {
                                $pdfUrl = "$baseUrl$pdfRelUrl"
                            } else {
                                $pdfUrl = $pdfRelUrl # Handle absolute URLs if any
                            }
                            
                            $filename = $pdfUrl.Split('/')[-1]
                            $cleanFilename = Clean-Filename $filename
                            $filePath = Join-Path $sessionDir $cleanFilename
                            
                            if (-not (Test-Path $filePath)) {
                                Write-Host "    Downloading $cleanFilename (from resource page)..."
                                Invoke-WebRequest -Uri $pdfUrl -OutFile $filePath
                            }
                        }
                    }
                    catch {
                        Write-Warning "    Failed to process resource page $resUrl"
                    }
                }
            }
        }
        catch {
            Write-Warning "  Failed to fetch session $sessionUrl"
        }
    }
}

Write-Host "Download complete."
