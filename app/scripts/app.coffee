'use strict'

app = angular
  .module('taarifaApp', [
    'ui.bootstrap'
    'gridster',
    'ngResource',
    'ngRoute',
    'ngCookies',
    'dynform',
    'angular-flash.service',
    'angular-flash.flash-alert-directive',
    'geolocation',
    'gettext'
  ])

  .config ($routeProvider, $httpProvider, flashProvider) ->
    request: (config) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
        reloadOnSearch: false
      .when '/dashboard',
        templateUrl: 'views/dashboard.html'
        controller: 'DashboardCtrl'
      .when '/schools/:id',
        templateUrl: 'views/school.html'
        controller: 'SchoolCtrl'
      .otherwise
        redirectTo: '/'

    $httpProvider.defaults.headers.patch =
      'Content-Type': 'application/json;charset=utf-8'

    $httpProvider.interceptors.push () ->
      request: (config) ->
        # Intercept requests and start spinner
        spinner.spin()
        config
      response: (response) ->
        # Intercept response
        spinner.stop()
        response
      responseError: (response) ->
        # Intercept error response
        spinner.stop()
        response
 
    flashProvider.errorClassnames.push 'alert-danger'

  .filter('titlecase', () -> 
    return (s) -> 
      return s.toString().toLowerCase().replace( /\b([a-z])/g, (ch) -> return ch.toUpperCase()))

  .run ($rootScope, flash) ->
    $rootScope.resourceEndpoint = 'schools'
    $rootScope.resourceBaseURI = '/api/schools/'
    $rootScope.$on '$locationChangeSuccess', ->
      # Clear all flash messages on route change
      flash.info = ''
      flash.success = ''
      flash.warn = ''
      flash.error = ''
