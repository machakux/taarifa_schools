function getDimensions(selector, wMargin, hMargin){

  var pn = d3.select(selector).node().parentNode;
  var h = d3.select(pn).style('height').replace('px', '') - (hMargin || 60);
  var w = d3.select(pn).style('width').replace('px', '') - (wMargin || 40);

  return {height: h, width: w};
}


function prepareChartContainer(selector){
  var dims = getDimensions(selector);
  var h = dims.height, w = dims.width;

  var margin = {
      top: 10,
      right: 20,
      bottom: 20,
      left: 20
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  svg = d3.select(selector + " svg");
  if (!svg[0][0]) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)

  } else {
    //Note width/height may have changed
    svg.attr("width", width + margin.left + margin.right)
       .attr("height", height + margin.top + margin.bottom);
  }

}

function plotMultiBarChart(selector, data){

  /* $(selector).html('<svg><svg>')
  selectorSVG = selector + ' svg'
  
  var dimension = getDimensions(selector)
  $(selectorSVG).css({'min-height': dimension.height || 300, 'min-width': dimension.width || 800, 'max-width': '100%'}) */
  
  prepareChartContainer(selector);

  nv.addGraph(function() {
      var chart = nv.models.multiBarChart()
        .transitionDuration(350)
        .reduceXTicks(false)   //If 'false', every single x-axis tick label will be rendered.
        .rotateLabels(40)      //Angle to rotate x-axis labels.
        .showControls(false)   //Allow user to switch between 'Grouped' and 'Stacked' mode.
        .groupSpacing(0.1);    //Distance between each group of bars.

      chart.yAxis.tickFormat(d3.format(',.2f'));
      d3.select(selector + ' svg').datum(data).call(chart);

      nv.utils.windowResize(chart.update);

      return chart;
  });
}

function plotMultiBarHorizontalChart(selector, data){
  
  prepareChartContainer(selector);

  nv.addGraph(function() {
    var chart = nv.models.multiBarHorizontalChart()
        .showValues(false)           //Show bar value next to each bar.
        .tooltips(true)             //Show tooltips on hover.
        .transitionDuration(350)
        .showControls(false);        //Allow user to switch between "Grouped" and "Stacked" mode.

    chart.yAxis.tickFormat(d3.format(',.2f'));

    d3.select(selector + ' svg').datum(data).call(chart);

    nv.utils.windowResize(chart.update);

    return chart;
  });

}

function plotDonutChart(selector, data){
  
  prepareChartContainer(selector);

  nv.addGraph(function() {
    var chart = nv.models.pieChart()
        .showLabels(true)     //Display pie labels
        .labelThreshold(.05)  //Configure the minimum slice size for labels to show up
        .labelType("percent") //Configure what type of data to show in the label. Can be "key", "value" or "percent"
        .donut(true)          //Turn on Donut mode. Makes pie chart look tasty!
        .donutRatio(0.35)     //Configure how big you want the donut hole size to be.
        ;

    d3.select(selector + " svg").datum(data).transition().duration(350).call(chart);
    nv.utils.windowResize(chart.update);

    return chart;
  });

}

function shorten(s, maxlen) {
  if (!s) return s;
  if (!maxlen) maxlen = 10;
  return (s.length > maxlen) ? s.slice(0, maxlen - 3) + "..." : s;
}
