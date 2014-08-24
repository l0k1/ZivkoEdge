var Gauge = {
  new: func( g, props )
  {
    var m = { parents: [ Gauge ] };

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

    m.animations = [
      TranslateAnimation.new( g, props.indicator.needle, func(o) {
        var a = m.interpolate( props.indicator.getValue(), props.table );
        return { 
          x: props.x + props.w - props.w*math.cos(a),
          y: props.h + props.y - props.h*math.sin(a),
        };
      }),

      RotateAnimation.new( g, props.indicator.needle, func(o) {
        var a = m.interpolate( props.indicator.getValue(), props.table );
        var x = props.x + props.w - props.w*math.cos(a);
        var y = props.h + props.y - props.h*math.sin(a);
        return { 
          angle: a,
          cy: y,
          cx: x,
        };
      }),

      PrintfTextAnimation.new( g, props.indicator.digits, func(o) {
        return props.indicator.getValue();
      }),
    ];

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
  }
};

var ED = {
  new: func( efis )
  {
    print(" * ED");
    var m = { parents: [ ED, EFISSVGScreen.new(efis, "ED.svg" ) ] };

    m.gauges = [

      Gauge.new(m.g, {
        x: 25,
        y: 25, 
        w: 462,
        h: 256,
        table: [
          [ 0,     0*D2R ],
          [ 2800, 90*D2R ]
        ],
        indicator: { needle: "RPMNeedle", digits: "RPMDigits", getValue: func() { efis.readSensor("RPM"); } },
        stroke: 4,
        arc: [
          { start:    0, end:  500, color: [ 1, 1, 0] },
          { start:  500, end: 2750, color: [ 0, 1, 0] },
          { start: 2750, end: 2800, color: [ 1, 0, 0] },
        ],
      }),

      Gauge.new(m.g, {
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

      Gauge.new(m.g, {
        x: 25,
        y: 347, 
        w: 291,
        h: 135,
        table: [
          [ 10,  0*D2R ],
          [ 35, 90*D2R ]
        ],
        indicator: { needle: "OPNeedle", digits: "OPDigits", getValue: func() { efis.readSensor("OP"); } },
        stroke: 4,
        arc: [
          { start: 10, end: 25, color: [ 1, 1, 0] },
          { start: 25, end: 30, color: [ 0, 1, 0] },
          { start: 30, end: 35, color: [ 1, 0, 0] },
        ],
      }),

      Gauge.new(m.g, {
        x: 25+1024/3,
        y: 347, 
        w: 291,
        h: 135,
        table: [
          [ 10,  0*D2R ],
          [ 35, 90*D2R ]
        ],
        indicator: { needle: "FPNeedle", digits: "FPDigits", getValue: func() { efis.readSensor("FP"); } },
        stroke: 4,
        arc: [
          { start: 10, end: 25, color: [ 1, 1, 0] },
          { start: 25, end: 30, color: [ 0, 1, 0] },
          { start: 30, end: 35, color: [ 1, 0, 0] },
        ],
      }),

      Gauge.new(m.g, {
        x: 25+1024*2/3,
        y: 347, 
        w: 291,
        h: 135,
        table: [
          [ 10,  0*D2R ],
          [ 35, 90*D2R ]
        ],
        stroke: 4,
        indicator: { needle: "FFNeedle", digits: "FFDigits", getValue: func() { efis.readSensor("FF"); } },
        arc: [
          { start: 10, end: 25, color: [ 1, 1, 0] },
          { start: 25, end: 30, color: [ 0, 1, 0] },
          { start: 30, end: 35, color: [ 1, 0, 0] },
        ],
      }),

      Gauge.new(m.g, {
        x: 25,
        y: 532, 
        w: 291,
        h: 135,
        table: [
          [ 10,  0*D2R ],
          [ 35, 90*D2R ]
        ],
        stroke: 4,
        indicator: { needle: "OTNeedle", digits: "OTDigits", getValue: func() { efis.readSensor("OT"); } },
        arc: [
          { start: 10, end: 25, color: [ 1, 1, 0] },
          { start: 25, end: 30, color: [ 0, 1, 0] },
          { start: 30, end: 35, color: [ 1, 0, 0] },
        ],
      }),


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
