#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Firebase Cleanup Script${NC}"
echo "This script will clean up cached Firebase data to ensure your app uses the correct Firebase project."
echo

# Check if we're in the Flutter project directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: This script must be run from the root of your Flutter project.${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Cleaning Flutter build cache${NC}"
flutter clean
echo -e "${GREEN}✓ Flutter build cache cleaned${NC}"

echo -e "${YELLOW}Step 2: Cleaning Gradle cache (Android)${NC}"
if [ -d "android" ]; then
    cd android
    ./gradlew clean
    cd ..
    echo -e "${GREEN}✓ Android Gradle cache cleaned${NC}"
else
    echo -e "${RED}Android directory not found, skipping Gradle clean${NC}"
fi

echo -e "${YELLOW}Step 3: Removing Pods cache (iOS)${NC}"
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
    rm -f ios/Podfile.lock
    echo -e "${GREEN}✓ iOS Pods cache removed${NC}"
else
    echo -e "${RED}iOS Pods directory not found, skipping${NC}"
fi

echo -e "${YELLOW}Step 4: Getting dependencies${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies updated${NC}"

echo
echo -e "${GREEN}Cleanup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Rebuild your app: flutter run"
echo "2. Make sure the Firebase project ID in the logs is 'chords-app-ecd47'"
echo "3. If you still see 'react-native-firebase-testing', check your firebase_options.dart file"
