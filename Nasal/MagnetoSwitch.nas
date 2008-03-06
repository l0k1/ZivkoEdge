############################################################
# Keep the magneto and starter properties in sync
# maintainer: Torsten Dreyer, torsten (at) t3r (dot) de 
############################################################
var switchPositionNode = props.globals.getNode( "controls/engines/engine[0]/magneto-switch-position", 1 );
var magnetoListener = func {
  var magnetoNode = props.globals.getNode( "controls/engines/engine[0]/magnetos", 1 );
  var starter = props.globals.getNode( "controls/engines/engine[0]/starter", 1 ).getValue();

  if( starter == nil )
    starter = 0;

  if( starter != 0 )
    magnetoNode.setIntValue( 3 );
  
  switchPositionNode.setIntValue( magnetoNode.getValue() + starter );
};

setlistener("/sim/signals/fdm-initialized", func {
  setlistener("controls/engines/engine[0]/magnetos", magnetoListener, 0, 0 );
  setlistener("controls/engines/engine[0]/starter", magnetoListener, 1, 0 );
});
