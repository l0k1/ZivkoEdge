#############################################################################
# This file is part of FlightGear, the free flight simulator
# http://www.flightgear.org/
#
# Copyright (C) 2014 Torsten Dreyer, Torsten (at) t3r _dot_ de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#############################################################################

var SCREEN_WIDTH = 1024;
var SCREEN_HEIGHT = 768;

var SCREEN_WIDTH_2 = SCREEN_WIDTH/2;
var SCREEN_HEIGHT_2 = SCREEN_HEIGHT/2;

#
# Base "class" for all Screens
var EFISScreen = {
  new: func( c ) 
  {
    var m = { parents: [EFISScreen] };
    m.g =  c.createGroup();

    m.latitudeNode = props.globals.getNode("/position/latitude-deg");
    m.longitudeNode = props.globals.getNode("/position/longitude-deg");
    m.rollNode = props.globals.getNode("/orientation/roll-deg");
    m.pitchNode = props.globals.getNode("/orientation/pitch-deg");
    m.headingNode = props.globals.getNode("/orientation/heading-magnetic-deg");
    m.accelNode = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec");
    m.kollsmannNode = props.globals.getNode("/instrumentation/altimeter[1]/setting-inhg");
    m.altitudeNode = props.globals.getNode("/instrumentation/altimeter[1]/indicated-altitude-ft");
    m.iasNode = props.globals.getNode("/instrumentation/airspeed-indicator[1]/indicated-speed-kt");
    m.slipSkidNode = props.globals.getNode("/instrumentation/slip-skid-ball/indicated-slip-skid");
    m.gsNode = props.globals.getNode("/velocities/groundspeed-kt");
    m.elapsedNode = props.globals.getNode("/sim/time/elapsed-sec");
    m.windDirNode = props.globals.getNode("/environment/wind-from-heading-deg");
    m.windSpeedNode = props.globals.getNode("/environment/wind-speed-kt");

    return m;
  },

  getLedstripMode: func()
  {
    return 0;
  },

  setEnabled: func(b)
  {
    me.g.setVisible(b);
  },

  getRequiredElement: func( id )
  {
    var e = me.g.getElementById( id);
    if( e == nil ) die(sprintf("missing mandatory element '%s'.",  id) );
    return e;
  },

  getNotNullValue: func( n )
  {
    var v = n.getValue();
    if( v == nil ) return 0;
    return v;
  },

  update: func()
  {
  },

};

