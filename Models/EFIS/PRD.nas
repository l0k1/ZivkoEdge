var PRD = {
  new: func( efis )
  {
    print(" * Pre Race Display");

    var m = { parents: [ PRD, EFISScreen.new(efis) ] };

    m.bg = m.g.rect( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT );
    

    m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 30)
       .setText("PRERACE DISPLAY");

    m.speedElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-center")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(400, 1.5)
       .setTranslation(SCREEN_WIDTH_2, SCREEN_HEIGHT_2)
       .setText("1");


    return m;
  },

  update: func()
  {
    var speed = int(me.efis.readSensor("gs"));
    if( speed == nil ) speed = int(0);
    if( speed < 1 ) speed = 1;

    me.speedElement.setText(sprintf("%3d", speed));

    if( speed <= 195 ) {
      me.bg.setColorFill(0.0, 1.0, 0.0);
    } else if( speed < 201 ) {
      me.bg.setColorFill(1.0, 1.0, 0.0);
    } else {
      me.bg.setColorFill(1.0, 0.0, 0.0);
    }
  },

  getLedstripMode: func()
  {
    return 1;
  },

  getName: func()
  {
    return "prd";
  },

};

append( EFISplugins, PRD );
