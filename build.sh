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

npm link sass
npm link gulp
npm link gulp-sass
npm link gulp-autoprefixer
npm link gulp-rename
npm link gulp-minifier

# run gulp to build static files and collect them for deploying
gulp scss

# run hugo server
cd ../..

rm -rf public && hugo -v --debug

echo "+ Build script finished."
