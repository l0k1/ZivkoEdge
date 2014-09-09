var Dialog = 
{
  new: func( props )
  {
    var m = { parents: [ Dialog ] };

    m.overlay = props.parent.createChild("group","overlaySVG");
    canvas.parsesvg(m.overlay, props.svg);

    m.size = size(props.labels);
    m.animations = [];

    for( var i = 0; i < m.size; i += 1 ) {
      m.overlay.getElementById( "Text" ~ i ).setText( props.labels[i] );

      var a = SelectAnimation.new( m.overlay, "Selector" ~ i, func(o) {
          return o.focus == me.focus;
        });

      a.focus = i;
      append( m.animations, a );
    }
    for( var i = m.size; i < 4; i += 1 ) {
      m.overlay.getElementById( "Item" ~ i ).setVisible( 0 );
    }

    return m;
  },

  init: func()
  {
    me.focus = 0;
    me.applyAnimations();
  },

  applyAnimations: func()
  {
    foreach( var a; me.animations ) 
      a.apply(me);
  },

  focus: 0,

  knobPositionChanged: func( n ) 
  {
    me.focus += n;
    if( me.focus >= me.size )
      me.focus = 0;
    if( me.focus < 0 )
      me.focus = me.size-1;
    me.applyAnimations();
  },

  knobPressed: func( b ) 
  {
    return me.focus;
  },

};


