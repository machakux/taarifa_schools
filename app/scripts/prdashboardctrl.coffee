'use strict'

angular.module('taarifaApp')

  .controller 'PrimaryDashboardCtrl', ($scope, $http, $timeout,
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

      totals:
        { sizeX: 6, sizeY: 6, row: 0, col: 6 }
      top:
        { sizeX: 6, sizeY: 4, row: 2, col: 0 }
      report:
        { sizeX: 12, sizeY: 10, row: 6, col: 0}
      plots: [
        { sizeX: 12, sizeY: 5, row: 16, col: 0 },
        { sizeX: 6, sizeY: 5, row: 21, col: 0 }
        { sizeX: 6, sizeY: 5, row: 21, col: 6 }
      ]
    }

    $scope.plots = [
      {id:"performanceChartPrimary", title: gettext("Percentage pass by district (this & last year)")},
      {id:"numberPassChartPrimary", title: gettext("Number of passed studets")},
      {id:"performanceChangeChartPrimary", title: gettext("Change in % pass from previous year")}
    ]

    $scope.numberComparators = [
      {'value': '$gt', 'label': gettext('Greater than')},
      {'value': '$lt', 'label': gettext('Less than')},
      {'value': '$gte', 'label': gettext('Greater than or equal to')},
      {'value': '$lte', 'label': gettext('Less than or equal to')}
    ]
    $scope.passGoalComparator = $scope.numberComparators[2]
    $scope.passGoalLimits = (x for x in [0..100] by 10)
    $scope.passGoalLimit = 60

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
      $http.get($scope.resourceBaseURI + 'performance/school_type?school_type=primary&region=' + $scope.region, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.percentagePass = {}
          $scope.percentagePass.this = data[0].numberPass / data[0].candidates * 100
          $scope.percentagePass.last = data[0].numberPassLast / data[0].candidatesLast * 100
          $scope.percentagePass.beforeLast = data[0].numberPassBeforeLast / data[0].candidatesBeforeLast * 100
          $scope.percentagePass.change = $scope.percentagePass.this - $scope.percentagePass.last
          $scope.percentagePass.changeLast = $scope.percentagePass.last - $scope.percentagePass.beforeLast
          $scope.performanceTotal = data[0]

    getSchoolsCount = () ->
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': {
                    "school_type":"primary",
                    "region":$scope.region})
        .success (data, status, headers, config) ->
          $scope.schoolsCount = data.count
          getCountImprovedThan()
          getCountByGoal()
          getCountByOwnership()
          getEnrolmentSum()
          getStaffSum()

    getCountImprovedThan = () ->
      # modalSpinner.open()
      $scope.improvedThan = {}
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': {
                    "percentage_pass_change":{"$gte": 10},
                    "school_type":"primary",
                    "region":$scope.region})
        .success (data, status, headers, config) ->
          $scope.improvedThan.current = data
          $scope.improvedThan.current.percent = ($scope.improvedThan.current.count/$scope.schoolsCount * 100)
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': {
                    "percentage_pass_change_last":{"$gte": 10},
                    "school_type":"primary",
                    "region":$scope.region})
        .success (data, status, headers, config) ->
          $scope.improvedThan.last = data
          # modalSpinner.close()

    getCountByOwnership = () ->
      endpoint = 'count/ownership?region=' + $scope.region + '&school_type=primary'
      $http.get($scope.resourceBaseURI + endpoint, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.schoolsCountByOwner = data
          $scope.countByOwnerGraphData = $scope.graphArray(data, 'ownership', 'count')
          plotDonutChart('#ownershipCountDonutChartPr', $scope.countByOwnerGraphData)

    getEnrolmentSum = () ->
      endpoint = 'sum/ownership/number_enrolled?region=' + $scope.region + '&school_type=primary'
      $http.get($scope.resourceBaseURI + endpoint, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.enrolledSumByOwner = data
          $scope.enrolledByOwnerGraphData = $scope.graphArray(data, '_id', 'sum')
          plotDonutChart('#ownershipEnrollmentDonutChartPr', $scope.enrolledByOwnerGraphData)

    getStaffSum = () ->
      params = '?region=' + $scope.region + '&school_type=primary'
      endpointTeaching = 'sum/ownership/number_teaching_staff' + params
      endpointNonTeaching = 'sum/ownership/number_non_teaching_staff_by_school,number_non_teaching_staff_by_govt' + params
      $http.get($scope.resourceBaseURI + endpointTeaching, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.sumTeachingStaff = $scope.graphArray(data, '_id', 'sum')
      $http.get($scope.resourceBaseURI + endpointNonTeaching, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.sumNonTeachingStaff = $scope.graphArray(data, '_id', 'sum')

    getTopSchools = () ->
      params = 'where={"region":"' + $scope.region + '", "school_type":"primary"}&max_results=50&sort=[("national_rank",1)]'
      $http.get($scope.resourceBaseURI + "?" + params, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.topSchools = data._items

    getCountByGoal = () ->
      # modalSpinner.open()
      $scope.reachedGoal = {}
      comparator = $scope.passGoalComparator.value
      wherePr = {}
      wherePrLast = {}
      
      passQuery = {}
      passQuery[comparator] = $scope.passGoalLimit
      
      wherePr['percentage_pass'] = passQuery
      wherePr.school_type = 'primary'
      wherePr.region = $scope.region
      
      wherePrLast['percentage_pass_last'] = passQuery
      wherePrLast.school_type = 'primary'
      wherePrLast.region = $scope.region

      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': wherePr)
        .success (data, status, headers, config) ->
          $scope.reachedGoal = data
          $scope.reachedGoal.percent = ($scope.reachedGoal.count/$scope.schoolsCount * 100)

      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': wherePrLast)
        .success (data, status, headers, config) ->
          $scope.reachedGoal.last = data
          # modalSpinner.close()

    getPerformance = () ->
      params = 'district/?region=' + $scope.region + '&school_type=primary'
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

    $scope.graphArray = (data, x_field, y_field) ->
      graph = []
      data.forEach( (item) ->
        itemObj = {x: item[x_field] || '', y: item[y_field] || 0}
        if itemObj.x isnt '' or itemObj.y isnt 0
          graph.push itemObj
      )
      graph

    $scope.$on "gettextLanguageChanged", (e) ->
      # redraw the plots so axis labels, etc are translated

      # will only work if the tab is visible (else d3 fails)
      if $scope.dashTabs.primary.active
        drawPlots()
      else
        # we have to remember to redraw the plots when the tab
        # finally does become active
        plotsDirty = true

    $scope.$watch "dashTabs.primary.active", (val) ->
      if val and plotsDirty
        drawPlots()

    $scope.onGoalUpdated = (limit, comparator) ->
      if limit
        $scope.passGoalLimit = limit
      if comparator
        $scope.passGoalComparator = comparator
      getCountByGoal()

    getData = () ->
      getPerformanceTotal()
      getPerformance()
      getTopSchools()
      getSchoolsCount()
      
    drawPlots = () ->
      if $scope.performanceData
        graphPerformanceData($scope.performanceData)
        plotMultiBarChart('#performanceChartPrimary', $scope.graphPerformance)
        plotMultiBarHorizontalChart('#numberPassChartPrimary', $scope.graphNumberPass)
        plotMultiBarHorizontalChart("#performanceChangeChartPrimary", $scope.graphPerformanceChange)
      if $scope.countByOwnerGraphData
        plotDonutChart('#ownershipCountDonutChartPr', $scope.countByOwnerGraphData)
      if $scope.enrolledByOwnerGraphData
        plotDonutChart('#ownershipEnrollmentDonutChartPr', $scope.enrolledByOwnerGraphData)

    $scope.initView = () ->
      getRegions(getData)

    $scope.refreshView = () ->
      getData()

