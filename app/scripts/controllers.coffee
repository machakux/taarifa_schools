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

  .controller 'MainCtrl', ($scope, $http, $location, $window, MainResource, Map, flash, gettext) ->

    map = Map "poiMap", showScale:true
    $scope.defaultRegion = 'Dar es Salaam'
    $scope.where = $location.search()
    $scope.schoolTypes = ['primary', 'secondary']
    $scope.where.max_results = parseInt($scope.where.max_results) || 100000
    $scope.where.region = $scope.defaultRegion
    
    getDistricts = () ->
      $http.get($scope.resourceBaseURI + 'values/district', cache: true).success (districts) ->
        $scope.districts = districts
      
    getRegions = () ->
      $http.get($scope.resourceBaseURI + 'values/region', cache: true).success (regions) ->
        $scope.regions = regions

    getOwnerships = () ->
      $http.get($scope.resourceBaseURI + 'values/ownership', cache: true).success (ownerships) ->
        $scope.ownerships = ownerships

    getRegions()
    getDistricts()
    getOwnerships()

    $scope.clearDistrict = ->
      $scope.where.district = null
      $location.search 'district', null

    $scope.resetParameters = ->
      $scope.where = 
        max_results: 100000
        region: $scope.defaultRegion
      getRegions()
      getDistricts()

    $scope.updateMap = (nozoom) ->
      $location.search($scope.where)
      $scope.order = """[["national_rank", 1]]"""
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
      if $scope.where.ownership
        where.ownership = $scope.where.ownership
      if $scope.where.search
        where.$text =
          $search: '\"' + $scope.where.search + '\"'
      query where, $scope.where.max_results, $scope.order, nozoom

    $scope.reset = ->
      $scope.resetParameters()
      $scope.updateMap()

    $scope.download = ->
      downloadUrl = $scope.resourceBaseURI + 'download' + $location.url() + '&sort=' + $scope.order
      $window.open(downloadUrl)

    query = (where, max_results, order, nozoom) ->
      map.clearMarkers()
      $scope.results = []
      MainResource.query
        max_results: max_results
        sort: order
        where: where
        projection:
          _id: 1
          name: 1
          school_type: 1
          region: 1
          district: 1
          ward: 1
          national_rank: 1
          candidates: 1
          number_pass: 1
          percentage_pass: 1
          percentage_pass_change: 1
          number_teaching_staff: 1
          number_enrolled: 1
          location: 1
          code: 1
          ownership: 1
        strip: 1
      , (results) ->
        if results._items.length == 0
          flash.info = gettext('No items match your filter criteria!')
          spinner.stop()
          return
        $scope.results = results._items
        $scope.count = results._meta.total
        map.addPOI(results._items)
        map.zoomToMarkers() unless nozoom

    $scope.openPopup = (markerId) ->
      map.openPopup(markerId)

    $scope.closePopup = (markerId) ->
      map.closePopup(markerId)

    $scope.updateMap()

  .controller 'DashboardCtrl', ($scope) ->
    $scope.dashGroups =
      national:
        active: true
      primary:
        active: false
      secondary:
        active: false

  .controller 'SchoolCtrl', ($scope, $routeParams, Map, MainResource) ->
    $scope.mainResource = MainResource
    map = Map("mapView", {})
    MainResource.get id: $routeParams.id, (resource) ->
      $scope.resource = resource
      map.clearMarkers()
      map.addPOI([resource])
      map.centerToMarkers()

