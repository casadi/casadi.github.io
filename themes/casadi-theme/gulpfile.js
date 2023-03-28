const gulp = require('gulp');
const sass = require('gulp-sass')(require('sass'));
const autoprefixer = require('gulp-autoprefixer');
const rename = require('gulp-rename');
const minify = require('gulp-minifier');

const config = {
  staticDir: './static',
  scssPath: './src/scss',
};

// Compile SCSS files to CSS, minified and readable
function scss() {
  return gulp.src(config.scssPath + '/**/*.scss')
    .pipe(sass({
      includePaths: [
        config.scssPath
      ]
    }))
    .pipe(autoprefixer({
      overrideBrowserslist: ['last 20 versions']
    }))
    .pipe(gulp.dest(config.staticDir + '/_css'))
    .pipe(minify({
      minify: true,
      collapseWhitespace: true,
      conservativeCollapse: true,
      minifyCSS: true
    }))
    .pipe(rename({suffix: '.min'}))
    .pipe(gulp.dest(config.staticDir + '/_css'));
}

// Watch asset folder for changes
function watch() {
  gulp.watch(config.scssPath + '/**/*', scss);
}

// Set watch as default task
gulp.task('default', gulp.series(scss, watch));

// Export the tasks
exports.scss = scss;
exports.watch = watch;
