var PFD = {

  new: func( efis )
  {
    print(" * PFD");

    var m = { parents: [ PFD, EFISScreen.new(efis) ] };

    var svgGroup = m.g.createChild("group", "svgfile");    
    canvas.parsesvg(svgGroup, "/Aircraft/ZivkoEdge/Models/EFIS/PFD.svg");


    m.g.getElementById( "HeadingBug" ).setCenter( m.g.getElementById("Compass").getCenter() );

    m.animations = [
      TranslateAnimation.new( m.g, "Horizon", func(o) {
        return { 
          y: 10 * o.efis.readSensor( "pitch" ), 
          x: 0 
        };
      }),

      RotateAnimation.new( m.g, "Horizon", func(o) {
        return { 
          angle: -o.efis.readSensor("roll")*D2R,
          cy: SCREEN_HEIGHT_2 - o.efis.readSensor( "pitch" ), 
          cx: SCREEN_WIDTH_2, 
        };
      }),

      RotateAnimation.new( m.g, "Compass", func(o,e) {
        var c = e.getCenter();
        return { 
          angle: -o.efis.readSensor("heading")*D2R,
          cy: c[1],
          cx: c[0],
        };
      }),

      RotateAnimation.new( m.g, "HeadingBug", func(o,e) {
        var c = e.getCenter();
        return { 
          angle: o.efis.readSensor("headingBug")*D2R,
          cy: c[1],
          cx: c[0],
        };
      }),

      TranslateAnimation.new( m.g, "SlipSkidBall", func(o) {
        # returned value is approx angle in radians * 10
        # convert to deg, max dev is 125px for 10 deg
        # v * 5.729 * 125 / 10 = 71.6125
        var v = o.efis.readSensor("slipSkid") * -71.6125;
        return { 
          y: 0,
          x: v < -125 ? -125 : v > 125 ? 125 : v,
        };
      }),

      TextAnimation.new( m.g, "Heading", func(o) {
        return sprintf("%03d", math.round(o.efis.readSensor("heading")));
      }),

      TextAnimation.new( m.g, "Field_TopRight", func(o) {
        return sprintf("%+.1fG",  -0.0310810 * o.efis.readSensor("accel") );
      }),

      TextAnimation.new( m.g, "Field_BottomRight", func(o) {
        return sprintf("%4.2f", o.efis.readSensor("kollsmann"));
      }),

      TextAnimation.new( m.g, "AltimeterThousands", func(o) {
        return sprintf("%2d", int(o.efis.readSensor("altitude")/1000));
      }),

      TextAnimation.new( m.g, "AltimeterHundrets", func(o) {
        return sprintf("%03d", math.abs(int(math.fmod(o.efis.readSensor("altitude"),1000))));
      }),

      TextAnimation.new( m.g, "AltimeterLadderLabel0", func(o) {
        return o.getAltitudeLabel(0);
      }),

      TextAnimation.new( m.g, "AltimeterLadderLabel1", func(o) {
        return o.getAltitudeLabel(1);
      }),

      TextAnimation.new( m.g, "AltimeterLadderLabel2", func(o) {
        return o.getAltitudeLabel(2);
      }),

      TextAnimation.new( m.g, "AltimeterLadderLabel3", func(o) {
        return o.getAltitudeLabel(3);
      }),

      TextAnimation.new( m.g, "AltimeterLadderLabel4", func(o) {
        return o.getAltitudeLabel(4);
      }),

      TranslateAnimation.new( m.g, "AltimeterLadderLabels", func(o) {
        var v = o.efis.readSensor("altitude");
        return { 
          y: 152 * math.fmod(v,200) / 200,
          x: 0,
        };
      }),

      TranslateAnimation.new( m.g, "AltimeterLadder", func(o) {
        var v = o.efis.readSensor("altitude");
        return { 
          y: 76 * math.fmod(v,100) / 100,
          x: 0,
        };
      }),

      TextAnimation.new( m.g, "ASIDigits", func(o) {
        var v = o.efis.readSensor("ias");
        return v >= 1.0 ? sprintf("%3d", v ) : "---"; 
      }),

      TextAnimation.new( m.g, "ASILadderLabel0", func(o) {
        return o.getASILabel(0);
      }),

      TextAnimation.new( m.g, "ASILadderLabel1", func(o) {
        return o.getASILabel(1);
      }),

      TextAnimation.new( m.g, "ASILadderLabel2", func(o) {
        return o.getASILabel(2);
      }),

      TextAnimation.new( m.g, "ASILadderLabel3", func(o) {
        return o.getASILabel(3);
      }),

      TextAnimation.new( m.g, "ASILadderLabel4", func(o) {
        return o.getASILabel(4);
      }),

      TranslateAnimation.new( m.g, "ASILadderLabels", func(o) {
        var v = o.efis.readSensor("ias");
        return { 
          y: v > 40 ?  38 * 8 + 152*math.fmod(v,20)/20 : 38 * v / 5,
          x: 0,
        };
      }),

      TranslateAnimation.new( m.g, "AltimeterLadder", func(o) {
        var v = o.efis.readSensor("ias");
        return { 
          y: v > 40 ?  38 * 8 + 76*math.fmod(v,10)/10 : 38 * v / 5,
          x: 0,
        };
      }),

      TranslateAnimation.new( m.g, "TrajectoryMarker", func(o) {
        var hOffset = geo.normdeg180(o.efis.readSensor("track") - o.efis.readSensor("heading") );
        var vOffset = o.efis.readSensor("pitch") - o.efis.readSensor("path");
        if( o.efis.readSensor("gs") < 1.0 ) {
          hOffset = vOffset = 0;
        }
        return { 
          y: vOffset * 10,
          x: hOffset * 10
        };
      }),

      RotateAnimation.new( m.g, "TrajectoryMarker", func(o) {
        return { 
          angle: -o.efis.readSensor("roll")*D2R,
          cy: SCREEN_HEIGHT_2 - o.efis.readSensor("pitch"),
          cx: SCREEN_WIDTH_2,
        };
      }),

    ];

    m.g.getElementById("Altimeter")
      .set("clip", "rect( 137,1024,639,860 )" );

    m.g.getElementById("ASI")
      .set("clip", "rect( 137,165,639,0 )" );

    return m;
  },

  getAltitudeLabel: func(n)
  {
    # draw labels every 200ft
    var v = int(me.efis.readSensor("altitude")/200)*2-4;
    return sprintf("%2.1f", (v+n*2)/10 );
  },

  getASILabel: func(n)
  {
    # draw labels every 20kt
    var v = int(me.efis.readSensor("ias")/20)*20 - 40;
    v = v < 0 ?  0 : v;
    return sprintf("%3d", v+n*20 )
  },
};

append( EFISplugins, PFD );
