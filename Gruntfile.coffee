module.exports = (grunt) ->
  grunt.initConfig

    directories:
      build: 'resources/build'

    clean:
      target: ['<%= directories.build %>', 'resources/default.css']

    coffeelint:
      gruntfile: 'Gruntfile.coffee'
      options: max_line_length: value: 120

    connect:
      server: options: base: 'resources'

    jade:
      app:
        files:
          'resources/sitter_details.html': 'app/views/sitter_details.jade'
      options:
        pretty: true
        pretty$release: false

    sass:
      app:
        files:
          'resources/default.css': 'app/styles/default.scss'
          'resources/styles/sitter_details.css': 'app/styles/sitter_details.scss'
        options:
          banner: "// DO NOT EDIT. This file is generated from app/**/*.scss.\n"

    update:
      tasks: ['jade', 'sass']

    watch:
      options:
        livereload: true
      gruntfile:
        tasks: ['coffeelint:gruntfile']
      jade: {}
      sass: {files: 'app/**/*.scss'}

  require('load-grunt-tasks')(grunt)

  grunt.registerTask 'build', ['clean:target', 'jade', 'sass']
  grunt.registerTask 'build:release', ['contextualize:release', 'build']
  grunt.registerTask 'default', ['update', 'connect', 'autowatch']
