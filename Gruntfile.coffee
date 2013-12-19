module.exports = (grunt) ->
  grunt.initConfig

    directories:
      build: 'resources/build'

    clean:
      target: ['<%= directories.build %>', 'resources/sitter_details.css', 'resources/sitter_details.html']

    coffeelint:
      gruntfile: 'Gruntfile.coffee'
      options: max_line_length: value: 120

    jade:
      app:
        files:
          'resources/sitter_details.html': 'app/views/sitter_details.jade'
      options:
        pretty: true
        pretty$release: false

    sass:
      sitter_details:
        files:
          'resources/sitter_details.css': 'app/styles/sitter_details.scss'
        options:
          banner: "/* DO NOT EDIT. Grunt builds this from from app/styles/sitter_details.scss. */\n"

    update:
      tasks: ['jade', 'sass']

    watch:
      gruntfile:
        tasks: ['coffeelint:gruntfile']
      jade: {files: 'app/**/*.jade'}
      sass: {files: 'app/**/*.scss'}

  require('load-grunt-tasks')(grunt)

  grunt.registerTask 'build', ['clean:target', 'jade', 'sass']
  grunt.registerTask 'build:release', ['contextualize:release', 'build']
  grunt.registerTask 'default', ['update', 'connect', 'autowatch']
