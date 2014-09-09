############################################################
# Models a JPInstruments EDM700
# maintainer: Torsten Dreyer, torsten (at) t3r (dot) de 
############################################################

############################################################
# A Sensor class, inspired by JSBSim FGSensor
# maintainer: Torsten Dreyer, torsten (at) t3r (dot) de 
############################################################
var Sensor = {};

Sensor.new = func( sensorNode ) {
  var obj = {};
  obj.parents = [Sensor];
  obj.sensorNode = sensorNode;
  obj.inputNode = props.globals.getNode( sensorNode.getNode( "input", 1 ).getValue() );
  obj.outputNode = sensorNode.getNode( "output", 1 );
  obj.outputNode.alias( obj.inputNode );;
  return obj;
}

Sensor.getName = func {
  return me.sensorNode.getNode( "name", 1 ).getValue();
}

Sensor.getOutputValue = func {
  return me.outputNode.getValue();
}

var BarDisplay = {};

BarDisplay.new = func {
  var obj = {};
  obj.parents = [BarDisplay];

  return obj;
}

###########################################################
# a button that can have two actions:
# a short tap
# a long hold
# listens on a property and fires the action with the argument
# set to "tap" if it was just clicked shorter than the holdTime
# and "hold" if it was held for longer then holdTime
###########################################################
Button = {};

Button.new = func( property, action, holdTime = 3 ) {
  var obj = {};
  obj.parents = [Button];
  obj.propertyNode = property;
  obj.holdTime = holdTime;
  obj.TIMER = 0.2;
  obj.action = action;
  obj.pressedTime = nil;
  obj.elapsedTimeNode = props.globals.getNode( "/sim/time/elapsed-sec" );

  obj.propertyNode.setBoolValue( 0 );
  setlistener( obj.propertyNode, func { obj.listener() }, 0, 0 );
  return obj;
};

Button.listener = func {
  if( me.propertyNode.getValue() ) {
    me.pressedTime = me.elapsedTimeNode.getValue();
    settimer( func { me.timeout(); }, me.TIMER );
  }
};

Button.timeout = func {
  if( me.propertyNode.getValue() ) {
    if( me.elapsedTimeNode.getValue() - me.pressedTime > me.holdTime ) {
      me.action( me.propertyNode, "hold" );
      return;
    }
    settimer( func { me.timeout(); }, me.TIMER );
  } else {
    me.action( me.propertyNode, "tap" );
  }

};

############################################################
# A class to model a EDM700
############################################################
#
var DISPLAY_MODE_PERCENTAGE = "percentage";
var DISPLAY_MODE_NORMALIZE  = "normalize";

var MODE_AUTOMATIC = "automatic";
var MODE_MANUAL    = "manual";
var MODE_LEAN_FIND = "leanfind";

var LEAN_FIND_STATE_START = 0;
var LEAN_FIND_STATE_ACTIVE = 1;
var LEAN_FIND_STATE_LEANEST_FLASH = 2;
var LEAN_FIND_STATE_LEANEST = 3;
#
#

var EDM700 = {};

