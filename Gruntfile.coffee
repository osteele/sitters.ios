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
      global:
        options:
          banner: "/* DO NOT EDIT. Grunt builds this from from app/styles/*.scss. */\n"
        files:
          'resources/default.css': ['app/styles/default.scss', 'app/styles/**/*.scss']
      sitter_details:
        files:
          'resources/default.css': 'app/styles/default.scss'
        options:
          banner: "/* DO NOT EDIT. Grunt builds this from from app/styles/default.scss. */\n"

    update:
      tasks: ['jade', 'sass:global', 'sass:sitter_details']

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
