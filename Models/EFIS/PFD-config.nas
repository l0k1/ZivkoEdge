var PFDconfig = {

  new: func( efis )
  {
    print(" * PFD-config");

    var m = { parents: [ PFDconfig, EFISScreen.new(efis) ] };

    var svgGroup = m.g.createChild("group", "svgfile");    
    canvas.parsesvg(svgGroup, "/Aircraft/ZivkoEdge/Models/EFIS/PFD-config.svg");

    return m;
  },

  update: func()
  {
  },

};
