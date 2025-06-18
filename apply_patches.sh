#!/bin/bash

PLUGIN_PATH="$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/google_mobile_ads-3.1.0"
PATCH_PATH="$HOME/app/aa_readings_25/patches/google_mobile_ads+3.1.0/android/build.gradle.patch"

echo "Applying patches to Google Mobile Ads plugin..."
patch -N "$PLUGIN_PATH/android/build.gradle" < "$PATCH_PATH"
echo "Patches applied successfully."
