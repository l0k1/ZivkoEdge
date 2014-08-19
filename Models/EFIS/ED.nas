var ED = {
  new: func( efis )
  {
    print(" * Engine Display");
    var m = { parents: [ ED, EFISScreen.new(efis) ] };
    return m;
  },

};
