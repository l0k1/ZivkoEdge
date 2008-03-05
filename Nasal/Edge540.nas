############################################################
# Some basic functionality for the Edge
# maintainer: Torsten Dreyer, torsten (at) t3r (dot) de 
############################################################
var propify = debug.propify;

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
  var batterySwitchNode = props.globals.getNode( "controls/electric/battery-switch", 1 );
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

  update();
});

