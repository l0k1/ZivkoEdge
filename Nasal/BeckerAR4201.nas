############################################################
# Models a Becker Avionics AR4201 transceiver
# maintainer: Torsten Dreyer, torsten (at) t3r (dot) de 
############################################################

var AR4201 = {};

AR4201.new = func( rootNode ) {
  var obj = {};
  obj.parents = [AR4201];
  obj.rootNode = rootNode;

  print( "creating Becker AR4201 transceiver #" ~ rootNode.getIndex() );

  obj.digitANodes = [
    obj.rootNode.getNode( "display/digit-a[0]", 1 ),
    obj.rootNode.getNode( "display/digit-a[1]", 1 ),
    obj.rootNode.getNode( "display/digit-a[2]", 1 ),
    obj.rootNode.getNode( "display/digit-a[3]", 1 ),
    obj.rootNode.getNode( "display/digit-a[4]", 1 ),
    obj.rootNode.getNode( "display/digit-a[5]", 1 )
  ];
  foreach( var n; obj.digitANodes )
    n.setIntValue( 0 );

  obj.digitBNodes = [
    obj.rootNode.getNode( "display/digit-b[0]", 1 ),
    obj.rootNode.getNode( "display/digit-b[1]", 1 ),
    obj.rootNode.getNode( "display/digit-b[2]", 1 ),
    obj.rootNode.getNode( "display/digit-b[3]", 1 ),
    obj.rootNode.getNode( "display/digit-b[4]", 1 ),
    obj.rootNode.getNode( "display/digit-b[5]", 1 ),
    obj.rootNode.getNode( "display/digit-b[6]", 1 )
  ];
  foreach( var n; obj.digitBNodes )
    n.setIntValue( 0 );

  obj.selectedFrequencyNode = rootNode.getNode("frequencies").getNode("selected-mhz");
  obj.standbyFrequencyNode = rootNode.getNode("frequencies").getNode("standby-mhz");
  obj.volumeNode = rootNode.initNode("volume", 0.0 );

  obj.powerSwitchNode = rootNode.initNode( "power-switch", 0, "BOOL" );

  obj.modeNode  = rootNode.initNode( "mode", 1, "INT" );

  setlistener( obj.selectedFrequencyNode, func { obj.frequencyListener() }, 0, 0 );
  setlistener( obj.standbyFrequencyNode, func { obj.frequencyListener() }, 1, 0 );
  setlistener( obj.volumeNode, func { obj.volumeListener() }, 1, 0 );

  return obj;
}

AR4201.frequencyListener = func {
  me.setDigits( me.digitANodes, me.selectedFrequencyNode.getValue() * 1000 );
  me.setDigits( me.digitBNodes, me.standbyFrequencyNode.getValue() * 1000 );
}

AR4201.volumeListener = func {
  me.powerSwitchNode.setBoolValue( me.volumeNode.getValue() > 0.01 );
}
 
AR4201.setDigits = func( digitNodes, value ) {
  divisor = 1;
  # hack to work around the rounding/truncating bug in the property system
  # which make 128.700 appear as 128.699
  value = (int(value*10)+1)/10;

  foreach( digitNode; digitNodes ) {
    digitNode.setIntValue( math.mod((value / divisor),10) );
    divisor *= 10;
  }
}

############################################################

setlistener("/sim/signals/fdm-initialized", func {
  foreach( var ar4201Node; props.globals.getNode( "instrumentation", 1 ).getChildren( "comm" ) ) {
    AR4201.new( ar4201Node );
  }
});
