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
io.include("Aircraft/ZivkoEdge/Models/EFIS/Animation.nas");
io.include("Aircraft/ZivkoEdge/Models/EFIS/Dialog.nas");

var SCREEN_WIDTH = 1024;
var SCREEN_HEIGHT = 768;

var SCREEN_WIDTH_2 = SCREEN_WIDTH/2;
var SCREEN_HEIGHT_2 = SCREEN_HEIGHT/2;

#
# Base "class" for all Screens
var EFISScreen = 
{
  new: func( efis ) 
  {
    var m = { parents: [EFISScreen] };
    m.g =  efis.canvas.createGroup();
    m.efis = efis;

    return m;
  },

  getLedstripMode: func()
  {
    return 0;
  },

  getName: func()
  {
    return "unnamed";
  },

  setEnabled: func(b)
  {
    me.g.setVisible(b);
  },

  animations: nil,

  update: func()
  {
    if( me.animations == nil )
      return;

    foreach( var a; me.animations ) 
      a.apply(me);
  },

  knobPositionChanged: func( n ) 
  {
  },

  knobPressed: func( b ) 
  {
    return 0; # event not consumed
  },

};

var EFISSVGScreen = 
{
  new: func( efis, svgFile ) 
  {
    var m = { parents: [EFISSVGScreen, EFISScreen.new(efis)] };

    canvas.parsesvg(m.g.createChild("group", "baseSVG"), 
       "/Aircraft/ZivkoEdge/Models/EFIS/" ~ svgFile );

    return m;
  },

};

var EFISplugins = [];

io.include("Aircraft/ZivkoEdge/Models/EFIS/PFD.nas");
io.include("Aircraft/ZivkoEdge/Models/EFIS/HSI.nas");
io.include("Aircraft/ZivkoEdge/Models/EFIS/ED.nas");
io.include("Aircraft/ZivkoEdge/Models/EFIS/PRD.nas");
io.include("Aircraft/ZivkoEdge/Models/EFIS/RD.nas");
io.include("Aircraft/ZivkoEdge/Models/EFIS/ResultsDisplay.nas");

