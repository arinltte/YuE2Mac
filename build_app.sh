#!/bin/bash
set -e
xcodebuild -project YuE2Mac.xcodeproj -scheme YuE2Mac build
# Remove the old bundle first: `mv` into an existing directory would nest the new one inside it.
rm -rf /Users/Lee/Documents/Code/YuE2Mac-upgraded/YuE2Mac.app
mv /Users/Lee/Library/Developer/Xcode/DerivedData/YuE2Mac-eefhecsvcpronjdgxwfveyfjhfog/Build/Products/Debug/YuE2Mac.app /Users/Lee/Documents/Code/YuE2Mac-upgraded/YuE2Mac.app