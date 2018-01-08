#!/bin/bash

# clear

echo "+ Starting build script."

# checking dependencies
echo "Checking dependencies: "
declare -a dep=("hugo" "npm" "bower")
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

bower install # assuming that "bower.json" and ".bowerrc" are given
# npm install gulp gulp-sass gulp-autoprefixer
npm install gulp gulp-sass gulp-notify gulp-bower --save-dev

echo "+ Build script finished."
