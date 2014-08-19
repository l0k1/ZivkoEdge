var Animation = {
  new: func(e,id,f) 
  {
    var m = { parents: [Animation] };

    m.f = f;
    m.element = e.getElementById(id);
    if( m.element == nil ) die(sprintf("missing mandatory element '%s'.",  id) );
    return m;
  },

  apply: func(o)
  {
  },
};

var SelectAnimation = {
  new: func(e,id,f)
  {
    var m = { parents: [ SelectAnimation, Animation.new(e,id,f) ] };
    return m;
  },

  apply: func(o)
  {
    var b = me.f(o, me.element);
    me.element.setVisible(b);
  },
};

var TransformAnimation = {
  new: func(e,id,f)
  {
    var m = { parents: [ TransformAnimation, Animation.new(e,id,f) ] };
    m.transform = m.element.createTransform();
    return m;
  },
};

var TranslateAnimation = {
  new: func(e,id,f)
  {
    var m = { parents: [ TranslateAnimation, TransformAnimation.new(e,id,f) ] };
    return m;
  },

  apply: func(o)
  {
    var t = me.f(o, me.element);
    me.transform.setTranslation( t.x, t.y );
  },
};

var RotateAnimation = {
  new: func(e,id,f)
  {
    var m = { parents: [ RotateAnimation, TransformAnimation.new(e,id,f) ] };
    return m;
  },

  apply: func(o)
  {
    var t = me.f(o,me.element);
    me.transform.setRotation( t.angle, t.cx, t.cy );
  },
};

var TextAnimation = {
  new: func(e,id,f)
  {
    var m = { parents: [ TextAnimation, Animation.new(e,id,f) ] };
    return m;
  },

  apply: func(o)
  {
    var t = me.f(o,me.element);
    me.element.setText( t );
  },
};