var EFIS = {

  sensors: 
  {
    latitude: props.globals.initNode("/position/latitude-deg", 0, "DOUBLE"),
    longitude: props.globals.initNode("/position/longitude-deg", 0, "DOUBLE"),
    roll: props.globals.initNode("/orientation/roll-deg", 0, "DOUBLE"),
    pitch: props.globals.initNode("/orientation/pitch-deg", 0, "DOUBLE"),
    heading: props.globals.initNode("/orientation/heading-magnetic-deg", 0, "DOUBLE"),
    accel: props.globals.initNode("/accelerations/pilot/z-accel-fps_sec", 0, "DOUBLE"),
    kollsmann: props.globals.initNode("/instrumentation/altimeter[1]/setting-inhg", 0, "DOUBLE"),
    altitude: props.globals.initNode("/instrumentation/altimeter[1]/indicated-altitude-ft", 0, "DOUBLE"),
    ias: props.globals.initNode("/instrumentation/airspeed-indicator[1]/indicated-speed-kt", 0, "DOUBLE"),
    slipSkid: props.globals.initNode("/instrumentation/slip-skid-ball/indicated-slip-skid", 0, "DOUBLE"),
    gs: props.globals.initNode("/velocities/groundspeed-kt", 0, "DOUBLE"),
    elapsedTime: props.globals.initNode("/sim/time/elapsed-sec", 0, "DOUBLE"),
    windDir: props.globals.initNode("/environment/wind-from-heading-deg", 0, "DOUBLE"),
    windSpeed: props.globals.initNode("/environment/wind-speed-kt", 0, "DOUBLE"),
    track: props.globals.initNode("/orientation/track-magnetic-deg", 0, "DOUBLE"),
    path: props.globals.initNode("/orientation/path-deg", 0, "DOUBLE"),
    headingBug: props.globals.initNode("/instrumentation/efis/heading-bug-deg", 0, "DOUBLE"),

    RPM: props.globals.initNode("/engines/engine[0]/rpm", 0, "DOUBLE" ),
    MAP: props.globals.initNode("/engines/engine[0]/mp-inhg", 0, "DOUBLE" ),
    OP: props.globals.initNode("/engines/engine[0]/oil-pressure-psi", 0, "DOUBLE" ),
    OT: props.globals.initNode("/engines/engine[0]/oil-temperature-degf", 0, "DOUBLE" ),
    FP: props.globals.initNode("/engines/engine[0]/fuel-pressure-psi", 0, "DOUBLE" ),
    FF: props.globals.initNode("/engines/engine[0]/fuel-flow-gph", 0, "DOUBLE" ),
    CHT0: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[0]/cht-degf", 0, "DOUBLE" ),
    CHT1: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[1]/cht-degf", 0, "DOUBLE" ),
    CHT2: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[2]/cht-degf", 0, "DOUBLE" ),
    CHT3: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[3]/cht-degf", 0, "DOUBLE" ),
    CHT4: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[4]/cht-degf", 0, "DOUBLE" ),
    CHT5: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[5]/cht-degf", 0, "DOUBLE" ),
    EGT0: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[0]/egt-degf", 0, "DOUBLE" ),
    EGT1: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[1]/egt-degf", 0, "DOUBLE" ),
    EGT2: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[2]/egt-degf", 0, "DOUBLE" ),
    EGT3: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[3]/egt-degf", 0, "DOUBLE" ),
    EGT4: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[4]/egt-degf", 0, "DOUBLE" ),
    EGT5: props.globals.initNode("/fdm/jsbsim/propulsion/engine/cylinder[5]/egt-degf", 0, "DOUBLE" ),
    FQ: props.globals.initNode("/consumables/fuel/total-fuel-m3", 0, "DOUBLE" ),
  },

  readSensor: func(name)
  {
    return me.sensors[name].getValue();
  },

  writeSensor: func(name,val)
  {
    me.sensors[name].setValue(val);
  },

  new: func( root )
  {
    print("Creating Red Bull Air Race EFIS");

    var m = { parents: [EFIS] };

    m.root = props.globals.getNode(root,1);

    m.config = {
      pressureUnit: m.root.initNode("config/pressure-unit","inhg","STRING"),
    };

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
    m.screens = [];
    foreach( var p; EFISplugins )
      append( m.screens, p.new(m) );

    m.currentScreen = 0;
    m.ledStripModeNode = props.globals.getNode("/instrumentation/ledstrip/mode");
    m.screenName = props.globals.initNode("/instrumentation/efis/current-screen-name","", "STRING");

    setlistener("/instrumentation/efis/knob-pressed", func(n) { 
      m.knobPressed( n.getValue() ); 
    }, 1);

    setlistener("/instrumentation/efis/knob-position", func(n) { 
      m.knobPositionChanged( n.getValue() ); 
    }, 0);

    setlistener("/instrumentation/efis/selected-screen", func(n) { 
      m.changeScreen( n.getValue() ); 
    }, 0, 0);

    m.changeScreen(0);

    return m;
  },

  update: func()
  {
    me.screens[me.currentScreen].update();
    settimer(func me.update(), 0);
  },

  lastKnobPosition: 0,

  knobPositionChanged: func( n ) {
    var knobOffset = n - me.lastKnobPosition;
    me.lastKnobPosition = n;
    me.screens[ me.currentScreen ].knobPositionChanged( knobOffset );
  },

  knobPressed: func( b ) {
    if( me.screens[ me.currentScreen ].knobPressed( b ) )
      return; # screen has consumed the event

    if( 0 == b ) return;

    var n = me.currentScreen + 1;
    if( n >= size(me.screens) )
      n = 0;

    me.changeScreen( n );
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
      me.screenName.setValue( me.screens[n].getName() );
      setprop("/instrumentation/efis/selected-screen", n );
    } else {
      me.screenName.setValue( "" );
    }
    me.ledStripModeNode.setIntValue( ledstripMode );
  },

};

setlistener("/nasal/canvas/loaded", func {
  var efis = EFIS.new("/instrumentation/efis");
  efis.update();
}, 1);
