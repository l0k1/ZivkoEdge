############################################################
# Some basic functionality for the Edge
# maintainer: Torsten Dreyer, torsten (at) t3r (dot) de 
############################################################
var propify = debug.propify;

if( getprop("/sim/presets/onground") == 0 ) {
  print("starting in air");
  setprop("/sim/presets/running",1);
  setprop("/controls/engines/engine[0]/magnetos", 3 );
#  setprop("/controls/engines/engine[0]/throttle", 0.75 );
  setprop("/controls/engines/engine[0]/propeller-pitch", 0.7 );
  setprop("/controls/gear/brake-parking", 0 );
}

var Logic = {};

Logic.new = func {
  var obj = {};
  obj.parents = [ Logic ];
  return obj;
}

var AND = {};

AND.new = func( out, in ) {
  var obj = Logic.new();
  obj.parents = [ Logic, AND ];
  obj.out = propify( out, 1 );
  obj.in = in;
  for( var i = 0; i < size(in); i += 1 ) {
    in[i] = propify( in[i], 1 );
    if( in[i].getValue() == nil )
      in[i].setBoolValue( 0 );
  }

  return obj;
}

AND.Run = func {
  var out = 1;
  foreach( var input; me.in ) {
    if( input.getValue() == 0 ) {
      out = 0;
      break;
    }
  }
  me.out.setBoolValue( out );
}

var NOT = {};

NOT.new = func( out, in ) {
  var obj = Logic.new();
  obj.parents = [ Logic, NOT ];
  obj.out = propify( out, 1 );
  obj.in = propify( in, 1 );
  return obj;
}

NOT.Run = func {
  me.out.setBoolValue( me.in.getValue() == 0 );
}


var logics = [];

var update = func {
  foreach( var logic; logics )
    logic.Run();

  settimer( update, 0.05 );
}

setlistener("sim/signals/fdm-initialized", func {
  var batterySwitchNode = props.globals.initNode( "controls/electric/battery-switch", 0, "BOOL" );
  append( logics, AND.new( "controls/electric/avi-power", [ batterySwitchNode, "controls/electric/circuitbreaker[0]" ] ) );
  append( logics, AND.new( "controls/electric/fuel-pump-power", [ batterySwitchNode, "controls/electric/circuitbreaker[1]" ] ) );
  append( logics, AND.new( "controls/electric/trim-power", [ batterySwitchNode, "controls/electric/circuitbreaker[2]" ] ) );
  append( logics, AND.new( "controls/electric/gauge-power", [ batterySwitchNode, "controls/electric/circuitbreaker[3]" ] ) );
  append( logics, AND.new( "controls/electric/smoke-power", [ batterySwitchNode, "controls/electric/circuitbreaker[4]" ] ) );
  append( logics, AND.new( "controls/electric/pedals-power", [ batterySwitchNode, "controls/electric/circuitbreaker[5]" ] ) );

  append( logics, AND.new( "instrumentation/comm[0]/power", [ "controls/electric/avi-power", "instrumentation/comm[0]/power-switch" ] ) );
  append( logics, AND.new( "instrumentation/comm[1]/power", [ "controls/electric/avi-power", "instrumentation/comm[1]/power-switch" ] ) );

  append( logics, AND.new( "instrumentation/edm700/power", [ "controls/electric/gauge-power" ] ) );
  append( logics, AND.new( "instrumentation/fuel-indicator/power", [ "controls/electric/gauge-power" ] ) );

  append( logics, AND.new( "controls/electric/smoke-pump", [ "controls/electric/smoke-power", "controls/electric/smoke-switch" ] ) );

  props.globals.getNode( "controls/electric/smoke-pump" ).alias( "/sim/multiplay/generic/int[0]" );

  aircraft.livery.init("Aircraft/ZivkoEdge/Models/Liveries");

  update();
});

##############################
# some life for the pilot
##############################
var PilotsLife = {};

PilotsLife.new = func {
  var obj = {};
  obj.parents = [ PilotsLife ];

  obj.look = 0;
  aircraft.light.new( "sim/model/look-timer", [ 1, 4 ] ).switch(1);
  obj.lookLeft = aircraft.door.new( "sim/model/pilot-view-heading", 0.5 );
  setlistener( "sim/model/look-timer/state", func(n) { obj.lookTimerHandler(n) }, 0, 0 );
  return obj;
}

PilotsLife.lookTimerHandler = func(n) {
  var v = n.getValue();
  if( v != 0 ) {
    me.lookLeft.open();
  } else {
    me.lookLeft.close();
  }
}

PilotsLife.new();

##############################
# let the magneto switch also fire starter
##############################
controls.stepMagnetos = func(change) {
    foreach(var e; controls.engines) {
        if(e.selected.getValue()) {
            var starter = 0;
            if (change) {
                var mag = e.controls.getNode("magnetos", 1);
                var setting = mag.getValue() + change;
                if(setting > 3){
                   starter = 1;
                   setting = 3;
                }
                mag.setIntValue(setting);
            }
            setprop("controls/engines/engine/starter", starter);
            controls.startEngine(starter);
        }
    }
} 
