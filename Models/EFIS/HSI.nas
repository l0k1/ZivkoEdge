var HSI = {
  new: func( efis )
  {
    print(" * HSI");
    var m = { parents: [ HSI, EFISScreen.new(efis) ] };

    var svgGroup = m.g.createChild("group", "svgfile");    
    canvas.parsesvg(svgGroup, "/Aircraft/ZivkoEdge/Models/EFIS/HSI.svg");

    m.g.getElementById( "HeadingBug" ).setCenter( m.g.getElementById("Compass").getCenter() );

    m.animations = [
      RotateAnimation.new( m.g, "Compass", func(o,e) {
        var c = e.getCenter();
        return { 
          angle: -o.efis.readSensor("heading")*D2R,
          cy: c[1],
          cx: c[0],
        };
      }),

      RotateAnimation.new( m.g, "HeadingBug", func(o,e) {
        var c = e.getCenter();
        return { 
          angle: o.efis.readSensor("headingBug")*D2R,
          cy: c[1],
          cx: c[0],
        };
      }),

      TextAnimation.new( m.g, "Heading", func(o) {
        return sprintf("%03d", math.round(o.efis.readSensor("heading")));
      }),

      TextAnimation.new( m.g, "Latitude", func(o) {
        return o.formatDeg( 0, o.efis.readSensor("latitude"));
      }),

      TextAnimation.new( m.g, "Longitude", func(o) {
        return o.formatDeg( 0, o.efis.readSensor("longitude"));
      }),

      TextAnimation.new( m.g, "IAS", func(o) {
        return sprintf("%03d", o.efis.readSensor("ias"));
      }),

      TextAnimation.new( m.g, "GS", func(o) {
        return sprintf("%03d", o.efis.readSensor("gs"));
      }),

      TextAnimation.new( m.g, "Wind", func(o) {
        return sprintf("%02d/%02d", 
          o.efis.readSensor("windDir"),
          o.efis.readSensor("windSpeed") );
      }),

      SelectAnimation.new( m.g, "VOR", func(o) {
        return 0;
      }),

      SelectAnimation.new( m.g, "GreenArrow", func(o) {
        return 0;
      }),
    ];

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

};

append( EFISplugins, HSI );
