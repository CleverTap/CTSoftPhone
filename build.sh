#!/usr/bin/env bash
set -eo pipefail; [[ $DEBUG ]] && set -x

main() {
  rm -rf build
  rm -rf Release
  printf "\n"

  build_ios 'CTSoftPhone' 'build/CTSoftPhone' 'CTSoftPhone'

  # remove duplicate assets if any
  find "Release/" -name '_CodeSignature' -exec rm -rf {} +

  echo "Done"
}


build_ios() {
  scheme=$1
  archivePath=$2
  productName=$3
  
  echo "Starting build for $scheme framework"

  echo "Building $scheme (device) target ..."
  xcodebuild archive \
  -quiet \
  -scheme $scheme \
  -archivePath $archivePath-iphoneos.xcarchive \
  -sdk iphoneos \
  -destination generic/platform=iOS \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

  echo "Building $scheme (simulator) target ..."
  xcodebuild archive \
  -quiet \
  -scheme $scheme \
  -archivePath $archivePath-iphonesimulator.xcarchive \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  SKIP_INSTALL=NO \

  cp -r $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$productName.framework \
    build/$productName.framework
  rm -rf build/$productName.framework/$productName


  echo "Creating $scheme xcframework ..."
  xcodebuild -quiet -create-xcframework \
  -framework $archivePath-iphonesimulator.xcarchive/Products/Library/Frameworks/$productName.framework \
  -framework $archivePath-iphoneos.xcarchive/Products/Library/Frameworks/$productName.framework \
  -output build/$productName.xcframework

  rm -rf $archivePath-iphoneos.xcarchive
  rm -rf $archivePath-iphonesimulator.xcarchive
  printf "%s\n" "Successfully built $scheme xcframework."

  echo "zipping dynamic xcframework"
  mkdir Release
  cd Release
  mv ../build/$productName.xcframework .
  cp -r $productName.xcframework ../
  zip -q -r $productName.xcframework.zip \
    $productName.xcframework
  rm -rf $productName.xcframework
  cd ../
  rm -rf build

  echo "updating SPM checksum and url"
  package_file=Package.swift
  package_tmp_file=Package_tmp.swift
  checksum=`swift package compute-checksum Release/CTSoftPhone.xcframework.zip`
  awk -v value="\"$checksum\"" '!x{x=sub(/checksum:.*/, "checksum: "value)}1' $package_file > $package_tmp_file \
      && mv $package_tmp_file $package_file
  
  version=`cat version.txt`
  p_framework="CTSoftPhone.xcframework.zip"
  github_url="https://github.com/CleverTap/CTSoftPhone/releases/download"
  url="$github_url/$version/$p_framework"
  awk -v value="\"$url\"," '!x{x=sub(/url: .*/, "url: "value)}1' $package_file > $package_tmp_file \
    && mv $package_tmp_file $package_file

  printf "%s\n" "Success!"
}

main "$@"
