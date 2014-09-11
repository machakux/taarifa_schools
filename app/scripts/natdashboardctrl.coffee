'use strict'

angular.module('taarifaApp')

  .controller 'NationalDashboardCtrl', ($scope, $http, $timeout,
                                gettextCatalog, gettext) ->

    # should http calls be cached
    # FIXME: should be application level setting
    cacheHttp = false

    # a flag to keep track if the plots should be redrawn
    # next time the tab is made visible
    plotsDirty = false

    $scope.gridsterOpts = {
        margins: [5,10],
        columns: 12,
        floating: true,
        pushing: true,
        draggable: {
            enabled: true
        },
        resizable: {
            enabled: true,
            stop: (event, uiWidget, $el) ->
                isplot = jQuery($el.children()[0]).hasClass("plot")
                if isplot then drawPlots()
        }
    }

    $scope.gridLayout = {
      tiles: [
        { sizeX: 3, sizeY: 2, row: 0, col: 0 },
        { sizeX: 3, sizeY: 2, row: 0, col: 3 },
      ]

      map:
        { sizeX: 6, sizeY: 6, row: 0, col: 6 }

      count:
        { sizeX: 6, sizeY: 4, row: 2, col: 0 }

      plots: [
        { sizeX: 12, sizeY: 6, row: 6, col: 0 },
        { sizeX: 6, sizeY: 8, row: 12, col: 0 }
        { sizeX: 6, sizeY: 8, row: 12, col: 6 }
      ]

      topPrimary:
        { sizeX: 6, sizeY: 6, row: 20, col: 0 }

      topSecondary:
        { sizeX: 6, sizeY: 6, row: 20, col: 6 }
      
    }

    $scope.plots = [
      {id:"performanceChart", title: gettext("Percentage pass")},
      {id:"numberPassChart", title: gettext("Number of passed students")},
      {id:"performanceChangeChart", title: gettext("Change in % pass")}]

    $scope.groups = ['region', 'district']
    
    $scope.schoolTypes = ['all', 'primary', 'secondary']
    
    $scope.schoolTypeChoice = "all"

    # default group by to region
    $scope.params = group: $scope.groups[0]

    getRegion = () ->
      $http.get($scope.resourceBaseURI + 'values/region', cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.regions = data.sort()

    getDistrict = () ->
      $http.get($scope.resourceBaseURI + 'values/district',
                params: {region: $scope.params?.region}
                cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.lgas = data.sort()

    getCountSchoolType = () ->
      # modalSpinner.open()
      $http.get($scope.resourceBaseURI + 'count/school_type',
                cache: cacheHttp
                params:
                  region: $scope.params?.region
                  district: $scope.params?.district
                  ward: $scope.params?.ward)
        .success (data, status, headers, config) ->
          data.forEach( (x) ->
            x.label = x.school_type
            x.value = x.count
          )
          $scope.typeCount = data.sort((a, b) ->
            return b.count - a.count
          )
          graphCountTypeData($scope.typeCount)
          plotDonutChart('#typeCountDonutChart', $scope.graphTypeCount)
          # modalSpinner.close()

    getPerformanceSchoolType = () ->
      $scope.shoolTypeChoice = "all"

      # modalSpinner.open()

      $http.get($scope.resourceBaseURI + 'performance',
        cache: cacheHttp
        params: _.omit($scope.params,'group'))
        .success (data, status, headers, config) ->
          data.forEach( (x) ->
            x.percent = x.numberPass / x.candidates * 100
            x.percentLast = x.numberPassLast / x.candidatesLast * 100
            x.passChange = x.percent - x.percentLast
          )

          # index by school_type for convenience
          schoolTypeMap = _.object(_.pluck(data, "school_type"), data)
          $scope.schoolType = schoolTypeMap

          # ensure all school types are always represented
          empty = {numberPass: 0, candidates: 0}
          school_types = [gettext("primary"), gettext("secondary")]
          school_types.forEach((x) -> schoolTypeMap[x] = schoolTypeMap[x] || empty)

          $scope.tiles = _.pairs(_.pick(schoolTypeMap, 'primary', 'secondary'))
          # modalSpinner.close()
 
    getPerformance = () ->
      url = $scope.resourceBaseURI + "performance/" + $scope.params.group
      if $scope.schoolTypeChoice and $scope.schoolTypeChoice isnt 'all'
          url += '?school_type=' + $scope.schoolTypeChoice
      $http.get(url, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.performanceData = data
          graphPerformanceData($scope.performanceData)
          plotMultiBarChart('#performanceChart', $scope.graphPerformance)
          plotMultiBarHorizontalChart('#numberPassChart', $scope.graphNumberPass)
          plotMultiBarHorizontalChart("#performanceChangeChart", $scope.graphPerformanceChange)

    getTopSchools = () ->
      params_sec = 'where={"school_type":"secondary"}&max_results=100&sort=[("national_rank",1)]'
      params_pr = 'where={"school_type":"primary"}&max_results=100&sort=[("national_rank",1)]'
      $http.get($scope.resourceBaseURI + "?" + params_sec, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.topSchoolsSecondary = data._items
      $http.get($scope.resourceBaseURI + "?" + params_pr, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.topSchoolsPrimary = data._items

    graphPerformanceData = (data) ->
      performanceCurrent = []
      performancePrevious = []
      numberPassCurrent = []
      numberPassPrevious = []
      performanceChange = []
      groupField = $scope.params.group
      
      data.forEach( (item) ->
        performanceObj = {x: item[groupField] || '', y: item.numberPass / item.candidates * 100 || 0}
        performancePrevObj = {x: item[groupField] || '', y: item.numberPassLast / item.candidatesLast * 100 || 0}
        numberPassObj = {x: item[groupField] || '', y: item.numberPass || 0}
        numberPassPrevObj = {x: item[groupField] || '', y: item.numberPassLast || 0}
        performanceChangeObj = {x: item[groupField] || '', y: performanceObj.y - performancePrevObj.y}
        performanceCurrent.push performanceObj
        performancePrevious.push performancePrevObj
        numberPassCurrent.push numberPassObj
        numberPassPrevious.push numberPassPrevObj
        performanceChange.push performanceChangeObj
      )

      $scope.graphPerformance = [
        {
          key: 'Percentage pass',
          color: "#51A351",
          values: _.sortBy(performanceCurrent, 'y' ).reverse()
        },
        {
          key: 'Percentage pass previous year',
          color: "#BD362F",
          values: _.sortBy(performancePrevious, 'y' ).reverse()
        },
      ]

      $scope.graphNumberPass = [
        {
          key: 'Number of passed students',
          color: "#51A351",
          values: _.sortBy(numberPassCurrent, 'y' ).reverse()
        },
        {
          key: 'Number of passed students previous year',
          color: "#BD362F",
          values: _.sortBy(numberPassPrevious, 'y' ).reverse()
        },
      ]

      $scope.graphPerformanceChange = [
        {
          key: 'Percentage change in pass',
          color: "#51A351",
          values: _.sortBy(performanceChange, 'y' ).reverse()
        },
      ]

    graphCountTypeData = (data) ->
      typeCount = []
      
      data.forEach( (item) ->
        typeObj = {x: item.school_type || '', y: item.count || 0}
        typeCount.push typeObj
      )

      $scope.graphTypeCount = typeCount

    $scope.onSchoolTypeSelected = (event) ->
      schoolType = event.target.attributes.value.value
      $scope.schoolTypeChoice = schoolType
      getPerformance()


    drawPlots = () ->
      if $scope.performanceData
        graphPerformanceData($scope.performanceData)
        plotMultiBarChart('#performanceChart', $scope.graphPerformance)
        plotMultiBarHorizontalChart('#numberPassChart', $scope.graphNumberPass)
        plotMultiBarHorizontalChart("#performanceChangeChart", $scope.graphPerformanceChange)
      if $scope.typeCount
        graphCountTypeData($scope.typeCount)
        plotDonutChart('#typeCountDonutChart', $scope.graphTypeCount)

    $scope.drillDown = (fieldVal, fieldType, clearFilters) ->
      groupField = fieldType || $scope.params.group
      geoField = _.contains(['region','district'], groupField)

      if !geoField then return

      gforder =
        "region": "district"
        "district": "region"

      # Using timeout of zero instead of $scope.apply() in order to avoid
      # this error: https://docs.angularjs.org/error/$rootScope/inprog?p0=$apply
      # This happens, for example, when drillDown is called from the geojson feature
      # click handler (by the leaflet directive)
      # FIXME: a workaround, better solution?
      $timeout(() ->
        if !$scope.params then $scope.params = {}

        newgf = gforder[groupField]
        $scope.params.group = newgf

        if clearFilters || newgf == "region"
          $scope.params.region = null
          $scope.params.district = null

        if newgf == "region"
          $scope.getStatus()
        else
          $scope.params[groupField] = fieldVal
          $scope.getStatus()
      ,0)

    barDblClick = (d) ->
      groupField = $scope.params.group
      $scope.drillDown(d[groupField])


    $scope.$on "gettextLanguageChanged", (e) ->
      # redraw the plots so axis labels, etc are translated

      # will only work if the tab is visible (else d3 fails)
      if $scope.dashTabs.national.active
        drawPlots()
      else
        # we have to remember to redraw the plots when the tab
        # finally does become active
        plotsDirty = true

    $scope.$watch "dashTabs.national.active", (val) ->
      if val and plotsDirty
        drawPlots()
        
    $scope.refreshView = () ->
      drawPlots()

    initView = () ->
      getPerformanceSchoolType()
      getCountSchoolType()
      getPerformance()
      getTopSchools()

    initView()
