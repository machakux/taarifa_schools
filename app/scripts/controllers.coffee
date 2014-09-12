'use strict'

angular.module('taarifaApp')

  .controller 'NavCtrl', ($scope, $location) ->
    $scope.location = $location

  .controller 'LocaleCtrl', ($scope, $cookies, $rootScope, gettextCatalog) ->
    # get the current language from the cookie if available
    $cookies.locale = 'en' unless !!$cookies.locale
    gettextCatalog.currentLanguage = $cookies.locale

    # Save the catalog on the root scope so others can access it
    # e.g., in event handler
    # FIXME: feels clunky, surprised you cant get at it from the event obj
    $rootScope.langCatalog = gettextCatalog

    $scope.languages =
      current: gettextCatalog.currentLanguage
      available:
        en: "English"
        sw_TZ: "Swahili"

    $scope.$watch "languages.current", (lang) ->
      if not lang then return
      # Update the cookie
      $cookies.locale = lang
      # Using the setter function ensures the gettextLanguageChanged event gets fired
      gettextCatalog.setCurrentLanguage(lang)

  .controller 'MainCtrl', ($scope, $http, $location, MainResource, Map, flash, gettext) ->
    map = Map "poiMap", showScale:true
    $scope.where = $location.search()
    $scope.schoolTypes = ['primary', 'secondary']
    $scope.where.max_results = parseInt($scope.where.max_results) || 100000
    $http.get($scope.resourceBaseURI + 'values/region', cache: true).success (regions) ->
      $scope.regions = regions
    $http.get($scope.resourceBaseURI + 'values/district', cache: true).success (districts) ->
      $scope.districts = districts
    $scope.clearDistrict = ->
      $scope.where.district = null
      $location.search 'district', null
    $scope.updateMap = (nozoom) ->
      $location.search($scope.where)
      where = {}
      if $scope.where.region
        where.region = $scope.where.region
        # Filter Districtss based on selected Region
        $http.get($scope.resourceBaseURI + 'values/district', params: {region: where.region}, cache: true).success (districts) ->
          $scope.districts = districts
      else
        $http.get($scope.resourceBaseURI + 'values/district', cache: true).success (districts) ->
            $scope.district = districts
      if $scope.where.district
        where.district = $scope.where.district
      if $scope.where.school_type
        where.school_type = $scope.where.school_type
      query where, $scope.where.max_results, nozoom
    query = (where, max_results, nozoom) ->
      map.clearMarkers()
      MainResource.query
        max_results: max_results
        where: where
        projection:
          _id: 1
          name: 1
          school_type: 1
          region: 1
          district: 1
          national_rank: 1
          percentage_pass: 1
          location: 1
          code: 1
        strip: 1
      , (results) ->
        if results._items.length == 0
          flash.info = gettext('No items match your filter criteria!')
          return
        $scope.results = results._items
        map.addPOI(results._items)
        map.zoomToMarkers() unless nozoom
    $scope.updateMap()

  .controller 'DashboardCtrl', ($scope) ->
    $scope.dashGroups =
      national:
        active: true
      primary:
        active: false
      secondary:
        active: false
