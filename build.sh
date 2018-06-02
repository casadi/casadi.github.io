#!/bin/bash

# clear

echo "+ Starting build script."

# checking dependencies
echo "Checking dependencies: "
declare -a dep=("hugo" "npm")
for i in "${dep[@]}"
do
  {
    command -v $i > /dev/null 2>&1 &&
    echo "  $i - yep"
  } || {
    echo >&2 "  $i - nope, aborting."
    exit 1
  }
done

# goto theme folder and run npm/gulp
cd themes/casadi-theme/

# get/update npm packages
npm update

# run gulp to build static files and collect them for deploying
node node_modules/gulp/ scss

# run hugo server
cd ../..

rm -rf build && hugo

echo "+ Build script finished."
