var l = setlistener("/sim/signals/fdm-initialized", func {
  removelistener( l );

  var a = airportinfo("KHAF");
  if( a == nil ) {
    print("OUPS");
    return;
  }

  var lat = a.lat;
  var lon = a.lon;

  print(lat, " *** ", lon );

  geo._put_model( "Aircraft/ZivkoEdge540/Aerobatic/box.xml", lat, lon, nil );
});