EDM700.new = func( rootNode ) {
  var obj = {};
  obj.parents = [EDM700];
  obj.rootNode = rootNode;
  obj.sensors = {};

  obj.timerNode = rootNode.initNode( "timer", 0.25 );
  obj.scanIntervalNode = rootNode.initNode( "scan-interval-sec", 4.0 );

  obj.stepButton = Button.new( rootNode.getNode( "step-button", 1 ), func { obj.step(arg); } );
  obj.lfButton = Button.new( rootNode.getNode( "lf-button", 1 ), func { obj.lf(arg); } );

  obj.DISPLAY_EGT_MAX = 1650.0;
  obj.DISPLAY_EGT_MIN = obj.DISPLAY_EGT_MAX / 2.0;
  obj.DISPLAY_EGT_DELTA = obj.DISPLAY_EGT_MAX - obj.DISPLAY_EGT_MIN;

  obj.displayModeNode = rootNode.initNode( "display-mode", DISPLAY_MODE_PERCENTAGE );

  if( obj.displayModeNode.getValue() == DISPLAY_MODE_PERCENTAGE ) {
    obj.rootNode.getNode( "display/norm", 1 ).setBoolValue( 0 );
    obj.rootNode.getNode( "display/percentage", 1 ).setBoolValue( 1 );
  } else {
    obj.rootNode.getNode( "display/norm", 1 ).setBoolValue( 1 );
    obj.rootNode.getNode( "display/percentage", 1 ).setBoolValue( 0 );
  }
  obj.displayNormBase = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];

  obj.lastCHT = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];
  obj.lastCHTRate = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];

  obj.leanFindState = LEAN_FIND_STATE_START;
  obj.leanestCylinder = -1;
  obj.leanFindStartEGT = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];
  obj.lastEGT = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];

  obj.modeNode = obj.rootNode.getNode( "mode", 1 );
  obj.modeNode.setValue( MODE_MANUAL );

  obj.modeFunctions = { 
    automatic : func { obj.automatic() },
    manual : func { obj.manual() },
    leanfind : func { obj.leanfind() } 
  };

  obj.currentColumnNode = obj.rootNode.initNode( "current-column", 0, "INT" );

  obj.barNormalNodes = [
    obj.rootNode.getNode( "display/bar-norm[0]", 1 ),
    obj.rootNode.getNode( "display/bar-norm[1]", 1 ),
    obj.rootNode.getNode( "display/bar-norm[2]", 1 ),
    obj.rootNode.getNode( "display/bar-norm[3]", 1 ),
    obj.rootNode.getNode( "display/bar-norm[4]", 1 ),
    obj.rootNode.getNode( "display/bar-norm[5]", 1 ),
    obj.rootNode.getNode( "display/bar-norm[6]", 1 )
  ];
  foreach( var n; obj.barNormalNodes )
    n.setDoubleValue( 0.0 );

  obj.barSelectNodes = [
    obj.rootNode.getNode( "display/bar-select[0]", 1 ),
    obj.rootNode.getNode( "display/bar-select[1]", 1 ),
    obj.rootNode.getNode( "display/bar-select[2]", 1 ),
    obj.rootNode.getNode( "display/bar-select[3]", 1 ),
    obj.rootNode.getNode( "display/bar-select[4]", 1 ),
    obj.rootNode.getNode( "display/bar-select[5]", 1 ),
    obj.rootNode.getNode( "display/bar-select[6]", 1 )
  ];
  foreach( var n; obj.barSelectNodes )
    n.setBoolValue( 1 );

  obj.bar0NormalNodes = [
    obj.rootNode.getNode( "display/bar0-norm[0]", 1 ),
    obj.rootNode.getNode( "display/bar0-norm[1]", 1 ),
    obj.rootNode.getNode( "display/bar0-norm[2]", 1 ),
    obj.rootNode.getNode( "display/bar0-norm[3]", 1 ),
    obj.rootNode.getNode( "display/bar0-norm[4]", 1 ),
    obj.rootNode.getNode( "display/bar0-norm[5]", 1 ),
    obj.rootNode.getNode( "display/bar0-norm[6]", 1 )
  ];
  foreach( var n; obj.bar0NormalNodes )
    n.setDoubleValue( 0.0 );

  obj.digitANodes = [
    obj.rootNode.getNode( "display/digit-a[3]", 1 ),
    obj.rootNode.getNode( "display/digit-a[2]", 1 ),
    obj.rootNode.getNode( "display/digit-a[1]", 1 ),
    obj.rootNode.getNode( "display/digit-a[0]", 1 )
  ];
  foreach( var n; obj.digitANodes )
    n.setIntValue( 0 );

  obj.digitBNodes = [
    obj.rootNode.getNode( "display/digit-b[2]", 1 ),
    obj.rootNode.getNode( "display/digit-b[1]", 1 ),
    obj.rootNode.getNode( "display/digit-b[0]", 1 )
  ];
  foreach( var n; obj.digitBNodes )
    n.setIntValue( 0 );

  obj.columnSelectorNodes = obj.rootNode.getNode( "display" ).getChildren("column-selector");
  foreach( var n; obj.columnSelectorNodes )
    n.setBoolValue( 0 );

  obj.textNodes = obj.rootNode.getNode( "display/text" ).getChildren();
  foreach( var n; obj.textNodes )
    n.setBoolValue( 0 );

  obj.elapsedTimeNode = props.globals.getNode( "/sim/time/elapsed-sec" );
  obj.lastColumnSwitch = obj.elapsedTimeNode.getValue();
  obj.lastParameterSwitch = obj.elapsedTimeNode.getValue();
  obj.lastRun = obj.elapsedTimeNode.getValue();
  obj.systemStart = obj.lastRun;
  obj.buttonTouched = 0;

  obj.displayParameters = [ "BAT", "OAT", "CRB", "DIF", "EGT", "OIL", "CLD" ];
  obj.currentDisplayParameter = 4;
  obj.displayParameterFunctions = { 
    BAT : func { 
      obj.columnSelectorNodes[ obj.currentColumnNode.getValue() ].setBoolValue( 0 );
      obj.setText( nil );
      obj.setText( "bat" );
      obj.showSensor("bat", obj.digitANodes, 1 );
    },

    OAT : func { 
      obj.columnSelectorNodes[ obj.currentColumnNode.getValue() ].setBoolValue( 0 );
      obj.setText( nil );
      obj.setText( "oat" );
      obj.showSensor("oat", obj.digitANodes, 1 );
    },

    CRB : func { 
      obj.columnSelectorNodes[ obj.currentColumnNode.getValue() ].setBoolValue( 0 );
      obj.setText( nil );
      obj.setText( "crb" );
      obj.showSensor("crb", obj.digitANodes );
    },

    DIF : func { 
      obj.columnSelectorNodes[ obj.currentColumnNode.getValue() ].setBoolValue( 0 );
      obj.setText( nil );
      obj.setText( "dif" );
      var maxEGT = 0;
      var minEGT = 1e6;
      var hottest = nil;
      var coolest = nil;
      for( var i = 0; i < 6; i+=1 ) {
        var egt = obj.sensors[ "egt" ~ i ].getOutputValue();
        if( egt > maxEGT ) {
          hottest = i;
          maxEGT = egt;
        }
        if( egt < minEGT ) {
          coolest = i;
          minEGT = egt;
        }
      }
      obj.setDigits( obj.digitANodes, maxEGT - minEGT );
    },

    EGT : func { 
      obj.setText( nil );
      var currentColumn = obj.currentColumnNode.getValue();
      if( obj.elapsedTimeNode.getValue() - obj.lastColumnSwitch > obj.scanIntervalNode.getValue() ) {
        obj.lastColumnSwitch = obj.elapsedTimeNode.getValue();
        currentColumn += 1;
        if( currentColumn >= 6 )
          currentColumn = 0;
        obj.currentColumnNode.setIntValue( currentColumn );
      }
      foreach( var columnSelectorNode; obj.columnSelectorNodes )
        columnSelectorNode.setBoolValue(  currentColumn == columnSelectorNode.getIndex() );

      obj.showSensor("egt" ~ obj.currentColumnNode.getValue(), obj.digitANodes );
      obj.showSensor("cht" ~ obj.currentColumnNode.getValue(), obj.digitBNodes );
    },

    OIL : func { 
      obj.columnSelectorNodes[ obj.currentColumnNode.getValue() ].setBoolValue( 0 );
      obj.setText( nil );
      obj.setText( "oil" );
      obj.showSensor("oil", obj.digitANodes );
    },

    CLD : func { 
      obj.columnSelectorNodes[ obj.currentColumnNode.getValue() ].setBoolValue( 0 );
      obj.setText( nil );
      obj.setText( "cld" );
      var maxRate = 0.0;
      var fastest = nil;
      for( var i = 0; i < 6; i += 1 ) {
        if( obj.lastCHTRate[i] < maxRate ) {
          maxRate = obj.lastCHTRate[i];
          fastest = i;
        }
      }

      if( maxRate < 0 )
        maxRate *= -1;

      obj.setDigits( obj.digitANodes, maxRate );
    }
  };

  foreach( var sensorNode; obj.rootNode.getChildren( "sensor" ) ) {
    var sensor = Sensor.new( sensorNode );
    obj.sensors[sensor.getName()] = sensor;
  }

  obj.Run();
  return obj;
}

