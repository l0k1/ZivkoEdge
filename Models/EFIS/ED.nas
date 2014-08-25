var Gauge = {
  new: func( g, props )
  {
    var m = { parents: [ Gauge ] };
    m.animations = [];

    return m;
  },

  interpolate: func( x, pairs )
  {
    var n = size(pairs)-1;
    if( x <= pairs[0][0] ) {
      return pairs[0][1];
    }
    if( x >= pairs[n][0] ) {
      return pairs[n][1];
    }
    for( var i = 0; i < n; i = i + 1 ) {
      if( x > pairs[i][0] and x <= pairs[i+1][0] ) {
        var x1 = pairs[i][0];
        var x2 = pairs[i+1][0];
        var y1 = pairs[i][1];
        var y2 = pairs[i+1][1];
        return (x - x1)/(x2-x1)*(y2-y1)+y1;
      }
    }
    return pairs[i][1];
  },

  applyAnimations: func(o) 
  {
    foreach( var a; me.animations ) 
      a.apply(me);
  },
};

var DigitGauge = {
  new: func( g, props )
  {
    var m = { parents: [ DigitGauge, Gauge.new(g,props) ] };

    append(m.animations,
      PrintfTextAnimation.new( g, props.indicator.digits, func(o) {
        return props.indicator.getValue();
      }));

    return m;
  },

};

var ArcGauge = {
  new: func( g, props )
  {
    var m = { parents: [ ArcGauge, DigitGauge.new(g,props) ] };

    foreach( var arc; props.arc ) {
      var a0 = m.interpolate( arc.start, props.table );
      var a1 = m.interpolate( arc.end, props.table );
      var x0 = props.x + props.w - props.w*math.cos(a0);
      var y0 = props.h + props.y - props.h*math.sin(a0);
      var x1 = props.x + props.w - props.w*math.cos(a1);
      var y1 = props.h + props.y - props.h*math.sin(a1);

      g.createChild("path")
        .moveTo( x0, y0 )
        .arcSmallCW( props.w, props.h, 0, x1-x0, y1-y0 )
        .setStrokeLineWidth(props.stroke)
        .setColor(arc.color);

    }

    append(m.animations,
      TranslateAnimation.new( g, props.indicator.needle, func(o) {
        var a = m.interpolate( props.indicator.getValue(), props.table );
        return { 
          x: props.x + props.w - props.w*math.cos(a),
          y: props.h + props.y - props.h*math.sin(a),
        };
      }));

    append(m.animations,
      RotateAnimation.new( g, props.indicator.needle, func(o) {
        var a = m.interpolate( props.indicator.getValue(), props.table );
        var x = props.x + props.w - props.w*math.cos(a);
        var y = props.h + props.y - props.h*math.sin(a);
        return { 
          angle: a,
          cy: y,
          cx: x,
        };
      }));

    return m;
  },

};

var ED = {
  new: func( efis )
  {
    print(" * ED");
    var m = { parents: [ ED, EFISSVGScreen.new(efis, "ED.svg" ) ] };

    m.gauges = [

      ArcGauge.new(m.g, {
        x: 25,
        y: 25, 
        w: 462,
        h: 256,
        table: [
          [ 0,     0*D2R ],
          [ 2900, 90*D2R ]
        ],
        indicator: { needle: "RPMNeedle", digits: "RPMDigits", getValue: func() { efis.readSensor("RPM"); } },
        stroke: 4,
        arc: [
          { start:    0, end:  700, color: [ 1, 1, 0] },
          { start:  700, end: 2750, color: [ 0, 1, 0] },
          { start: 2750, end: 2850, color: [ 1, 1, 0] },
          { start: 2850, end: 2900, color: [ 1, 0, 0] },
        ],
      }),

      ArcGauge.new(m.g, {
        x: 512+25,
        y: 25, 
        w: 462,
        h: 256,
        table: [
          [ 10,  0*D2R ],
          [ 35, 90*D2R ]
        ],
        indicator: { needle: "MAPNeedle", digits: "MAPDigits", getValue: func() { efis.readSensor("MAP"); } },
        stroke: 4,
        arc: [
          { start: 10, end: 25, color: [ 1, 1, 0] },
          { start: 25, end: 30, color: [ 0, 1, 0] },
          { start: 30, end: 35, color: [ 1, 0, 0] },
        ],
      }),

      ArcGauge.new(m.g, {
        x: 25,
        y: 347, 
        w: 291,
        h: 135,
        table: [
          [   0,  0*D2R ],
          [ 120, 90*D2R ]
        ],
        indicator: { needle: "OPNeedle", digits: "OPDigits", getValue: func() { efis.readSensor("OP"); } },
        stroke: 4,
        arc: [
          { start:   0, end:   25, color: [ 1, 0, 0] },
          { start:   25, end:  55, color: [ 1, 1, 0] },
          { start:   55, end:  95, color: [ 0, 1, 0] },
          { start:   95, end: 116, color: [ 1, 1, 0] },
          { start:  116, end: 120, color: [ 1, 0, 0] },
        ],
      }),

      ArcGauge.new(m.g, {
        x: 25+1024/3,
        y: 347, 
        w: 291,
        h: 135,
        table: [
          [ 15,  0*D2R ],
          [ 70, 90*D2R ]
        ],
        indicator: { needle: "FPNeedle", digits: "FPDigits", getValue: func() { efis.readSensor("FP"); } },
        stroke: 4,
        arc: [
          { start: 15, end: 29, color: [ 1, 1, 0] },
          { start: 29, end: 55, color: [ 0, 1, 0] },
          { start: 55, end: 65, color: [ 1, 1, 0] },
          { start: 65, end: 70, color: [ 1, 0, 0] },
        ],
      }),

      ArcGauge.new(m.g, {
        x: 25+1024*2/3,
        y: 347, 
        w: 291,
        h: 135,
        table: [
          [ 0,   0*D2R ],
          [ 40, 90*D2R ]
        ],
        stroke: 4,
        indicator: { needle: "FFNeedle", digits: "FFDigits", getValue: func() { efis.readSensor("FF"); } },
        arc: [
          { start: 0,  end:  2, color: [ 1, 1, 0] },
          { start: 2,  end: 35, color: [ 0, 1, 0] },
          { start: 35, end: 40, color: [ 1, 0, 0] },
        ],
      }),

      ArcGauge.new(m.g, {
        x: 25,
        y: 532, 
        w: 291,
        h: 135,
        table: [
          [ 100,  0*D2R ],
          [ 280, 90*D2R ]
        ],
        stroke: 4,
        indicator: { needle: "OTNeedle", digits: "OTDigits", getValue: func() { efis.readSensor("OT"); } },
        arc: [
          { start: 100, end: 140, color: [ 1, 1, 0] },
          { start: 140, end: 212, color: [ 0, 1, 0] },
          { start: 212, end: 250, color: [ 1, 1, 0] },
          { start: 250, end: 280, color: [ 1, 0, 0] },
        ],
      }),

      DigitGauge.new(m.g, {
        indicator: { digits: "FQDigits", getValue: func() { efis.readSensor("FQ")*1000; } },
      }),

#CHT 
# Yellow: less than 64degc
# Green: 65..225 degc
# Yellow: 225..240degc
# Red: 240


    ];

    return m;
  },

  update: func() 
  {
    foreach( var g; me.gauges ) 
      g.applyAnimations(me);
  },

};

append( EFISplugins, ED );
