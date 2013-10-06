module.exports = (grunt) ->
  grunt.initConfig

    directories:
      build: 'resources/build'

    clean:
      target: '<%= directories.build %>/*'

    coffeelint:
      gruntfile: 'Gruntfile.coffee'
      options: max_line_length: value: 120

    connect:
      server: options: base: '<%= directories.build %>'

    jade:
      app:
        expand: true
        cwd: 'app'
        src: '**/*.jade'
        dest: '<%= directories.build %>'
        ext: '.html'
      options:
        pretty: true
        pretty$release: false

    sass:
      app:
        expand: true
        cwd: 'app'
        dest: '<%= directories.build %>'
        src: ['**/*.scss']
        ext: '.css'
        filter: 'isFile'

    update:
      tasks: ['jade', 'sass']

    watch:
      options:
        livereload: true
      gruntfile:
        tasks: ['coffeelint:gruntfile']
      jade: {}
      sass: {}

  require('load-grunt-tasks')(grunt)

  grunt.registerTask 'build', ['clean:target', 'jade', 'sass']
  grunt.registerTask 'build:release', ['contextualize:release', 'build']
  grunt.registerTask 'default', ['update', 'connect', 'autowatch']
