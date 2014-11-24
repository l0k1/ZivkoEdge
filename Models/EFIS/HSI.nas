var SimpleGpsNavigator = {
  new: func( gps, root )
  {
    var m = { parents: [ SimpleGpsNavigator ] };
    m._gps = gps;
    m._root = root;

    m._destination = {
      id: m._root.initNode("id","","STRING"),
      type: root.initNode("type","","STRING"),
      name: root.initNode("name","","STRING"),
      lat: root.initNode("lat",0,"DOUBLE"),
      lon: root.initNode("lon",0,"DOUBLE"),
      dist: root.initNode("dist",0,"DOUBLE"),
      bearing: root.initNode("bearing",0,"DOUBLE"),
      info1: root.initNode("info1","","STRING"),
      info2: root.initNode("info2","","STRING"),
      valid: root.initNode("valid","0","BOOL"),
      coord: geo.aircraft_position(),
      selected: root.initNode("selected-course",0,"DOUBLE"),
    };

    return m;
  },

  update: func() 
  {
    if( me._destination.valid.getValue() == 0 )
      return;

    var myPos = geo.aircraft_position();
    me._destination.bearing.setValue( myPos.course_to( me._destination.coord ) );
    me._destination.dist.setValue( myPos.distance_to( me._destination.coord ) * M2NM );
  },

  getFrequency: func( type, f )
  {
    if( type == "vor" ) {
      return f/100;
    }
    return f;
  },

  setDestination: func(type, id)
  {
    print("New destination: " ~ id ~ "(" ~ type ~ ")");
    me._destination.name.setValue( id );
    me._destination.type.setValue( type );

    if( type == "airport" ) {
      var info = airportinfo( id );
      me._destination.id.setValue( info.id );
      me._destination.name.setValue( info.name );
      me._destination.coord.set_lat(info.lat);
      me._destination.coord.set_lon(info.lon);
      me._destination.lat.setValue( info.lat );
      me._destination.lon.setValue( info.lon );
      me._destination.dist.setValue( 999999 );
      me._destination.bearing.setValue( 0 );
      me._destination.name.setValue( info.name );
      me._destination.info1.setValue( "TWR 118.00" );
      me._destination.info2.setValue( "RWY 00/36" );
      me._destination.valid.setValue( 1 );
    } else {
      var info = navinfo( type, id );
      if( size(info) == 0 ) {
        me._destination.id.setValue( id );
        me._destination.name.setValue( "" );
        me._destination.coord.set_lat(info.lat);
        me._destination.coord.set_lon(info.lon);
        me._destination.dist.setValue( 999999 );
        me._destination.bearing.setValue( 0 );
        me._destination.name.setValue( "" );
        me._destination.info1.setValue( "" );
        me._destination.info2.setValue( "" );
        me._destination.valid .setValue( 0 );
      } else {
        var nav = info[0];
        me._destination.id.setValue( nav.id );
        me._destination.name.setValue( nav.name );
        me._destination.coord.set_lat(nav.lat);
        me._destination.coord.set_lon(nav.lon);
        me._destination.dist.setValue( 999999 );
        me._destination.bearing.setValue( 0 );
        me._destination.name.setValue( nav.name );
        me._destination.info1.setValue( "FRQ " ~ me.getFrequency( type, nav.frequency ) );
        me._destination.info2.setValue( "" );
        me._destination.valid .setValue( 1 );
      }
    }
  },
 
};

