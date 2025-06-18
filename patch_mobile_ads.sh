#!/bin/bash

# Define the path to the build.gradle file that needs to be modified
GRADLE_FILE="$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/google_mobile_ads-3.1.0/android/build.gradle"

# Check if the file exists
if [ -f "$GRADLE_FILE" ]; then
    # Extract package name from AndroidManifest.xml
    MANIFEST_FILE="$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/google_mobile_ads-3.1.0/android/src/main/AndroidManifest.xml"
    PACKAGE_NAME=$(grep -o 'package="[^"]*"' "$MANIFEST_FILE" | sed 's/package="\(.*\)"/\1/')
    
    # Add namespace to build.gradle if it doesn't already have it
    if ! grep -q "namespace" "$GRADLE_FILE"; then
        sed -i "/android {/a\\    namespace '$PACKAGE_NAME'" "$GRADLE_FILE"
        echo "Added namespace '$PACKAGE_NAME' to $GRADLE_FILE"
    else
        echo "Namespace already exists in $GRADLE_FILE"
    fi
else
    echo "Could not find the build.gradle file at $GRADLE_FILE"
fi
