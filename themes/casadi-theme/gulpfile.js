// var gulp         = require('gulp'),
//     sass         = require('gulp-sass'),
//     autoprefixer = require('gulp-autoprefixer')
var gulp = require('gulp'),
    sass = require('gulp-sass'),
    notify = require('gulp-notify'),
    bower = require('gulp-bower');

var config = {
    scssPath: './src/scss',
    bowerDir: './src/bower_components'
}

gulp.task('bower', function() {
  return bower()
    .pipe(gulp.dest(config.bowerDir));
});

gulp.task('icons', function() {
  return gulp.src(config.bowerDir + '/fontawesome/fonts/**.*')
    .pipe(gulp.dest('./public/fonts')); 
});

// Compile SCSS files to CSS
gulp.task('scss', function () {
  gulp.src('src/scss/**/*.scss')
    .pipe(sass({
      // outputStyle : 'compressed'
    }))
    .pipe(autoprefixer({
      browsers : ['last 20 versions']
    }))
    .pipe(gulp.dest('static/css'))
});

// Watch asset folder for changes
gulp.task('watch', ['scss'], function () {
    gulp.watch('src/scss/**/*', ['scss'])
});

// Set watch as default task
gulp.task('default', ['watch'])
