xcodebuild -version
rm *.zip
rm -rf Carthage
time carthage build --no-skip-current --configuration Debug
source makearchive.sh