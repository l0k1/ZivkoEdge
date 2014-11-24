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

var LineGauge = {
  new: func( g, props )
  {
    var m = { parents: [ LineGauge, Gauge.new(g,props) ] };

    # draw one line for each pair of indicators
    var numLines = int(size(props.indicator)/2) + 1;

    #draw each colored line-segment
    foreach( var segment; props.segment ) {
      var a0 = m.interpolate( segment.start, props.table );
      var a1 = m.interpolate( segment.end, props.table );
      var y0 = props.h + props.y - props.h*a0;
      var y1 = props.h + props.y - props.h*a1;

      for( var n = 1; n < numLines; n+=1  ) {
        var x0 = props.x + (props.w*n/numLines);

        g.createChild("path")
          .moveTo( x0, y0 )
          .lineTo( x0, y1 )
          .setStrokeLineWidth(props.stroke)
          .setColor(segment.color);
        }
    }

    # create one animation for each indicator
    for( var n = 0; n < size(props.indicator); n+=1 ) {

      var indicator = props.indicator[n];
      var lineNo = int(n/2)+1;


      var translateAnimation = TranslateAnimation.new( g, indicator.needle, func(o) {
        var a = m.interpolate( indicator.getValue(), props.table );
        return { 
          x: me.xTranslate,
          y: props.y + props.h*(1 -a),
        };
      });
      translateAnimation.xTranslate = props.x + props.w * lineNo/numLines;
      append(m.animations, translateAnimation );
    }

    return m;
  },

};

var ArcGauge = {
  new: func( g, props )
  {
    var m = { parents: [ ArcGauge, DigitGauge.new(g,props) ] };

    foreach( var segment; props.segment ) {
      var a0 = m.interpolate( segment.start, props.table );
      var a1 = m.interpolate( segment.end, props.table );
      var x0 = props.x + props.w - props.w*math.cos(a0);
      var y0 = props.h + props.y - props.h*math.sin(a0);
      var x1 = props.x + props.w - props.w*math.cos(a1);
      var y1 = props.h + props.y - props.h*math.sin(a1);

      g.createChild("path")
        .moveTo( x0, y0 )
        .arcSmallCW( props.w, props.h, 0, x1-x0, y1-y0 )
        .setStrokeLineWidth(props.stroke)
        .setColor(segment.color);

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
        segment: [
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
        segment: [
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
        segment: [
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
        segment: [
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
        segment: [
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
        segment: [
          { start: 100, end: 140, color: [ 1, 1, 0] },
          { start: 140, end: 212, color: [ 0, 1, 0] },
          { start: 212, end: 250, color: [ 1, 1, 0] },
          { start: 250, end: 280, color: [ 1, 0, 0] },
        ],
      }),

      DigitGauge.new(m.g, {
        indicator: { digits: "FQDigits", getValue: func() { efis.readSensor("FQ")*1000; } },
      }),

      LineGauge.new(m.g, {
        x: 1024/3,
        y: 568, 
        w: 1024/3,
        h: 115,
        table: [
          [ 100,  0.0 ],
          [ 500,  1.0 ]
        ],
        stroke: 4,
        indicator:  [
          { needle: "CHTNeedle0", getValue: func() { efis.readSensor("CHT0"); } },
          { needle: "CHTNeedle1", getValue: func() { efis.readSensor("CHT1"); } },
          { needle: "CHTNeedle2", getValue: func() { efis.readSensor("CHT2"); } },
          { needle: "CHTNeedle3", getValue: func() { efis.readSensor("CHT3"); } },
          { needle: "CHTNeedle4", getValue: func() { efis.readSensor("CHT4"); } },
          { needle: "CHTNeedle5", getValue: func() { efis.readSensor("CHT5"); } },
        ],
        segment: [
          { start: 100, end: 147, color: [ 1, 1, 0] },
          { start: 147, end: 437, color: [ 0, 1, 0] },
          { start: 437, end: 464, color: [ 1, 1, 0] },
          { start: 464, end: 500, color: [ 1, 0, 0] },
        ],
      }),

      LineGauge.new(m.g, {
        x: 1024*2/3,
        y: 568, 
        w: 1024/3,
        h: 115,
        table: [
          [ 1300,  0.0 ],
          [ 1800,  1.0 ]
        ],
        stroke: 4,
        indicator:  [
          { needle: "EGTNeedle0", getValue: func() { efis.readSensor("EGT0"); } },
          { needle: "EGTNeedle1", getValue: func() { efis.readSensor("EGT1"); } },
          { needle: "EGTNeedle2", getValue: func() { efis.readSensor("EGT2"); } },
          { needle: "EGTNeedle3", getValue: func() { efis.readSensor("EGT3"); } },
          { needle: "EGTNeedle4", getValue: func() { efis.readSensor("EGT4"); } },
          { needle: "EGTNeedle5", getValue: func() { efis.readSensor("EGT5"); } },
        ],
        segment: [
          { start: 1300, end: 1350, color: [ 1, 1, 0] },
          { start: 1350, end: 1550, color: [ 0, 1, 0] },
          { start: 1550, end: 1700, color: [ 1, 1, 0] },
          { start: 1700, end: 1800, color: [ 1, 0, 0] },
        ],
      }),
    ];

    return m;
  },

  getName: func()
  {
    return "ed";
  },


  update: func() 
  {
    foreach( var g; me.gauges ) 
      g.applyAnimations(me);
  },

};

append( EFISplugins, ED );