EDM700.nextDisplayParameter = func( step = 1 ) {
  me.currentDisplayParameter += step;

  if( me.currentDisplayParameter >= size(me.displayParameters) )
    me.currentDisplayParameter = 0;

  if( me.currentDisplayParameter < 0 )
    me.currentDisplayParameter = size(me.displayParameters)-1;
}

EDM700.setDisplayParameter = func( name ) {
  for( var i = 0; i < size(me.displayParameters); i += 1 ) {
    if( me.displayParameters[i] == name ) {
      me.currentDisplayParameter = i;
      return;
    }
  }
}

# called when step button is pressed
EDM700.step = func(arg) {
  me.buttonTouched = 1;
  var mode = me.modeNode.getValue();
  if( arg[1] == "tap" ) {
    if( mode == MODE_MANUAL ) {
      me.nextDisplayParameter();
    } elsif ( mode == MODE_AUTOMATIC ) {
      me.modeNode.setValue( MODE_MANUAL );
    } elsif( mode == MODE_LEAN_FIND ) {
      me.modeNode.setValue( MODE_AUTOMATIC );
    } else {
      me.modeNode.setValue( MODE_MANUAL );
    }
  } elsif( arg[1] == "hold" ) {
    if( mode == MODE_MANUAL ) {
      me.nextDisplayParameter(-1);
    }
  }
}

