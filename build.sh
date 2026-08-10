#!/usr/bin/env bash
set -e

export CI_PRIMARY_REPOSITORY_PATH="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
ci_scripts/ci_post_clone.sh

PROJECT="BTRemote"
PLATFORM="${1:-all}"
mkdir -p build

if [ "$PLATFORM" = "mac" ] || [ "$PLATFORM" = "all" ]; then
    xcodebuild \
        -project $PROJECT.xcodeproj \
        -scheme $PROJECT \
        -configuration Release \
        -destination "platform=macOS" \
        -derivedDataPath .build/DerivedData \
        CODE_SIGNING_ALLOWED=NO \
        build
    codesign --force --sign - --entitlements $PROJECT/entitlements.plist .build/DerivedData/Build/Products/Release/$PROJECT.app || true
    cp -R .build/DerivedData/Build/Products/Release/$PROJECT.app build/ || true
fi

if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "all" ]; then
    xcodebuild \
        -project $PROJECT.xcodeproj \
        -scheme $PROJECT \
        -configuration Release \
        -sdk iphoneos \
        -destination "generic/platform=iOS" \
        -derivedDataPath .build/DerivedData \
        CODE_SIGNING_ALLOWED=NO \
        build
    codesign --force --sign - --entitlements $PROJECT/entitlements.plist .build/DerivedData/Build/Products/Release-iphoneos/$PROJECT.app || true
    rm -rf .build/Payload build/$PROJECT.ipa
    mkdir -p .build/Payload
    cp -R .build/DerivedData/Build/Products/Release-iphoneos/$PROJECT.app .build/Payload/
    cd .build
    zip -qry ../build/$PROJECT.ipa Payload
    cd ..
fi
