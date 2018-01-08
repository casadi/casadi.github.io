var gulp = require('gulp'),
    sass = require('gulp-sass'),
    autoprefixer = require('gulp-autoprefixer'),
    // notify = require('gulp-notify'),
    rename = require('gulp-rename'),
    bower = require('gulp-bower'),
    minify = require('gulp-minifier');

var config = {
    staticDir: './static',
    scssPath: './src/scss',
    bowerDir: './src/bower_components'
}

// Run bower (from gulp) to fetch packages
gulp.task('bower', function() {
  return bower()
    .pipe(gulp.dest(config.bowerDir));
});

// Copy font-awesome fonts to static directory
gulp.task('icons', function() {
  return gulp.src(config.bowerDir + '/components-font-awesome/fonts/**.*')
    .pipe(gulp.dest(config.staticDir + '/fonts'));
});

// Compile SCSS files to CSS, minified and readable
gulp.task('scss', function () {
  gulp.src(config.scssPath + '/**/*.scss')
    .pipe(sass({
      // outputStyle : 'compressed',
      includePaths: [
          config.scssPath,
          config.bowerDir
      ]
    }))
    .pipe(autoprefixer({
      browsers : ['last 20 versions']
    }))
    .pipe(gulp.dest(config.staticDir + '/css'))
    .pipe(minify({
      minify: true,
      collapseWhitespace: true,
      conservativeCollapse: true,
      minifyCSS: true
    }))
    .pipe(rename({suffix: '.min'}))
    .pipe(gulp.dest(config.staticDir + '/css'))
});

// Watch asset folder for changes
gulp.task('watch', ['scss'], function () {
    gulp.watch(config.scssPath + '/**/*', ['scss'])
});

// Set watch as default task
gulp.task('default', ['watch'])