# called when lf button is pressed
EDM700.lf = func( arg ) {
  me.buttonTouched = 1;
  var mode = me.modeNode.getValue();
  if( arg[1] == "tap" ) {
    if( mode == MODE_MANUAL ) {
      me.startLeanFind();
    } elsif( mode == MODE_AUTOMATIC ) {
      me.startLeanFind();
    } elsif( mode == MODE_LEAN_FIND ) {
    } else {
      me.modeNode.setValue( MODE_MANUAL );
    }
  } elsif( arg[1] == "hold" ) {
    if( me.displayModeNode.getValue() == DISPLAY_MODE_PERCENTAGE ) {
      me.displayModeNode.setValue( DISPLAY_MODE_NORMALIZE );
      me.rootNode.getNode( "display/norm", 1 ).setBoolValue( 1 );
      me.rootNode.getNode( "display/percentage", 1 ).setBoolValue( 0 );
    } else {
      me.displayModeNode.setValue( DISPLAY_MODE_PERCENTAGE ); 
      me.rootNode.getNode( "display/norm", 1 ).setBoolValue( 0 );
      me.rootNode.getNode( "display/percentage", 1 ).setBoolValue( 1 );
    }
  }
}

EDM700.startLeanFind = func {
  me.modeNode.setValue( MODE_LEAN_FIND );
  me.setDisplayParameter( "EGT" );
  me.leanFindState = LEAN_FIND_STATE_START;
  for( var i = 0; i < 6; i+=1 )
    me.leanFindStartEGT[i] = me.sensors[ "egt" ~ i ].getOutputValue();

  me.currentDisplayParameter = -1;
  me.setText( nil );
  me.setText( "lean" );
  me.setText( "r" );
}

EDM700.showSensor = func( sensorName, digitNodes, scale10 = 0 ) { 
  var sensor = me.sensors[ sensorName ];
  me.setDigits( digitNodes, sensor.getOutputValue(), scale10 );
}

EDM700.Run = func {
  # switch to automatic mode after two minutes if no button touched
  if( me.buttonTouched == 0 and me.elapsedTimeNode.getValue() - me.systemStart > 120 ) {
    if( me.modeNode.getValue() !=  MODE_AUTOMATIC )
      me.modeNode.setValue( MODE_AUTOMATIC );
  }

  var deltaT = me.elapsedTimeNode.getValue() - me.lastRun;

  me.modeFunctions[ me.modeNode.getValue() ]();

  if( me.currentDisplayParameter != -1 )
    me.displayParameterFunctions[ me.displayParameters[ me.currentDisplayParameter] ]();

  for( var i = 0; i < 6; i += 1 ) {

    var egt = me.sensors[ "egt" ~ i ].getOutputValue();
    var norm = 0.0;

    if( me.displayModeNode.getValue() == DISPLAY_MODE_PERCENTAGE ) {
      norm = (egt - me.DISPLAY_EGT_MIN) / me.DISPLAY_EGT_DELTA;
      me.displayNormBase[i] = egt;
    }
    # normlize values at 50 percent and 10 deg per bar
    # to +/- 80 deg
    if( me.displayModeNode.getValue() == DISPLAY_MODE_NORMALIZE ) {
      norm = (egt - me.displayNormBase[i]) / 160 + 0.5;
    }

    if( norm < 0.0 )
      norm = 0.0;
    if( norm > 1.0 )
      norm = 1.0;

    me.barNormalNodes[i].setDoubleValue( norm );

    var cht = me.sensors[ "cht" ~ i ].getOutputValue();
    norm = (cht - 250) / 400;
    if( norm < 0.0 )
      norm = 0.0;
    if( norm > 1.0 )
      norm = 1.0;
    me.bar0NormalNodes[i].setDoubleValue( norm );
  }

  for( var i = 0; i < 6; i+=1 ) {
    var cht  = me.sensors[ "cht" ~ i ].getOutputValue();
    var egt  = me.sensors[ "egt" ~ i ].getOutputValue();
    me.lastCHTRate[i] = (cht - me.lastCHT[i])*60/deltaT;
    me.lastCHT[i] = cht;
    me.lastEGT[i] = egt;
  }

  me.lastRun = me.elapsedTimeNode.getValue();

  settimer( func { me.Run() }, me.timerNode.getValue() );
}