var PFD = {

  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: PFD");

    var m = { parents: [ PFD, EFISScreen.new(c) ] };

    var svgGroup = m.g.createChild("group", "svgfile");    
    canvas.parsesvg(svgGroup, "/Aircraft/ZivkoEdge/Models/EFIS/PFD.svg");

    m.horizonElement = m.getRequiredElement("Horizon");
    m.horizonElement.updateCenter();
    m.horizonRotate = m.horizonElement.createTransform();
    m.horizonTranslate = m.horizonElement.createTransform();

    m.compassElement = m.getRequiredElement( "Compass" );
    m.compassElement.updateCenter();
    m.compassRotate = m.compassElement.createTransform();

    m.headingElement = m.getRequiredElement( "Heading" );
    m.headingElement
       .setDrawMode(canvas.Text.TEXT)
       .setFont("LiberationFonts/LiberationSans-Regular.ttf");

    m.topRightFieldElement = m.getRequiredElement( "Field_TopRight" );

    m.topRightFieldElement
       .setDrawMode(canvas.Text.TEXT)
       .setFont("LiberationFonts/LiberationSans-Regular.ttf");

    m.bottomRightFieldElement = m.getRequiredElement("Field_BottomRight" );

    m.bottomRightFieldElement
       .setDrawMode(canvas.Text.TEXT)
       .setFont("LiberationFonts/LiberationSans-Regular.ttf");

    m.altimeterThousands = m.getRequiredElement("AltimeterThousands" );

    m.altimeterThousands
       .setDrawMode(canvas.Text.TEXT)
       .setFont("LiberationFonts/LiberationMono-Regular.ttf");

    m.altimeterHundrets = m.getRequiredElement("AltimeterHundrets" );

    m.altimeterHundrets
       .setDrawMode(canvas.Text.TEXT)
       .setFont("LiberationFonts/LiberationMono-Regular.ttf");

    m.altimeterLadderLabel = [];
    for( var i = 0; i < 5; i+=1 ) {
      append(m.altimeterLadderLabel, m.getRequiredElement("AltimeterLadderLabel" ~ i ));
      m.altimeterLadderLabel[i] 
        .setDrawMode(canvas.Text.TEXT)
        .setFont("LiberationFonts/LiberationMono-Regular.ttf");
    }

    m.altimeterLadderLabels = m.getRequiredElement("AltimeterLadderLabels" );
    m.altimeterLadderLabelsTranslate = m.altimeterLadderLabels.createTransform();

    m.altimeterLadder = m.getRequiredElement("AltimeterLadder");
    m.altimeterLadderTranslate = m.altimeterLadder.createTransform();

    m.getRequiredElement("Altimeter")
      .set("clip", "rect( 137,1024,639,860 )" );

    m.asiDigits = m.getRequiredElement( "ASIDigits" );
    m.asiDigits
       .setDrawMode(canvas.Text.TEXT)
       .setFont("LiberationFonts/LiberationMono-Regular.ttf");

    m.asiLadderLabel = [];
    for( var i = 0; i < 5; i+=1 ) {
      append(m.asiLadderLabel, m.getRequiredElement("ASILadderLabel" ~ i ));
      m.asiLadderLabel[i] 
        .setDrawMode(canvas.Text.TEXT)
        .setFont("LiberationFonts/LiberationMono-Regular.ttf");
    }

    m.asiLadderLabels = m.getRequiredElement("ASILadderLabels" );
    m.asiLadderLabelsTranslate = m.asiLadderLabels.createTransform();

    m.asiLadder = m.getRequiredElement("ASILadder");
    m.asiLadderTranslate = m.asiLadder.createTransform();

    m.getRequiredElement("ASI")
      .set("clip", "rect( 137,165,639,0 )" );

    m.slipSkidTranslate = m.getRequiredElement("SlipSkidBall").createTransform();
    return m;
  },

  update: func()
  {
    var v = 0;

    var roll = me.getNotNullValue( me.rollNode );
    var pitch = me.getNotNullValue( me.pitchNode );

    me.horizonTranslate.setTranslation( 0, pitch * 10 );
    me.horizonRotate.setRotation( -roll * D2R, SCREEN_WIDTH_2, SCREEN_HEIGHT_2-pitch*10 );

    v = me.getNotNullValue( me.headingNode );
    me.compassRotate.setRotation( -v * D2R, me.compassElement.getCenter() );
    me.headingElement.setText( sprintf("%03d", math.round(v)) );

    v = int( -0.310810 * me.getNotNullValue( me.accelNode ) );
    me.topRightFieldElement.setText( sprintf("%+.1fG", v/10) );

    v = me.getNotNullValue( me.kollsmannNode );
    me.bottomRightFieldElement.setText( sprintf("%4.2f", v) );

    v = me.getNotNullValue( me.altitudeNode );
    me.altimeterThousands.setText( sprintf("%2d", int(v/1000)) );
    me.altimeterHundrets.setText( sprintf("%03d", math.abs(int(math.fmod(v,1000)))) );

    me.altimeterLadderTranslate.setTranslation(0, 76 * math.fmod(v,100) / 100 );
    me.altimeterLadderLabelsTranslate.setTranslation(0, 152 * math.fmod(v,200) / 200 );

    # draw labels every 200ft
    v = int(v/200)*2-4;
    for( var i = 0; i < 5; i += 1 ) {
      me.altimeterLadderLabel[i].setText(
        # -400, -200, +0, +200, +400
        sprintf("%2.1f", (v+i*2)/10 )
      );
    }

    v = me.getNotNullValue( me.iasNode );
    me.asiDigits.setText( v >= 1.0 ? sprintf("%3d", v ) : "---" ); 

    me.asiLadderTranslate.setTranslation(0, 
        v > 40 ?  38 * 8 + 76*math.fmod(v,10)/10 :
                  38 * v / 5 );

    me.asiLadderLabelsTranslate.setTranslation(0, 
        v > 40 ?  38 * 8 + 152*math.fmod(v,20)/20 :
                  38 * v / 5 );

    # draw labels every 20kt
    v = int(v/20)*20 - 40;
    v = v < 0 ?  0 : v;

    for( var i = 0; i < 5; i += 1 ) {
      me.asiLadderLabel[i].setText(
        sprintf("%3d", v+i*20 )
      );
    }

    # returned value is approx angle in radians * 10
    # convert to deg, max dev is 125px for 10 deg
    # v * 5.729 * 125 / 10 = 71.6125
    v = me.getNotNullValue( me.slipSkidNode ) * 71.6125;
    v = v < -125 ? -125 : v > 125 ? 125 : v;
    me.slipSkidTranslate.setTranslation( -v, 0 ); 
  },

};

