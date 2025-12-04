# Setup Git hooks for automatic version bump
# Run this script once to setup hooks

$hookPath = ".git/hooks/pre-commit"
$hookContent = @'
#!/bin/sh
# Auto-increment build number on commit

# Path to pubspec.yaml
PUBSPEC="pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
    exit 0
fi

# Extract current version
CURRENT_VERSION=$(grep -E "^version:" $PUBSPEC | sed 's/version: //')

if [ -z "$CURRENT_VERSION" ]; then
    exit 0
fi

# Parse version components
MAJOR=$(echo $CURRENT_VERSION | cut -d'.' -f1)
MINOR=$(echo $CURRENT_VERSION | cut -d'.' -f2)
PATCH_BUILD=$(echo $CURRENT_VERSION | cut -d'.' -f3)
PATCH=$(echo $PATCH_BUILD | cut -d'+' -f1)
BUILD=$(echo $PATCH_BUILD | cut -d'+' -f2)

# Increment build number
NEW_BUILD=$((BUILD + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$NEW_BUILD"

# Update pubspec.yaml
sed -i "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" $PUBSPEC

# Add updated pubspec.yaml to commit
git add $PUBSPEC

echo "Build number incremented: $CURRENT_VERSION -> $NEW_VERSION"
'@

# Create hooks directory if not exists
$hooksDir = ".git/hooks"
if (!(Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force
}

# Write hook file
Set-Content $hookPath $hookContent -NoNewline
Write-Host "Git pre-commit hook installed!" -ForegroundColor Green
Write-Host "Build number will auto-increment on each commit." -ForegroundColor Cyan



