$gradleFile = "C:\Users\ColinDiffer\AppData\Local\Pub\Cache\hosted\pub.dev\google_mobile_ads-1.3.0\android\build.gradle"

if (Test-Path $gradleFile) {
    $content = Get-Content $gradleFile -Raw
    
    if ($content -notlike "*namespace*") {
        $content = $content -replace "android \{", "android {`r`n    namespace `"io.flutter.plugins.googlemobileads`""
        Set-Content -Path $gradleFile -Value $content
        Write-Host "Namespace added successfully."
    } else {
        Write-Host "Namespace already exists in the file."
    }
} else {
    Write-Host "Could not find the build.gradle file."
}