var HSI = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: HSI");
    var m = { parents: [ HSI, EFISScreen.new(c) ] };

    var svgGroup = m.g.createChild("group", "svgfile");    
    canvas.parsesvg(svgGroup, "/Aircraft/ZivkoEdge/Models/EFIS/HSI.svg");

    m.compassElement = m.getRequiredElement( "Compass" );
    m.compassElement.updateCenter();
    m.compassRotate = m.compassElement.createTransform();
    m.headingElement = m.getRequiredElement( "Heading" );

    m.latitudeElement = m.getRequiredElement("Latitude" );
    m.longitudeElement = m.getRequiredElement("Longitude" );

    m.iasElement = m.getRequiredElement("IAS" );
    m.gsElement = m.getRequiredElement("GS" );
    m.windElement = m.getRequiredElement("Wind" );

    m.adfElement = m.getRequiredElement("VOR" );
    m.vorElement = m.getRequiredElement("GreenArrow" );

   m.adfElement.setVisible(0);
   m.vorElement.setVisible(0);

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

  update: func()
  {
    var v = 0;

    v = me.getNotNullValue( me.headingNode );
    me.compassRotate.setRotation( -v * D2R, me.compassElement.getCenter() );
    me.headingElement.setText( sprintf("%03d", math.round(v)) );

    me.latitudeElement.setText( me.formatDeg( 0, me.getNotNullValue( me.latitudeNode ) ) );
    me.longitudeElement.setText( me.formatDeg( 1, me.getNotNullValue( me.longitudeNode ) ) );

    v = me.getNotNullValue( me.iasNode );
    me.iasElement.setText( sprintf("%03d", v ) );

    v = me.getNotNullValue( me.gsNode );
    me.gsElement.setText( sprintf("%03d", v ) );

    me.windElement.setText( sprintf("%02d/%02d", 
      me.getNotNullValue( me.windDirNode ),
      me.getNotNullValue( me.windSpeedNode ) ));

  }

};

var ED = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: ED");
    var m = { parents: [ ED, EFISScreen.new(c) ] };
    return m;
  },

};

var PRD = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: Pre Race Display");

    var m = { parents: [ PRD, EFISScreen.new(c) ] };

    m.bg = m.g.rect( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT );
    

    m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(40, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 30)
       .setText("PRERACE DISPLAY");

    m.speedElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-center")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(400, 1.5)
       .setTranslation(SCREEN_WIDTH_2, SCREEN_HEIGHT_2)
       .setText("1");


    return m;
  },

  update: func()
  {
    var speed = int(me.gsNode.getValue());
    if( speed == nil ) speed = int(0);
    if( speed < 1 ) speed = 1;

    me.speedElement.setText(sprintf("%3d", speed));

    if( speed <= 195 ) {
      me.bg.setColorFill(0.0, 1.0, 0.0);
    } else if( speed < 201 ) {
      me.bg.setColorFill(1.0, 1.0, 0.0);
    } else {
      me.bg.setColorFill(1.0, 0.0, 0.0);
    }
  },

  getLedstripMode: func()
  {
    return 1;
  },

};

