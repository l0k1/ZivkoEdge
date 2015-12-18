var RD = {
  new: func( efis )
  {
    print(" * Race Display");

    var m = { parents: [ RD, EFISScreen.new(efis) ] };

    m.bg = m.g.rect( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT );

    m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 30)
       .setText("RACE DISPLAY");


    m.gLoadElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-center")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(400, 1.5)
       .setTranslation(SCREEN_WIDTH_2, SCREEN_HEIGHT_2)
       .setText("1.0");

    m.maxElement = m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-bottom")
       .setFont("LiberationFonts/LiberationMono-Bold.ttf")
       .setFontSize(120, 1.5)
       .setTranslation(SCREEN_WIDTH_2, SCREEN_HEIGHT-40)
       .setText("(10.1 -- 0.00s)");


    m.maxG = int(10);
    m.maxGDuration = 0.0;
    m.maxGStartTime = -1.0;

    return m;
  },

  update: func()
  {
    var accel = me.efis.readSensor("accel");
    if( accel == nil ) accel = 0;
    var gLoad = int( -0.310810 * accel );
    var now = me.efis.readSensor("elapsedTime");

    if( gLoad > me.maxG ) {
      me.maxG = gLoad;
      if( me.maxGStartTime < 0.0 ) {
        me.maxGStartTime = now;
      }
    } else {
      if( me.maxGStartTime >= 0.0 ) {
        me.maxGDuration = now - me.maxGStartTime;
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
  },

  getLedstripMode: func()
  {
    return 2;
  },

  getName: func()
  {
    return "rd";
  },

};

append( EFISplugins, RD );
