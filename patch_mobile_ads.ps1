# Path to the build.gradle file that needs to be modified
$gradleFile = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\google_mobile_ads-3.1.0\android\build.gradle"

# Check if the file exists
if (Test-Path $gradleFile) {
    # Extract package name from AndroidManifest.xml
    $manifestFile = "$env:USERPROFILE\AppData\Local\Pub\Cache\hosted\pub.dev\google_mobile_ads-3.1.0\android\src\main\AndroidManifest.xml"
    $manifestContent = Get-Content $manifestFile -Raw
    
    if ($manifestContent -match 'package="([^"]*)"') {
        $packageName = $matches[1]
        
        # Read the build.gradle file
        $gradleContent = Get-Content $gradleFile -Raw
        
        # Check if namespace is already defined
        if ($gradleContent -notmatch 'namespace\s') {
            # Add namespace to the android block
            $updatedContent = $gradleContent -replace '(android\s*\{)', "`$1`n    namespace '$packageName'"
            
            # Write the updated content back to the file
            Set-Content -Path $gradleFile -Value $updatedContent
            
            Write-Output "Added namespace '$packageName' to $gradleFile"
        } else {
            Write-Output "Namespace already exists in $gradleFile"
        }
    } else {
        Write-Output "Could not extract package name from AndroidManifest.xml"
    }
} else {
    Write-Output "Could not find the build.gradle file at $gradleFile"
}
