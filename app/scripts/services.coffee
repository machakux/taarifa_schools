'use strict'

angular.module('taarifaApp')

 .factory 'resourceStats', ($http, $q, populationData) ->
    result = {}

    getStats = (region, district, groupfield, cache) ->
      def = $q.defer()
      url = "/api/schools/performance/" + groupfield
      filterFields = {"region":region, "district":district}
      filters = []

      _.keys(filterFields).forEach((x) ->
        if filterFields[x] then filters.push(x + "=" + filterFields[x]))

      filter = filters.join("&")

      if filter then url += "?" + filter

      # FIXME: use $cacheFactory to cache also the processed data
      $http.get(url, cache: cache)
        .success (data, status, headers, config) ->
          geoField = _.contains(['region','district'], groupfield)
          data.forEach((x) ->
            f = _.find(x.numberPass)
            x.perPass = (x.numberPass / x.candidates * 100).toFixed(2)
            x.perPassLast = (x.numberPassLast / x.candidatesLast * 100).toFixed(2)
            x.perPassBeforeLast = (x.numberPassBeforeLast / x.candidatesBeforeLast * 100).toFixed(2)
            x.perChange = x.perPass - x.perPassLast
            # all done, call the callback
            def.resolve(data)
          )

      return def.promise

    result.getStats = getStats

    return result


  .factory 'modalSpinner', ($modal, $timeout) ->
    modalDlg = null

    # shared counter to allow multiple invocations of
    # open/close
    ctr = {val: 0}

    openSpinner = () ->
      ++ctr.val
      if ctr.val > 1 then return
      modalDlg = $modal.open
        templateUrl: '/views/spinnerdlg.html'
        backdrop: "static"
        size: "sm"

    closeSpinner = () ->
      --ctr.val
      if ctr.val < 1
        # If the close event comes really quickly after the
        # open event the close will fail if the open is not
        # yet completed. Hence add a timeout.
        # FIXME: better solution?
        $timeout(modalDlg.close, 300)
        ctr.val = 0

    res =
        open: openSpinner
        close: closeSpinner

  .factory 'populationData', ($http, $q) ->
    def = $q.defer()
    url = '/data/population_novillages.json'
    result = {}

    $http.get(url).then((data) ->
      #allGrouped = _.groupBy(data.data,"Region")
      #_.keys(grouped).forEach((r) ->
      #  grouped[r] = _.groupBy(grouped[r],"District")
      #  _.keys(grouped[r]).forEach((d) ->
      #    grouped[r][d] = _.groupBy(grouped[r][d],"Ward")))

      # create 3 indices on the data for convenience
      # we can do this since all names happen to be unique
      # FIXME: eventually should be delegated to a database
      regionGroups = _.groupBy(data.data, "Region")
      districtGroups = _.groupBy(data.data, "District")
      wardGroups = _.groupBy(data.data, "Ward")

      lookup = (r,d,w) ->
        try
          if w
            wardGroups[w][0].Both_Sexes
          else if d
            districtGroups[d].filter((d) ->
              d.Ward == "")[0].Both_Sexes
          else if r
            regionGroups[r].filter((d) ->
              !d.District)[0].Both_Sexes
          else
            d3.sum(_.chain(regionGroups)
              .values(regionGroups)
              .flatten()
              .filter((d) ->
                !d.District)
              .pluck("Both_Sexes")
              .value())
        catch e
          return -1

      result.lookup = lookup

      def.resolve(result))

    return def.promise

  .factory 'populationData', ($http, $q) ->
    def = $q.defer()
    url = '/data/population_novillages.json'
    result = {}

    $http.get(url).then((data) ->
      #allGrouped = _.groupBy(data.data,"Region")
      #_.keys(grouped).forEach((r) ->
      #  grouped[r] = _.groupBy(grouped[r],"District")
      #  _.keys(grouped[r]).forEach((d) ->
      #    grouped[r][d] = _.groupBy(grouped[r][d],"Ward")))

      # create 3 indices on the data for convenience
      # we can do this since all names happen to be unique
      # FIXME: eventually should be delegated to a database
      regionGroups = _.groupBy(data.data, "Region")
      districtGroups = _.groupBy(data.data, "District")
      wardGroups = _.groupBy(data.data, "Ward")

      lookup = (r,d,w) ->
        try
          if w
            wardGroups[w][0].Both_Sexes
          else if d
            districtGroups[d].filter((d) ->
              d.Ward == "")[0].Both_Sexes
          else if r
            regionGroups[r].filter((d) ->
              !d.District)[0].Both_Sexes
          else
            d3.sum(_.chain(regionGroups)
              .values(regionGroups)
              .flatten()
              .filter((d) ->
                !d.District)
              .pluck("Both_Sexes")
              .value())
        catch e
          return -1

      result.lookup = lookup

      def.resolve(result))

    return def.promise

  .factory 'ApiResource', ($resource, $http, flash) ->
    (resource, args) ->
      Resource = $resource "/api/#{resource}/:id"
      , # Default arguments
        args
      , # Override methods
        query:
          method: 'GET'
          isArray: false
      Resource.update = (id, data) ->
        # We need to remove special attributes starting with _ since they are
        # not defined in the schema and the data will not validate and the
        # update be rejected
        putdata = {}
        for k, v of data when k[0] != '_'
          putdata[k] = v
        $http.put("/api/#{resource}/"+id, putdata,
                  headers: {'If-Match': data._etag})
        .success (res, status) ->
          if status == 200 and res._status == 'OK'
            flash.success = "#{resource} successfully updated!"
            data._etag = res._etag
          if status == 200 and res._status == 'ERR'
            for field, message of res._issues
              flash.error = "#{field}: #{message}"
      Resource.patch = (id, data, etag) ->
        $http
          method: 'PATCH'
          url: "/api/#{resource}/"+id
          data: data
          headers: {'If-Match': etag}
      return Resource

  .factory 'MainResource', (ApiResource) ->
    ApiResource 'schools'

  .factory 'Facility', (ApiResource) ->
    ApiResource 'facilities'

  .factory 'Request', (ApiResource) ->
    ApiResource 'requests'

  .factory 'Service', (ApiResource) ->
    ApiResource 'services'

  .factory 'Map', ($filter) ->
    (id, opts) =>

      defaults =
        clustering: true
        markerType: "regular"
        coverage: false
        heatmap: false
        showScale: false

      options = _.extend(defaults, opts)

      mapLayer = L.tileLayer(
        'https://{s}.tiles.mapbox.com/v3/emilli.jj2l2761/{z}/{x}/{y}.png',
        attribution: '<a href="https://www.mapbox.com/about/maps/">© Mapbox © OpenStreetMap</a>')

      satLayer = L.tileLayer(
        'http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: '(c) Esri')

      baseMaps =
        "Map": mapLayer
        "Satellite": satLayer

      overlays = {}

      if options.clustering
        markerLayer = new L.MarkerClusterGroup();
      else
        markerLayer = L.featureGroup()

      overlays.Schools = markerLayer
      defaultLayers = [mapLayer, markerLayer]

      if options.coverage
        coverageLayer = L.TileLayer.maskCanvas
          radius: 1000
          useAbsoluteRadius: true   # true: r in meters, false: r in pixels
          color: '#000'             # the color of the layer
          opacity: 0.5              # opacity of the not covered area
          noMask: false             # true results in normal (filled) circled, instead masked circles
          lineColor: '#A00'         # color of the circle outline if noMask is true

        overlays["Coverage (1km)"] = coverageLayer

      if options.heatmap
        heatmapLayer = new HeatmapOverlay
          radius: 15
          maxOpacity: .7
          scaleRadius: false
          useLocalExtrema: true

        overlays["Functionality Heatmap"] = heatmapLayer

        # we add the heatmap layer by default
        defaultLayers.push(heatmapLayer)

      map = L.map id,
        center: new L.LatLng -6.3153, 35.15625
        zoom: 6
        fullscreenControl: true
        layers: defaultLayers

      if options.heatmap
        # FIXME: remove the heatmap layer again to workaround
        # https://github.com/pa7/heatmap.js/issues/130
        map.removeLayer(heatmapLayer)

      # add a layer selector
      layerSelector = L.control.layers(baseMaps, overlays).addTo(map)

      # add a distance scale
      if options.showScale
        scale = L.control.scale().addTo(map)

      makePopup = (poi) ->
        cleanKey = (k) ->
          $filter('titlecase')(k.replace("_"," "))

        cleanValue = (k,v) ->
          if v instanceof Date
            v.getFullYear()
          else if k == "location"
            v.coordinates.toString()
          else
            v

        header = '<h5><a href="#/schools/' + poi._id + '">' + poi.name + '</a></h5>'

        # FIXME: can't this be offloaded to angular somehow?
        fields = _.keys(poi).sort().map((k) ->
            #cleanKey(k) + String(cleanValue(k, poi[k]))
            '<span class="popup-key">' + cleanKey(k) + '</span>: ' +
            '<span class="popup-value">' + String(cleanValue(k,poi[k])) + '</span>'
          ).join('<br />')

        html = '<div class="popup">' + header + fields + '</div>'

      @openPopup = (marker_id) ->
        marker = window.markers[marker_id]
        if marker?
          if options.clustering
            markerLayer.zoomToShowLayer marker, ->
              marker.openPopup()
          else
            marker.openPopup()

      @closePopup = (marker_id) ->
        marker = window.markers[marker_id]
        if marker?
          marker.closePopup()

      @clearMarkers = () ->
        if options.clustering
          markerLayer.clearLayers()

      # FIXME: more hardcoded statusses
      makeAwesomeIcon = (status) ->
        if status == 'functional'
          color = 'blue'
        else if status == 'not functional'
          color = 'red'
        else if status == 'needs repair'
          color = 'orange'
        else
          color = 'black'

        icon = L.AwesomeMarkers.icon
          prefix: 'glyphicon',
          icon: 'tint',
          markerColor: color

      makeMarker = (poi) ->
        [lng,lat] = poi.location.coordinates
        mt = options.markerType

        if mt == "circle"
          m = L.circleMarker L.latLng(lat,lng),
            stroke: false
            radius: 5
            fillOpacity: 1
            fillColor: statusColor(poi.status_group)
        else
          m = L.marker L.latLng(lat,lng),
              icon: makeAwesomeIcon(poi.status_group)

      @addPOI = (pois) ->
        spinner.spin()
        window.markers = {}
        pois.forEach (poi) ->
          if poi.location?
            [lng,lat] = poi.location.coordinates
            popup = makePopup(poi)
            m = makeMarker(poi)
            m.bindPopup popup
            markerLayer.addLayer(m)
            window.markers[poi._id] = m

        if options.coverage
          coords = pois.map (x) -> [x.location.coordinates[1], x.location.coordinates[0]]
          coverageLayer.setData coords
        spinner.stop()


      @zoomToMarkers = () ->
        bounds = markerLayer.getBounds()
        if bounds.isValid()
          map.fitBounds(bounds)

      @centerToMarkers = (zoom) ->
        @zoomToMarkers()
        zoom = if zoom? and parseInt(zoom)? then parseInt(zoom) else 6
        map.setZoom(zoom)

      return this

  # Get an angular-dynamic-forms compatible form description from a Facility
  # given a facility code
  .factory 'FacilityForm', (Facility) ->
    (facility_code) ->
      Facility.get(facility_code: facility_code)
        # Return a promise since dynamic-forms needs the form template in
        # scope when the controller is invoked
        .$promise.then (facility) ->
          typemap =
            string: 'text'
            integer: 'number'
            # FIXME a number field assumes integers, therefore use text
            float: 'number'
            boolean: 'checkbox'
          mkfield = (type, label, step) ->
            type: type
            label: label
            step: step
            class: "form-control"
            wrapper: '<div class="form-group"></div>'
          fields = {}
          for f, v of facility._items[0].fields
            if v.type == 'point'
              fields.longitude = mkfield 'number', 'longitude', 'any'
              fields.latitude = mkfield 'number', 'latitude', 'any'
              fields.longitude.model = 'location.coordinates[0]'
              fields.latitude.model = 'location.coordinates[1]'
            else
              # Use the field name as label if no label was specified
              fields[f] = mkfield typemap[v.type] || v.type, v.label || f
              if v.type in ['float', 'number']
                fields[f].step = 'any'
              if v.allowed?
                fields[f].type = 'select'
                options = {}
                options[label] = label: label for label in v.allowed
                fields[f].options = options
          fields.submit =
            type: "submit"
            label: "Save"
            class: "btn btn-primary"
          return fields
