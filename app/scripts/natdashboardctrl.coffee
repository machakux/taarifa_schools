'use strict'

angular.module('taarifaApp')

  .controller 'NationalDashboardCtrl', ($scope, $http, $timeout, $window,
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

      totals:
        { sizeX: 6, sizeY: 6, row: 0, col: 6 }

      count:
        { sizeX: 6, sizeY: 4, row: 2, col: 0 }

      report:
        { sizeX: 12, sizeY: 14, row: 6, col: 0}

      plots: [
        { sizeX: 12, sizeY: 6, row: 20, col: 0 },
        { sizeX: 6, sizeY: 8, row: 26, col: 0 }
        { sizeX: 6, sizeY: 8, row: 26, col: 6 }
      ]

      topPrimary:
        { sizeX: 6, sizeY: 6, row: 29, col: 0 }

      topSecondary:
        { sizeX: 6, sizeY: 6, row: 29, col: 6 }

    }

    $scope.plots = [
      {id:"performanceChart", title: gettext("Percentage pass")},
      {id:"numberPassChart", title: gettext("Number of passed students")},
      {id:"performanceChangeChart", title: gettext("Change in % pass")}]

    $scope.groups = ['region', 'district']
    $scope.schoolTypes = ['all', 'primary', 'secondary']
    $scope.schoolTypeChoice = "all"
    $scope.numberComparators = [
      {'value': '$gt', 'label': gettext('Greater than')},
      {'value': '$lt', 'label': gettext('Less than')},
      {'value': '$gte', 'label': gettext('Greater than or equal to')},
      {'value': '$lte', 'label': gettext('Less than or equal to')}
    ]
    $scope.passGoalComparator = $scope.numberComparators[2]
    $scope.passGoalLimits = (x for x in [0..100] by 10)
    $scope.passGoalLimit = 60

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
          $scope.typeCount = data.sort((a, b) ->
            return b.count - a.count
          )
          graphCountTypeData($scope.typeCount)
          plotDonutChart('#typeCountDonutChart', $scope.graphTypeCount)
          # modalSpinner.close()

    getCountImprovedThan = () ->
      # modalSpinner.open()
      $scope.improvedThan = {}
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': {
                    "percentage_pass_change":{"$gte": 10},
                    "school_type":"primary"})
        .success (data, status, headers, config) ->
          $scope.improvedThan.primary = data
          $scope.improvedThan.primary.percent = ($scope.improvedThan.primary.count/$scope.typeCountIndexed.primary * 100)
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': {
                    "percentage_pass_change":{"$gte": 10},
                    "school_type":"secondary"})
        .success (data, status, headers, config) ->
          $scope.improvedThan.secondary = data
          $scope.improvedThan.secondary.percent = ($scope.improvedThan.secondary.count/$scope.typeCountIndexed.secondary * 100)
          # modalSpinner.close()

    getCountByGoal = () ->
      # modalSpinner.open()
      $scope.reachedGoal = {}
      comparator = $scope.passGoalComparator.value
      whereSec = {}
      whereSecLast = {}
      wherePr = {}
      wherePrLast = {}
      
      passQuery = {}
      passQuery[comparator] = $scope.passGoalLimit
      
      whereSec['percentage_pass'] = passQuery
      whereSec.school_type = 'secondary'
     
      whereSecLast['percentage_pass_last'] = passQuery
      whereSecLast.school_type = 'secondary'
      
      wherePr['percentage_pass'] = passQuery
      wherePr.school_type = 'primary'
      
      wherePrLast['percentage_pass_last'] = passQuery
      wherePrLast.school_type = 'primary'

      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': wherePr)
        .success (data, status, headers, config) ->
          $scope.reachedGoal.primary = data
          $scope.reachedGoal.primary.percent = ($scope.reachedGoal.primary.count/$scope.typeCountIndexed.primary * 100)
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': whereSec)
        .success (data, status, headers, config) ->
          $scope.reachedGoal.secondary = data
          $scope.reachedGoal.secondary.percent = ($scope.reachedGoal.secondary.count/$scope.typeCountIndexed.secondary * 100)

      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': wherePrLast)
        .success (data, status, headers, config) ->
          $scope.reachedGoal.primaryLast = data
      $http.get($scope.resourceBaseURI + 'total_count',
                cache: cacheHttp
                params:
                  '$where': whereSecLast)
        .success (data, status, headers, config) ->
          $scope.reachedGoal.secondaryLast = data
          # modalSpinner.close()

    getCountByOwnership = () ->
      endpointSc = 'count/ownership?&school_type=secondary'
      endpointPr = 'count/ownership?&school_type=primary'
      $scope.schoolsCountByOwner = {}
      $http.get($scope.resourceBaseURI + endpointSc, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.schoolsCountByOwner.secondary = $scope.graphArray(data, 'ownership', 'count')
          plotDonutChart('#ownershipCountDonutChartNatSc', $scope.schoolsCountByOwner.secondary)
      $http.get($scope.resourceBaseURI + endpointPr, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.schoolsCountByOwner.primary = $scope.graphArray(data, 'ownership', 'count')
          plotDonutChart('#ownershipCountDonutChartNatPr', $scope.schoolsCountByOwner.primary)

    getEnrolmentSum = () ->
      endpointSc = 'sum/ownership/number_enrolled?school_type=secondary'
      endpointPr = 'sum/ownership/number_enrolled?school_type=primary'
      $scope.enrolledSumByOwner = {}
      $http.get($scope.resourceBaseURI + endpointSc, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.enrolledSumByOwner.secondary = $scope.graphArray(data, '_id', 'sum')
          plotDonutChart('#ownershipEnrollmentDonutChartNatSc', $scope.enrolledSumByOwner.secondary)
      $http.get($scope.resourceBaseURI + endpointPr, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.enrolledSumByOwner.primary = $scope.graphArray(data, '_id', 'sum')
          plotDonutChart('#ownershipEnrollmentDonutChartNatPr', $scope.enrolledSumByOwner.primary)

    getStaffSum = () ->
      paramsSc = '?school_type=secondary'
      paramsPr = '?school_type=primary'
      endpointTeaching = 'sum/ownership/number_teaching_staff'
      endpointNonTeaching = 'sum/ownership/number_non_teaching_staff_by_school,number_non_teaching_staff_by_govt'
      $scope.sumTeachingStaff = {}
      $scope.sumNonTeachingStaff = {}
      $http.get($scope.resourceBaseURI + endpointTeaching + paramsSc, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.sumTeachingStaff.secondary = $scope.graphArray(data, '_id', 'sum')
      $http.get($scope.resourceBaseURI + endpointNonTeaching + paramsSc, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.sumNonTeachingStaff.secondary = $scope.graphArray(data, '_id', 'sum')
      $http.get($scope.resourceBaseURI + endpointTeaching + paramsPr, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.sumTeachingStaff.primary = $scope.graphArray(data, '_id', 'sum')
      $http.get($scope.resourceBaseURI + endpointNonTeaching + paramsSc, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.sumNonTeachingStaff.primary = $scope.graphArray(data, '_id', 'sum')


    getPerformanceSchoolType = () ->
      $scope.shoolTypeChoice = "all"

      # modalSpinner.open()

      $http.get($scope.resourceBaseURI + 'performance/school_type',
        cache: cacheHttp
        params: _.omit($scope.params,'group'))
        .success (data, status, headers, config) ->
          $scope.percentagePass = {}
          data.forEach( (x) ->
            x.passChange = x.percentPass - x.percentPassLast
            $scope.percentagePass[x.school_type] =
              this: x.numberPass / x.candidates * 100
              last: x.numberPassLast / x.candidatesLast * 100
              beforeLast: x.numberPassBeforeLast / x.candidatesBeforeLast * 100
              change: x.percent - x.percentLast
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
 
    getPerformance = (download) ->
      url = $scope.resourceBaseURI + "performance/" + $scope.params.group
      if download? and download
        $window.open(url + '?fmt=csv')
      if $scope.schoolTypeChoice and $scope.schoolTypeChoice isnt 'all'
          url += '?school_type=' + $scope.schoolTypeChoice
          return
      $http.get(url, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.performanceData = data
          graphPerformanceData($scope.performanceData)
          plotMultiBarChart('#performanceChart', $scope.graphPerformance)
          plotMultiBarHorizontalChart('#numberPassChart', $scope.graphNumberPass)
          plotMultiBarHorizontalChart("#performanceChangeChart", $scope.graphPerformanceChange)

    $scope.downloadPerformance = () ->
      getPerformance(true)

    getTopSchools = (downloadPrimary, downloadSecondary) ->
      params_sec = 'where={"school_type":"secondary"}&max_results=100&sort=[("national_rank",1)]'
      params_pr = 'where={"school_type":"primary"}&max_results=100&sort=[("national_rank",1)]'
      isDownload = false
      if downloadPrimary? and downloadPrimary
        $window.open($scope.resourceBaseURI + 'download?fmt=csv&school_type=primary&max_results=100&sort=[["national_rank",1]]')
        isDownload = true
      if downloadSecondary? and downloadSecondary
        $window.open($scope.resourceBaseURI + 'download?fmt=csv&school_type=secondary&max_results=100&sort=[["national_rank",1]]')
        isDownload = true
      if isDownload
        return
      $http.get($scope.resourceBaseURI + "?" + params_sec, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.topSchoolsSecondary = data._items
      $http.get($scope.resourceBaseURI + "?" + params_pr, cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.topSchoolsPrimary = data._items

    $scope.downloadTopSchools = (primary, secondary) ->
        getTopSchools(primary, secondary)

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
      $scope.typeCountIndexed = {}
      $scope.schoolsTotal = 0
      data.forEach( (item) ->
        typeObj = {x: item.school_type || '', y: item.count || 0}
        typeCount.push typeObj
        $scope.typeCountIndexed[item.school_type || ''] = item.count || 0
        $scope.schoolsTotal += typeObj.y
      )
      getCountImprovedThan()
      getCountByGoal()
      $scope.graphTypeCount = typeCount

    $scope.onSchoolTypeSelected = (event) ->
      schoolType = event.target.attributes.value.value
      $scope.schoolTypeChoice = schoolType
      getPerformance()

    $scope.onGoalUpdated = (limit, comparator) ->
      if limit
        $scope.passGoalLimit = limit
      if comparator
        $scope.passGoalComparator = comparator
      getCountByGoal()

    drawPlots = () ->
      if $scope.performanceData
        graphPerformanceData($scope.performanceData)
        plotMultiBarChart('#performanceChart', $scope.graphPerformance)
        plotMultiBarHorizontalChart('#numberPassChart', $scope.graphNumberPass)
        plotMultiBarHorizontalChart("#performanceChangeChart", $scope.graphPerformanceChange)
      if $scope.typeCount
        graphCountTypeData($scope.typeCount)
        plotDonutChart('#typeCountDonutChart', $scope.graphTypeCount)
      getStaffSum()

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
      getCountByOwnership()
      getEnrolmentSum()

    initView()
