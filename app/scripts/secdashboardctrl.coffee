'use strict'

angular.module('taarifaApp')

  .controller 'SecondaryDashboardCtrl', ($scope, $http, $timeout,
                                gettextCatalog, gettext) ->

    # should http calls be cached
    # FIXME: should be application level setting
    cacheHttp = false

    # a flag to keep track if the plots should be redrawn
    # next time the tab is made visible
    plotsDirty = true

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
      ],

      map:
        { sizeX: 6, sizeY: 6, row: 0, col: 6 }
      top:
        { sizeX: 6, sizeY: 4, row: 2, col: 0 }
      plots: [
        { sizeX: 12, sizeY: 5, row: 6, col: 0 },
        { sizeX: 6, sizeY: 5, row: 11, col: 0 }
        { sizeX: 6, sizeY: 5, row: 11, col: 6 }
      ]
    }

    $scope.plots = [
      {id:"performanceChartSecondary", title: gettext("Percentage pass by district (this & last year)")},
      {id:"numberPassChartSecondary", title: gettext("Number of passed studets")},
      {id:"performanceChangeChartSecondary", title: gettext("Change in % pass from previous year")}
    ]

    # a flag to keep track if the plots should be redrawn
    # next time the tab is made visible
    plotsDirty = false

    getRegions = (callback) ->
      $http.get($scope.resourceBaseURI + 'values/region', cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.regions = data.sort()
          $scope.region = $scope.regions[0]
          callback()

    getPerformanceTotal = () ->
      $http.get($scope.resourceBaseURI + 'performance?school_type=secondary&region=' + $scope.region, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.percentagePass = {}
          $scope.percentagePass['this'] = data[0].numberPass / data[0].candidates * 100
          $scope.percentagePass['last'] = data[0].numberPassLast / data[0].candidatesLast * 100
          $scope.percentagePass['beforeLast'] = data[0].numberPassBeforeLast / data[0].candidatesBeforeLast * 100
          $scope.percentagePass['change'] = $scope.percentagePass['this'] - $scope.percentagePass['last']
          $scope.percentagePass['changeLast'] = $scope.percentagePass['last'] - $scope.percentagePass['beforeLast']

    getTopSchools = () ->
      params = 'where={"region":"' + $scope.region + '", "school_type":"secondary"}&max_results=10&sort=[("national_rank",1)]'
      $http.get($scope.resourceBaseURI + "?" + params, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.topSchools = data._items

    getPerformance = () ->
      params = 'district/?region=' + $scope.region + '&school_type=secondary'
      $http.get($scope.resourceBaseURI + "performance/" + params, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.performanceData = data
          drawPlots()

    graphPerformanceData = (data) ->
      performanceCurrent = []
      performancePrevious = []
      numberPassCurrent = []
      numberPassPrevious = []
      performanceChange = []
      
      data.forEach( (item) ->
        performanceObj = {x: item.district || '', y: item.numberPass / item.candidates * 100 || 0}
        performancePrevObj = {x: item.district || '', y: item.numberPassLast / item.candidatesLast * 100 || 0}
        numberPassObj = {x: item.district || '', y: item.numberPass || 0}
        numberPassPrevObj = {x: item.district || '', y: item.numberPassLast || 0}
        performanceChangeObj = {x: item.district || '', y: performanceObj.y - performancePrevObj.y}
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

    $scope.$on "gettextLanguageChanged", (e) ->
      # redraw the plots so axis labels, etc are translated

      # will only work if the tab is visible (else d3 fails)
      if $scope.dashTabs.secondary.active
        drawPlots()
      else
        # we have to remember to redraw the plots when the tab
        # finally does become active
        plotsDirty = true

    $scope.$watch "dashTabs.secondary.active", (val) ->
      if val and plotsDirty
        drawPlots()

    getData = () ->
      getPerformanceTotal()
      getPerformance()
      getTopSchools()
      
    drawPlots = () ->
      if $scope.performanceData
        graphPerformanceData($scope.performanceData)
        plotMultiBarChart('#performanceChartSecondary', $scope.graphPerformance)
        plotMultiBarHorizontalChart('#numberPassChartSecondary', $scope.graphNumberPass)
        plotMultiBarHorizontalChart("#performanceChangeChartSecondary", $scope.graphPerformanceChange)

    $scope.initView = () ->
      getRegions(getData)

    $scope.refreshView = () ->
      getData()

