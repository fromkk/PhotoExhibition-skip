#!/bin/sh

set -e
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

brew install skiptools/skip/skip

# Disable Skip during CI builds by preventing gradle from running
echo "SKIP_ACTION = none" >> Darwin/PhotoExhibition.xcconfig
