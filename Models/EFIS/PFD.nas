var INHG2HPA = 1013.25 / 29.92133;
var HPA2INHG = 1 / INHG2HPA;
var PFD = {

  new: func( efis )
  {
    print(" * PFD");

    var m = { parents: [ PFD, EFISSVGScreen.new(efis, "PFD.svg" ) ] };

    m.g.getElementById( "HeadingBug" ).setCenter( m.g.getElementById("Compass").getCenter() );

    m.configScreen = Dialog.new( { 
      svg: "/Aircraft/ZivkoEdge/Models/EFIS/Dialog.svg",
      parent: m.g,
      labels: [ "HSI", "QNH" ],
    });

    m.animations = [
      SelectAnimation.new( m.configScreen.overlay, nil, func(o) {
        o.state == o.STATE_CONFIG;
      }),

      SelectAnimation.new( m.g, "Field_BottomRight_Selector", func(o) {
        o.state == o.STATE_QNH;
      }),
      
      CombinedAnimation.new( m.g, "Horizon", func(o) {
        var pitch = 10 * o.efis.readSensor( "pitch" );
        var roll = -o.efis.readSensor("roll")*D2R;
        
        return [{
            type: "translate",
            y: pitch, 
            x: 0 
          },{
            type: "rotate",
            angle: roll,
            cy: SCREEN_HEIGHT_2 - pitch, 
            cx: SCREEN_WIDTH_2, 
          }]
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
        if( o.efis.config.pressureUnit.getValue() == "inhg" )
          return sprintf("%4.2f", o.efis.readSensor("kollsmann"));
        else
          return sprintf("%4d", o.efis.readSensor("kollsmann") * INHG2HPA );
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

      TranslateAnimation.new( m.g, "ASILadder", func(o) {
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
          hOffset = 0;
          vOffset = o.efis.readSensor("pitch");
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

  getName: func()
  {
    return "pfd";
  },

  STATE_NORMAL: 0,
  STATE_CONFIG: 1,
  STATE_QNH:    2,
  state: 0,

  knobPositionChanged: func( n ) 
  {
    if( me.state == me.STATE_NORMAL ) {

      # knob rotation turns heading bug
      me.efis.writeSensor("headingBug", 
        normalizePeriodic( 0, 360, me.efis.readSensor("headingBug") + n ) );

    } elsif( me.state == me.STATE_CONFIG ) {

      # forward knob rotation to the config screen
      me.configScreen.knobPositionChanged( n );

    } elsif( me.state == me.STATE_QNH ) {
      # knob rotation changes kollsmann
      var step = me.efis.config.pressureUnit.getValue() == "inhg" ? 0.01 : HPA2INHG;
      me.efis.writeSensor("kollsmann", 
          me.efis.readSensor("kollsmann") + n * step );
    }
  },

  knobPressed: func( b ) 
  {
    if( b == 0 ) return; #ignore release

    if( me.state == me.STATE_NORMAL ) {
      me.state = me.STATE_CONFIG;
      me.configScreen.init();
      return 1; # event consumed, stay here

    } elsif( me.state == me.STATE_CONFIG ) {

      var reply = me.configScreen.knobPressed( b );
      if( reply == 0 ) { #HSI
        me.state = me.STATE_NORMAL;
        return 0; # event not consumed (switch screen)
      } elsif( reply == 1 ) { #QNH
        me.state = me.STATE_QNH;
        return 1; # event consumed (stay here)
      }

    } elsif( me.state == me.STATE_QNH ) {
      me.state = me.STATE_NORMAL;
      return 1; # event consumed
    }

    return 0; # event not consumed
  },
};

append( EFISplugins, PFD );
