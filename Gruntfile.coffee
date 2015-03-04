module.exports = (grunt) ->

  config =

    pkg: (grunt.file.readJSON('package.json'))

    coffeelint:
      options:
        configFile: 'coffeelint.json'
      app: ['src/**/*.coffee']

    coffee:
      dist:
        expand: true
        flatten: false
        cwd: 'src/coffee'
        src: ['./**/*.coffee']
        dest: 'tmp/dist'
        ext: '.js'
      test:
        expand: true,
        flatten: false,
        cwd: 'test',
        src: ['./**/*.coffee'],
        dest: 'tmp/test',
        ext: '.js'

    browserify:
      dist:
        files:
          'dist/background.js':   ['tmp/dist/background.js']
          'dist/popup.js':        ['tmp/dist/popup.js']
          'dist/eyejs-chrome.js': ['tmp/dist/eyejs-chrome.js']
      test:
        files:
          'test/test.js': ['tmp/test/**/*.js']
        options:
          browserifyOptions:
            debug: true
          preBundleCB: (b) ->
            b.plugin((require 'browserify-testability').plugin)

    # ### mocha_phantomjs
    # Runs mocha tests in PhantomJS.
    mocha_phantomjs:
      all: ['test/**/*.html']

    watch:
      files: [
        'src/**/*.coffee',
        'test/**/*.coffee',
        'src/**/*.jade',
        'src/**/*.sass'],
      tasks: ['compile']
      configFiles:
        files: ['Gruntfile.coffee']
        options:
          reload: true

    clean:
      dist: ['dist']
      tmp: ['tmp']
      test: ['test/**/*.js']

    replace:
      version:
        src: ['dist/**/*.js', 'dist/**/*.json'],
        overwrite: true,
        replacements: [{
          from: "*|VERSION|*",
          to: "<%= pkg.version %>"
        }]
      versionNumber:
        src: ['dist/**/*.js', 'dist/**/*.json'],
        overwrite: true,
        replacements: [{
          from: "*|VERSION_NUMBER|*",
          to: "<%= pkg.version.split('-')[0] %>"
        }]

    copy:
      chrome:
        files: [
          {
            expand: true
            flatten: true
            src: ['icons/**/*', 'manifest.json']
            dest: 'dist/'
            filter: 'isFile'
          }
        ]

    jade:
      index:
        files:
          'dist/popup.html': 'src/jade/popup.jade'

    sass:
      dist:
        options:
          loadPath: 'lib/'
        files:
          'dist/styles.css': 'src/sass/styles.sass'
          'dist/eyejs-chrome.css': 'src/sass/eyejs-chrome.sass'





  grunt.initConfig(config)

  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-mocha-test')
  grunt.loadNpmTasks('grunt-text-replace')
  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-mocha-phantomjs')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-sass')

  grunt.registerTask 'compile', [
    'coffeelint'
    'clean:dist'
    'coffee'
    'browserify:dist'
    'clean:tmp'
    'copy'
    'replace'
    'jade'
    'sass'
  ]

  grunt.registerTask 'test', [
    'compile'
    'mocha_phantomjs'
  ]
