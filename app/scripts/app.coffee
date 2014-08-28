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
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
        reloadOnSearch: false
      .otherwise
        redirectTo: '/'
    $httpProvider.defaults.headers.patch =
      'Content-Type': 'application/json;charset=utf-8'
    flashProvider.errorClassnames.push 'alert-danger'

  .filter('titlecase', () -> 
    return (s) -> 
      return s.toString().toLowerCase().replace( /\b([a-z])/g, (ch) -> return ch.toUpperCase()))

  .run ($rootScope, flash) ->
    $rootScope.resourceEndpoint = 'waterpoints'
    $rootScope.resourceBaseURI = '/api/waterpoints/'
    $rootScope.$on '$locationChangeSuccess', ->
      # Clear all flash messages on route change
      flash.info = ''
      flash.success = ''
      flash.warn = ''
      flash.error = ''
