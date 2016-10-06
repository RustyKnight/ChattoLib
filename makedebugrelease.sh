rm -rf Carthage/
rm *.zip
carthage build --no-skip-current --configuration Debug
source makearchive.sh