var RD = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: Race Display");

    var m = { parents: [ RD, EFISScreen.new(c) ] };

    m.bg = m.g.rect( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT );

    m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(40, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 30)
       .setText("RACE DISPLAY");


    m.gLoadElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-center")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(400, 1.5)
       .setTranslation(SCREEN_WIDTH_2, SCREEN_HEIGHT_2)
       .setText("1.0");

    m.maxElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-bottom")
       .setFont("LiberationFonts/LiberationMono-Bold.ttf")
       .setFontSize(120, 1.5)
       .setTranslation(SCREEN_WIDTH_2, SCREEN_HEIGHT-40)
       .setText("(10.1 -- 0.00s)");


    m.maxG = int(10);
    m.maxGDuration = 0.0;
    m.maxGStartTime = -1.0;

    return m;
  },

  update: func()
  {
    var accel = me.accelNode.getValue();
    if( accel == nil ) accel = 0;
    var gLoad = int( -0.310810 * accel );

    if( gLoad > me.maxG ) {
      me.maxG = gLoad;
      if( me.maxGStartTime < 0.0 ) {
        me.maxGStartTime = me.elapsedNode.getValue();
      }
    } else {
      if( me.maxGStartTime >= 0.0 ) {
        me.maxGDuration = me.elapsedNode.getValue() - me.maxGStartTime;
        me.maxGStartTime = -1.0;
      }
    }

    if( gLoad <= 95 ) {
      me.bg.setColorFill(0.0, 1.0, 0.0);
    } else if( gLoad <=10 ) {
      me.bg.setColorFill(1.0, 1.0, 0.0);
    } else {
      me.bg.setColorFill(1.0, 0.0, 0.0);
    }

    me.gLoadElement.setText( sprintf("%3.1f", gLoad/10.0) );
    me.maxElement.setText( sprintf("(%3.1f -- %3.2f)", me.maxG/10.0, me.maxGDuration ) );
  },

  getLedstripMode: func()
  {
    return 2;
  },

};

var ResultsDisplay = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: Results Display");
    var m = { parents: [ ED, EFISScreen.new(c) ] };
    return m;
  },

};

var EFIS = {

  new: func()
  {
    print("Creating Red Bull Air Race EFIS");

    var m = { parents: [EFIS] };
    
    # create a new canvas...
    m.canvas = canvas.new({
      "name": "EFIS",
      "size": [SCREEN_WIDTH, SCREEN_WIDTH],
      "view": [SCREEN_WIDTH, SCREEN_HEIGHT],
      "mipmapping": 1
    });

    m.canvas.addPlacement({"node": "Screen"});
    m.canvas.setColorBackground(0.87,1.0,0.87);

    # The screens
    m.screens = [
      PFD.new( m.canvas ),
      HSI.new( m.canvas ),
      PRD.new( m.canvas ),
      RD.new( m.canvas ),
    ];

    m.currentScreen = 0;
    m.ledStripModeNode = props.globals.getNode("/instrumentation/ledstrip/mode");

    setlistener("/instrumentation/efis/current-screen", func(n) { 
      m.changeScreen( n.getValue() ); 
    }, 1);
    
    return m;
  },

  update: func()
  {
    me.screens[me.currentScreen].update();
    settimer(func me.update(), 0);
  },

  changeScreen: func( n )
  {
    for( var i = 0; i < size(me.screens); i += 1 ) {
      me.screens[i].setEnabled( i == n );
    }

    var ledstripMode = 0;
    if( n >= 0 and n < size(me.screens) ) {
      me.currentScreen = n;
      ledstripMode = me.screens[n].getLedstripMode();
    }
    me.ledStripModeNode.setIntValue( ledstripMode );
  },
};

setlistener("/nasal/canvas/loaded", func {
  var efis = EFIS.new();
  efis.update();
}, 1);
