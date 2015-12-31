var ResultsDisplay = {
  new: func( efis )
  {
    print(" * Results Display");
    var m = { parents: [ ResultsDisplay, EFISScreen.new(efis) ] };
    m.bg = m.g.rect( 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT );

    m.g.createChild("text", "line-title")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 0*110)
       .setText("INFO - RESULTS");

    m.g.createChild("text", "line-g")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 1*110)
       .setText("(1.0  -- 1.00s) G");

    m.g.createChild("text", "line-speed")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 2*110)
       .setText("Entry 201.75kt+1s");

    m.g.createChild("text", "line-split1")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 3*110)
       .setText("split1 0:00.000+0");

    m.g.createChild("text", "line-split2")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 4*110)
       .setText("split2 0:00.000+0");

    m.g.createChild("text", "line-split3")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 5*110)
       .setText("split1 0:00.000+0");

    m.g.createChild("text", "line-finish")
       .setDrawMode(canvas.Text.TEXT)
       .setColor(0,0,0)
       .setAlignment("center-top")
       .setFont("LiberationFonts/LiberationMono-Regular.ttf")
       .setFontSize(96, 1.0)
       .setTranslation(SCREEN_WIDTH_2, 20 + 6*110)
       .setText("FINISH 0:00.000+0");


    m.maxG = int(10);
    m.maxGDuration = 0.0;
    m.maxGStartTime = -1.0;

    return m;
  },

  getName: func()
  {
    return "result";
  },

};

append( EFISplugins, ResultsDisplay );