var SimpleGps = {
  new: func( efis, root )
  {
    var m = { parents: [ SimpleGps ] };

    m.efis = efis;
    m.root = root;

    m.navigator = [
      SimpleGpsNavigator.new(m, root.getChild("gps",0,1) ),
      SimpleGpsNavigator.new(m, root.getChild("gps",1,1) ),
    ];

    return m;
  },

  update: func() 
  {
    me._enabled or return;
    foreach( var n; me.navigator )
      n.update();
    settimer( func() { me.update(); }, 0.1 );
  },

  _enabled: 0,

  enable: func(b)
  {
    if( b ) {
      me._enabled and return;
      me._enabled = 1;
      me.update();
    } else {
      me._enabled or return;
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
      ontimeout: func(d) { m.screenTimeout(d); },
    });

    m.hsiConfigScreen = Dialog.new( { 
      svg: "/Aircraft/ZivkoEdge/Models/EFIS/Dialog.svg",
      parent: m.g,
      labels: [ "ARPT", "NDB", "CDI", "VOR" ],
      ontimeout: func(d) { m.screenTimeout(d); },
    });

    m.gps = SimpleGps.new( efis, props.globals.getNode("/instrumentation/efis/hsi",1) );
    m.gps.navigator[0].setDestination("airport", "EDDH");
    m.gps.navigator[1].setDestination("vor", "DHE");
    m.gps.enable(1);

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
        return getprop("/instrumentation/efis/hsi/gps[0]/valid");
      }),

      SelectAnimation.new( m.g, "To", func(o) {
        var offsetDeg = geo.normdeg180(
                  getprop("/instrumentation/efis/hsi/gps[0]/bearing")
                  - getprop("/instrumentation/efis/hsi/gps[0]/selected-course"));
        return offsetDeg > -90 and offsetDeg <= 90;
      }),

      SelectAnimation.new( m.g, "From", func(o) {
        var offsetDeg = geo.normdeg180(
                  getprop("/instrumentation/efis/hsi/gps[0]/bearing")
                  - getprop("/instrumentation/efis/hsi/gps[0]/selected-course"));
        return offsetDeg <= -90 or offsetDeg > 90;
      }),

      RotateAnimation.new( m.g, "VOR", func(o,e) {
        var c = e.getCenter();
        return { 
          angle: getprop("/instrumentation/efis/hsi/gps[0]/selected-course")*D2R,
          cy: c[1],
          cx: c[0],
        };
      }),

      TranslateAnimation.new( m.g, "CDIDeflectionBar", func(o) {
        var offsetDeg = geo.normdeg180(
                  getprop("/instrumentation/efis/hsi/gps[0]/bearing")
                  - getprop("/instrumentation/efis/hsi/gps[0]/selected-course"));

        offsetDeg = offsetDeg > 10 ? 10 : offsetDeg < -10 ? -10 : offsetDeg;
        return { 
          y: 0,
          x: 52/5 * offsetDeg,
        };
      }),


      SelectAnimation.new( m.g, "GreenArrow", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[1]/valid");
      }),

      RotateAnimation.new( m.g, "GreenArrow", func(o,e) {
        var c = e.getCenter();
        return { 
          angle: getprop("/instrumentation/efis/hsi/gps[1]/bearing")*D2R,
          cy: c[1],
          cx: c[0],
        };
      }),


      PrintfTextAnimation.new( m.g, "VORLine1", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[0]/id");
      }),

      PrintfTextAnimation.new( m.g, "VORLine2", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[0]/dist");
      }),

      PrintfTextAnimation.new( m.g, "VORLine3", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[0]/name");
      }),

      PrintfTextAnimation.new( m.g, "VORLine4", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[0]/info1");
      }),

      PrintfTextAnimation.new( m.g, "VORLine5", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[0]/info2");
      }),

      PrintfTextAnimation.new( m.g, "ADFLine1", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[1]/id");
      }),

      PrintfTextAnimation.new( m.g, "ADFLine2", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[1]/dist");
      }),

      PrintfTextAnimation.new( m.g, "ADFLine3", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[1]/name");
      }),

      PrintfTextAnimation.new( m.g, "ADFLine4", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[1]/info1");
      }),

      PrintfTextAnimation.new( m.g, "ADFLine5", func(o) {
        return getprop("/instrumentation/efis/hsi/gps[1]/info2");
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
  STATE_CDI:    5,
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

    } elsif( me.state == me.STATE_CDI ) {
      # knob rotation changes cdi orientation
      setprop( "/instrumentation/efis/hsi/gps[0]/selected-course",
        normalizePeriodic( 0, 360, getprop("/instrumentation/efis/hsi/gps[0]/selected-course") + n ) );
    }
  },

  screenTimeout: func( dlg )
  {
    if( dlg == me.configScreen ) {
      if( me.state == me.STATE_CONFIG )
        me.state = me.STATE_NORMAL;
    } elsif ( dlg == me.hsiConfigScreen ) {
      if( me.state == me.STATE_HSI )
        me.state = me.STATE_NORMAL;
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
      var reply = me.hsiConfigScreen.knobPressed( b );
      if( reply == 0 ) { #ARPT
      } elsif( reply == 1 ) { #NDB
      } elsif( reply == 2 ) { #CDI
        me.state = me.STATE_CDI;
        return 1;
      } elsif( reply == 3 ) { #VOR
      }
      me.state = me.STATE_NORMAL;
      return 1; # event consumed

    } elsif( me.state == me.STATE_CDI ) {
      me.state = me.STATE_NORMAL;
      return 1; # event consumed
    }

    return 0; # event not consumed
  },
};

append( EFISplugins, HSI );
