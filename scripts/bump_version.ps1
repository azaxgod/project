# PowerShell script to bump version in pubspec.yaml
# Usage: .\scripts\bump_version.ps1 [patch|minor|major]

param(
    [string]$BumpType = "patch"
)

$pubspecPath = "pubspec.yaml"
$content = Get-Content $pubspecPath -Raw

# Extract current version
if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $build = [int]$Matches[4]
    
    $oldVersion = "$major.$minor.$patch+$build"
    
    # Bump version based on type
    switch ($BumpType) {
        "major" {
            $major++
            $minor = 0
            $patch = 0
        }
        "minor" {
            $minor++
            $patch = 0
        }
        "patch" {
            $patch++
        }
    }
    
    # Always increment build number
    $build++
    
    $newVersion = "$major.$minor.$patch+$build"
    
    # Replace in file
    $newContent = $content -replace "version:\s*$oldVersion", "version: $newVersion"
    Set-Content $pubspecPath $newContent -NoNewline
    
    Write-Host "Version bumped: $oldVersion -> $newVersion" -ForegroundColor Green
} else {
    Write-Host "Could not find version in pubspec.yaml" -ForegroundColor Red
    exit 1
}



