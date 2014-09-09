var SimpleGpsNavigator = {
  new: func( gps )
  {
    var m = { parents: [ SimpleGpsNavigator ] };
    m.gps = gps;

    return m;
  },

  update: func() 
  {
  },

  _destination: "",
  setDestination: func(s)
  {
    me._destination = s;
  },
 
};

var SimpleGps = {
  new: func( efis )
  {
    var m = { parents: [ SimpleGps ] };

    m.efis = efis;

    m.navigator = [
      SimpleGpsNavigator.new(m),
      SimpleGpsNavigator.new(m),
    ];

    return m;
  },

  update: func() 
  {
    foreach( var n; navigator )
      n.update();
    settimer( me.update, 2 );
  },

  _enabled: 0,

  enable: func(b)
  {
    if( b ) {
      if( me._enabled ) return;
      me._enabled = 1;
      me.update();
    } else {
      if( !me._enabled ) return;
    }

  }
};

var normalizePeriodic = func( min, max, val )
{
 var range = max - min;
 return val - range*geo.floor((val - min)/range);
}

var HSI = {
  new: func( efis )
  {
    print(" * HSI");
    var m = { parents: [ HSI, EFISSVGScreen.new(efis, "HSI.svg" ) ] };

    m.g.getElementById( "HeadingBug" ).setCenter( m.g.getElementById("Compass").getCenter() );

    m.configScreen = Dialog.new( { 
      svg: "/Aircraft/ZivkoEdge/Models/EFIS/Dialog.svg",
      parent: m.g,
      labels: [ "ENG", "ADF", "BUG", "HSI" ],
    });

    m.hsiConfigScreen = Dialog.new( { 
      svg: "/Aircraft/ZivkoEdge/Models/EFIS/Dialog.svg",
      parent: m.g,
      labels: [ "ARPT", "NDB", "CDI", "VOR" ],
    });

    m.animations = [
      SelectAnimation.new( m.configScreen.overlay, nil, func(o) {
        o.state == o.STATE_CONFIG;
      }),

      SelectAnimation.new( m.hsiConfigScreen.overlay, nil, func(o) {
        o.state == o.STATE_HSI;
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

      TextAnimation.new( m.g, "Heading", func(o) {
        return sprintf("%03d", math.round(o.efis.readSensor("heading")));
      }),

      TextAnimation.new( m.g, "Latitude", func(o) {
        return o.formatDeg( 0, o.efis.readSensor("latitude"));
      }),

      TextAnimation.new( m.g, "Longitude", func(o) {
        return o.formatDeg( 0, o.efis.readSensor("longitude"));
      }),

      TextAnimation.new( m.g, "IAS", func(o) {
        return sprintf("%03d", o.efis.readSensor("ias"));
      }),

      TextAnimation.new( m.g, "GS", func(o) {
        return sprintf("%03d", o.efis.readSensor("gs"));
      }),

      TextAnimation.new( m.g, "Wind", func(o) {
        return sprintf("%02d/%02d", 
          o.efis.readSensor("windDir"),
          o.efis.readSensor("windSpeed") );
      }),

      SelectAnimation.new( m.g, "VOR", func(o) {
        return 0;
      }),

      SelectAnimation.new( m.g, "GreenArrow", func(o) {
        return 0;
      }),
    ];

    return m;
  },

  formatDeg: func(isLongitude, v)
  {
    var NSEW = [ [ "N", "S" ], [ "E", "W" ] ];
    var format = [ "%s %02d %04.2f", "%s %03d %04.2f" ];

    var idx1 = isLongitude ? 1 : 0;
    var idx2 = 0;
    if( v < 0 ) {
      idx2 = 1;
      v = -v;
    }
    var deg = int(v);
    var min = (v - deg) * 60;
    return sprintf( format[idx1], NSEW[idx1][idx2], deg, min );
  }, 

  getName: func()
  {
    return "hsi";
  },

  STATE_NORMAL: 0,
  STATE_CONFIG: 1,
  STATE_ADF:    2,
  STATE_BUG:    3,
  STATE_HSI:    4,
  state: 0,

  knobPositionChanged: func( n ) 
  {
    if( me.state == me.STATE_NORMAL ) {

      # knob rotation turns heading bug
      me.efis.writeSensor("headingBug", 
        normalizePeriodic( 0, 360, me.efis.readSensor("headingBug") + n ) );

    } elsif( me.state == me.STATE_HSI ) {

      # forward knob rotation to the config screen
      me.hsiConfigScreen.knobPositionChanged( n );

    } elsif( me.state == me.STATE_CONFIG ) {

      # forward knob rotation to the config screen
      me.configScreen.knobPositionChanged( n );

    } elsif( me.state == me.STATE_BUG ) {
      # knob rotation changes heading bug
      me.efis.writeSensor("headingBug", 
        normalizePeriodic( 0, 360, me.efis.readSensor("headingBug") + n ) );
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
      if( reply == 0 ) { #ENG
        me.state = me.STATE_NORMAL;
        return 0; # event not consumed (switch screen)
      } elsif( reply == 1 ) { #ADF
        me.state = me.STATE_ADF;
        return 1; # event consumed (stay here)
      } elsif( reply == 2 ) { #BUG
        me.state = me.STATE_BUG;
        return 1; # event consumed (stay here)
      } elsif( reply == 3 ) { #HSI
        me.state = me.STATE_HSI;
        me.hsiConfigScreen.init();
        return 1; # event consumed (stay here)
      }

    } elsif( me.state == me.STATE_ADF ) {
      me.state = me.STATE_NORMAL;
      return 1; # event consumed
    } elsif( me.state == me.STATE_BUG ) {
      me.state = me.STATE_NORMAL;
      return 1; # event consumed
    } elsif( me.state == me.STATE_HSI ) {
      me.state = me.STATE_NORMAL;
      return 1; # event consumed
    }

    return 0; # event not consumed
  },
};

append( EFISplugins, HSI );
