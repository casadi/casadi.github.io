var gulp = require('gulp'),
    sass = require('gulp-sass'),
    autoprefixer = require('gulp-autoprefixer'),
    rename = require('gulp-rename'),
    minify = require('gulp-minifier');

var config = {
    staticDir: './static',
    scssPath: './src/scss',
}

// Compile SCSS files to CSS, minified and readable
gulp.task('scss', function () {
  gulp.src(config.scssPath + '/**/*.scss')
    .pipe(sass({
      includePaths: [
        config.scssPath,
        config.bowerDir
      ]
    }))
    .pipe(autoprefixer({
      browsers : ['last 20 versions']
    }))
    .pipe(gulp.dest(config.staticDir + '/_css'))
    .pipe(minify({
      minify: true,
      collapseWhitespace: true,
      conservativeCollapse: true,
      minifyCSS: true
    }))
    .pipe(rename({suffix: '.min'}))
    .pipe(gulp.dest(config.staticDir + '/_css'))
});

// Watch asset folder for changes
gulp.task('watch', ['scss'], function () {
    gulp.watch(config.scssPath + '/**/*', ['scss'])
});

// Set watch as default task
gulp.task('default', ['watch'])
