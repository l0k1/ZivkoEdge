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

var EFISScreen = {
  new: func( c ) 
  {
    var m = { parents: [EFISScreen] };
    m.g =  c.createGroup();

    return m;
  },

  setEnabled: func(b)
  {
    me.g.setVisible(b);
  },

  update: func()
  {
  },
};

var PFD = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: PFD");

    var p = EFISScreen.new(c);
    var m = { parents: [ PFD, EFISScreen.new(c) ] };

    return m;
  },

};

var HSI = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: HSI");
    var m = { parents: [ HSI, EFISScreen.new(c) ] };


    return m;
  },

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

    m.bg = m.g.rect( 0, 0, 1024, 1024 );
    

    m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
       .setColor(0,0,0)
       .setColorFill(0,0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(120, 2.0)
       .setTranslation(512, 40)
       .setText("PRERACE DISPLAY");

    m.speedElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
       .setColor(0,0,0)
       .setColorFill(0,0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(500, 1.5)
       .setTranslation(512, 300)
       .setText("1");

    m.gsNode = props.globals.getNode("/velocities/groundspeed-kt");

    return m;
  },

  update: func()
  {
    var speed = int(me.gsNode.getValue());
    if( speed == nil ) speed = int(0);

    me.speedElement.setText(sprintf("%3d", speed));

    if( speed <= 195 ) {
      me.bg.setColorFill(0.0, 1.0, 0.0);
    } else if( speed < 201 ) {
      me.bg.setColorFill(1.0, 1.0, 0.0);
    } else {
      me.bg.setColorFill(1.0, 0.0, 0.0);
    }
  },

};

var RD = {
  new: func( c )
  {
    print("Creating Red Bull Air Race EFIS: Race Display");

    var m = { parents: [ RD, EFISScreen.new(c) ] };

    m.bg = m.g.rect( 0, 0, 1024, 1024 );

    m.gLoadElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
       .setColor(0,0,0)
       .setColorFill(0,0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(512, 1.5)
       .setTranslation(512, 250)
       .setText("1.0");

    m.maxElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT + canvas.Text.FILLEDBOUNDINGBOX)
       .setColor(0,0,0)
       .setColorFill(0,0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Bold.ttf")
       .setFontSize(120, 1.5)
       .setTranslation(512, 850)
       .setText("(10.1 -- 0.00s)");

    m.accelNode = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec");
    m.elapsedNode = props.globals.getNode("/sim/time/elapsed-sec");

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
  }

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
      "size": [1024, 1024],
      "view": [1024, 1024],
      "mipmapping": 1
    });

    m.canvas.addPlacement({"node": "Screen"});
    m.canvas.setColorBackground(0.87,1.0,0.87);

    # The screens
    m.screens = [
      PRD.new( m.canvas ),
      RD.new( m.canvas ),
    ];

    setlistener("/instrumentation/efis/current-screen", func(n) { 
      m.changeScreen( n.getValue() ); 
    }, 1);
    
    m.currentScreen = 0;

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

    if( n >= 0 and n < size(me.screens) ) {
      me.currentScreen = n;
    }
  },
};

setlistener("/nasal/canvas/loaded", func {
  var efis = EFIS.new();
  efis.update();
}, 1);