EDM700.manual = func {

}

EDM700.automatic = func {
  if( me.elapsedTimeNode.getValue() - me.lastParameterSwitch > me.scanIntervalNode.getValue() ) {
    me.lastParameterSwitch = me.elapsedTimeNode.getValue();
    me.nextDisplayParameter();
  }
}

EDM700.leanfind = func {
  if( me.leanFindState == LEAN_FIND_STATE_START ) {
    # wait for egt to raise by 15 deg F
    for( var i = 0; i < 6; i += 1 ) {
      var egt  = me.sensors[ "egt" ~ i ].getOutputValue();
      if( egt > me.lastEGT[i] and egt - me.leanFindStartEGT[i] > 15 ) {
        me.leanFindState = LEAN_FIND_STATE_ACTIVE;
        me.setText( nil );
        me.setText( "lf" );
        return;
      }
    }
  } elsif( me.leanFindState == LEAN_FIND_STATE_ACTIVE ) {
    var maxEGT = -274.0;
    var hottestCylinder = -1;
    # wait for first egt to drop
    for( var i = 0; i < 6; i += 1 ) {
      var egt  = me.sensors[ "egt" ~ i ].getOutputValue();

      # remember hottest EGT for each cylinder
      if( egt > me.leanFindStartEGT[i] )
        me.leanFindStartEGT[i] = egt;

      # check hottest cylinder
      if( egt > maxEGT ) {
        maxEGT = egt;
        hottestCylinder = i;
      }

      # check for temperature drop 
      if( egt - me.leanFindStartEGT[i] < -5 ) {
        me.leanestCylinder = i;
        me.leanFindState = LEAN_FIND_STATE_LEANEST_FLASH;
        me.setText( nil );
        me.setText( "lean" );
        me.setText( "est" );
        me.leanestFoundTime = me.elapsedTimeNode.getValue();
        return;
      }
    }
    # show hottest EGT
    me.setDigits( me.digitANodes, maxEGT );

    # flash column dot
    me.columnSelectorNodes[hottestCylinder].setBoolValue( math.mod( me.elapsedTimeNode.getValue(), 1.0) < 0.5 );

  } elsif( me.leanFindState == LEAN_FIND_STATE_LEANEST_FLASH ) {
    var b = math.mod( me.elapsedTimeNode.getValue(), 1.0) < 0.5;
    # flash column dot
    me.columnSelectorNodes[me.leanestCylinder].setBoolValue( b );

    # flash column of leanest cylinder
    me.barSelectNodes[me.leanestCylinder].setBoolValue( b );

    if( me.elapsedTimeNode.getValue() - me.leanestFoundTime > 2.0 ) {
      me.leanFindState = LEAN_FIND_STATE_LEANEST;
      me.setText( nil );
      me.setText( "set" );
    }
  } elsif( me.leanFindState == LEAN_FIND_STATE_LEANEST ) {
    var b = math.mod( me.elapsedTimeNode.getValue(), 1.0) < 0.5;
    # flash column dot
    me.columnSelectorNodes[me.leanestCylinder].setBoolValue( b );

    # flash column of leanest cylinder
    me.barSelectNodes[me.leanestCylinder].setBoolValue( b );

    me.setDigits( me.digitANodes, me.sensors[ "egt" ~ me.leanestCylinder ].getOutputValue() );
  }
}

EDM700.setDigits = func( digitNodes, value, scale10 = 0 ) {
  divisor = 1;

  me.rootNode.getNode( "display/digit-a-dp", 1 ).setBoolValue( scale10 );
  if( scale10 )
    value *= 10.0;

  foreach( digitNode; digitNodes ) {
    digitNode.setIntValue( value / divisor );
    divisor *= 10;
  }
}

EDM700.setText = func( name ) {
  foreach( var n; me.textNodes ) {
    if( name == nil )
      n.setBoolValue( 0 );
    elsif( name == n.getName() )
      n.setBoolValue( 1 );
  }

}

############################################################

setlistener("/sim/signals/fdm-initialized", func {
  foreach( var edm700Node; props.globals.getNode( "instrumentation", 1 ).getChildren( "edm700" ) ) {
    EDM700.new( edm700Node );
  }
});
