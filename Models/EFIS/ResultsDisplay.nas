var ResultsDisplay = {
  new: func( efis )
  {
    print(" * Results Display");
    var m = { parents: [ ResultsDisplay, EFISScreen.new(efis) ] };
    return m;
  },

};
