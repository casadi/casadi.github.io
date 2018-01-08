# Locally host website

Requires: `hugo` > v0.32.2

1. [Get Hugo](https://gohugo.io/getting-started/installing/)
2. Clone this repo
3. Run `hugo server` in root directory of repo
4. Open your browser and go to `http://localhost:1313` (or as indicated by `hugo server` terminal output)

# Build website

Requires: `npm`

- Run the `develop.sh` script

or  the following steps manually
  1. Go to `themes/casadi-theme`
  2. Run: `npm install gulp gulp-sass gulp-autoprefixer gulp-rename gulp-bower gulp-minifier --save`
  3. Run: `gulp bower` (simple script to fetch dependencies with bower)
  4. Run: `gulp icons` (copy font-awesome fonts into static directory)
  5. Compile with `gulp scss` or compile and live reload with `gulp`
