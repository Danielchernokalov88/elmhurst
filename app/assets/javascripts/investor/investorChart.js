$.getJSON('/api/v1/annotations?initial=true', function(initial_data) {

  Highcharts.setOptions({
      global: {
          useUTC: false
      }
  });

  var high = 0;
  var low = 0;
  var nv = 0;
  var new_price = 0;
  var last1 = 0;
  var first_candlestick_created = false;
  
  window.chart = new Highcharts.StockChart({
      chart: {
          type: 'candlestick',
          renderTo: 'chart',
          events: {
              load: function() {
                  // set up the updating of the chart each second

                  var series1 = this.series[0];
                  var series2 = this.series[1];
                  last1 = series1;
                  setInterval(function() {
                      var x_axis = (new Date()).getTime();
                      /* var last1 = series1.groupedData[series1.groupedData.length - 1]; */
                      $.ajax({
                         url: '/api/v1/annotations',
                         type: 'GET',
                         data: {
                            x_axis: last1.x,
                            open: last1.open,
                            high: last1.high,
                            low: last1.low,
                            close: last1.close,
                            Volume: nv,
                            is_candlestick: true
                         },
                         success: function(points) {
                            console.log('1 min');
                            var price = points.new_price;
                            var total_fulfilled_requests = points.total_fulfilled_requests;
                            shift = series1.data.length > 20;
                            series1.addPoint([x_axis, price, price, price, price], false, shift);
                            series2.addPoint([x_axis, total_fulfilled_requests], true, true);
                            first_candlestick_created = true;
                         },
                      });
                  }, 5000);
                   setInterval(function() {
                    if (first_candlestick_created) {
                        $.ajax({
                            url: '/api/v1/annotations',
                            success: function(points) {
                                nv = points.total_fulfilled_requests;
                                new_price = points.new_price;
                                last1 = series1.data[series1.data.length - 1];
                                var last2 = series2.data[series2.data.length - 1];
                                high = Math.max(last1.high, new_price);
                                low = Math.min(last1.low, new_price);

                                last1.update([
                                    last1.x,
                                    last1.open,
                                    high,
                                    low,
                                    new_price,
                                ], true);

                                console.log('20 sec');

                                last2.update([
                                    last2.x,
                                    nv
                                ]);
                            },
                        });
                    }
                }, 1000);
              }
          }
      },
      
      rangeSelector: {
          inputEnabled: false,
          selected: 1,
          enabled: false
      },
      
      title: {
          text: 'AAPL Historical'
      },
      
      yAxis: [{
          labels: {
              align: 'right',
              x: -3
          },
          title: {
              text: 'OHLC'
          },
          height: '60%',
          lineWidth: 2,
          resize: {
              enabled: true
          }
      }, {
          labels: {
              align: 'right',
              x: -3
          },
          title: {
              text: 'Volume'
          },
          top: '65%',
          height: '35%',
          offset: 0,
          lineWidth: 2
      }],

      scrollbar: {
          enabled: false
      },
      navigator: {
          enabled: true,
      },
      
      tooltip: {
          split: true
      },
      
      xAxis: {
        type: 'datetime',
        tickPixelInterval: 150
      },
      
      series: [{
          type: 'candlestick',
          name: 'AAPL',
          data: initial_data.fulfilled_avg
      }, {
          type: 'column',
          name: 'Volume',
          data: initial_data.total_fulfilled_requests,
          yAxis: 1
      }]
  });

});

// Investment Principal Data
$('#buy_share').on('keyup',function(){
    var value = $("#buy_share").val();
    var item_price = $("#item_price_avg").html();
    $('#rate').val(value* item_price);

});

$('#sell_share').on('keyup',function(){
    var value = $("#sell_share").val();
    var item_price = $("#item_price_avg").html();
    $('#rate1').val(value* item_price);

});