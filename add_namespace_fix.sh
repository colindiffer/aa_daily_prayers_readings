#!/bin/bash

# Path to the google_mobile_ads build.gradle file
GRADLE_FILE="$HOME/.pub-cache/hosted/pub.dev/google_mobile_ads-1.3.0/android/build.gradle"
# For Windows, use this path instead:
WIN_GRADLE_FILE="C:/Users/ColinDiffer/AppData/Local/Pub/Cache/hosted/pub.dev/google_mobile_ads-1.3.0/android/build.gradle"

# Choose the correct path based on your OS
if [ -f "$GRADLE_FILE" ]; then
  FILE_PATH="$GRADLE_FILE"
elif [ -f "$WIN_GRADLE_FILE" ]; then
  FILE_PATH="$WIN_GRADLE_FILE"
else
  echo "Could not find the build.gradle file."
  exit 1
fi

# Add namespace to the android block if it doesn't exist
if ! grep -q "namespace" "$FILE_PATH"; then
  echo "Adding namespace to $FILE_PATH"
  sed -i '/android {/a \    namespace "io.flutter.plugins.googlemobileads"' "$FILE_PATH"
  echo "Namespace added successfully."
else
  echo "Namespace already exists in the file."
fi
