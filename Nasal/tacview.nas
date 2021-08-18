# ID Scheme
# currently using ints, but it accepts hex
# 999 - my plane
# 998 - dead reckoner
# 1000 - 11000 - other planes
# 11000 - 21000 - missiles
# 21000 - 41000 - explosions

var main_update_rate = 0.1;
var write_rate = 10;

var outstr = "";
var GAL2LT = 3.78541;
var timestamp = "";
var output_file = "";
var f = "";
var starttime = 0;
var writetime = 0;

var colors = ["Red","Orange","Green","Blue","Violet"];

var tacobj = {
    tacviewID: 0,
    lat: 0,
    lon: 0,
    alt: 0,
    roll: 0,
    pitch: 0,
    heading: 0,
    speed: -1,
    valid: 0,
};

var myplaneID = 0;

var lat = 0;
var lon = 0;
var alt = 0;
var roll = 0;
var pitch = 0;
var heading = 0;
var speed = 0;

var stop_on_prop = 0;

var startwrite = func() {

    myplaneID = 1000+(math.floor(rand() * 100002));
    timestamp = getprop("/sim/time/utc/year") ~ "-" ~ getprop("/sim/time/utc/month") ~ "-" ~ getprop("/sim/time/utc/day") ~ "T";
    timestamp = timestamp ~ getprop("/sim/time/utc/hour") ~ ":" ~ getprop("/sim/time/utc/minute") ~ ":" ~ getprop("/sim/time/utc/second") ~ "Z";
    filetimestamp = string.replace(timestamp,":","-");
    output_file = getprop("/sim/fg-home") ~ "/Export/tacview-" ~ filetimestamp ~ ".acmi";
    # create the file
    f = io.open(output_file, "w+");
    io.close(f);
    
    write("FileType=text/acmi/tacview\nFileVersion=2.1\n");
    write("0,ReferenceTime=" ~ timestamp ~ "\n#0\n");
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ ",Name=ZivkoEdge540,CallSign="~getprop("/sim/multiplay/callsign")~"\n"); #
    

    foreach(var mp; props.globals.getNode("/ai/models").getChildren("static")){
        if (mp.getNode("valid").getValue() == 1) {
            model = split(".", split("/", mp.getNode('sim/model/path').getValue())[-1])[0];
            if (model == "pylon-single") {
                model = "Single Pylon";
                hdg_offset = -90;
            } else {
                model = "Double Pylon";
                hdg_offset = 0;
            }
            tcv_id = 1000-mp.getNode("id").getValue();
            clr = colors[math.floor(rand() * size(colors))];
            write(tcv_id ~ ",Name="~model~",Callsign="~",Type=Ground+Static+Building,Color="~clr~",T=");

            write(mp.getNode("position/longitude-deg").getValue()~"|"~
                    mp.getNode("position/latitude-deg").getValue()~"|"~
                    mp.getNode("position/altitude-ft").getValue() * FT2M~"|0|0|"~
                    (mp.getNode("orientation/true-heading-deg").getValue() + hdg_offset) ~ "\n");

        }
    }

    starttime = systime();
    settimer(func(){mainloop();}, main_update_rate);
}

var stopwrite = func() {
    write("-"~myplaneID);
    writetofile();
    starttime = 0;
}

var mainloop = func() {
    if (!starttime) {
        return;
    }
    settimer(func(){mainloop();}, main_update_rate);
    if (systime() - writetime > write_rate) {
        writetofile();
    }
    
    write("#" ~ (systime() - starttime)~"\n");
    
    writeMyPlanePos();
    writeMyPlaneAttributes();


}

var writeMyPlanePos = func() {
    
    write(myplaneID ~ ",T=" ~ getLon() ~ "|" ~ getLat() ~ "|" ~ getAlt() ~ "|" ~ getRoll() ~ "|" ~ getPitch() ~ "|" ~ getHeading() ~ "\n");
    
}

var writeMyPlaneAttributes = func() {
    
    write(myplaneID ~ ",TAS="~getTas()~",MACH="~getMach()~",AOA="~getAoA()~",HDG="~getHeading()~",Throttle="~getThrottle());
    write(",FuelWeight="~getTotalFuelWeight());
    write(",IAS="~getIAS()~"\n");
    
}

var write = func(str) {
    outstr = outstr ~ str;
}

var external_write = func(str) {
    write("#" ~ (systime() - starttime)~"\n");
    write("0,Event=Message|"~myplaneID~"|"~str~"\n");
}

var writetofile = func() {
    if (outstr == "") {
        return;
    }
    writetime = systime();
    f = io.open(output_file, "a+");
    io.write(f, outstr);
    io.close(f);
    outstr = "";
}

var getLat = func() {
    return getprop("/position/latitude-deg");
}

var getLon = func() {
    return getprop("/position/longitude-deg");
}

var getAlt = func() {
    return rounder(getprop("/position/altitude-ft") * FT2M,0.01);
}

var getRoll = func() {
    return rounder(getprop("/orientation/roll-deg"),0.01);
}

var getPitch = func() {
    return rounder(getprop("/orientation/pitch-deg"),0.01);
}

var getHeading = func() {
    return rounder(getprop("/orientation/heading-deg"),0.01);
}

var getTas = func() {
    return rounder(getprop("/fdm/jsbsim/velocities/vtrue-kts") * KT2MPS,1.0);
}

var getMach = func() {
    return rounder(getprop("/velocities/mach"),0.001);
}

var getAoA = func() {
    return rounder(getprop("/orientation/alpha-deg"),0.01);
}

var getThrottle = func() {
    return rounder(getprop("/fdm/jsbsim/fcs/throttle-cmd-norm"),0.01);
}

var getTotalFuelWeight = func() {
    return getprop("/consumables/fuel/total-fuel-kg");
}

var getIAS = func() {
    #should be IAS in knots
    return getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") * KT2MPS;
}

var start = func() {
    if (starttime) {
        return;
    }
    startwrite();
}

var stop = func() {
    write("//  "~md5(io.readfile(getprop("/sim/aircraft-dir")~"/ZivkoEdge540-jsbsim.xml")));
    stopwrite();
}

var rounder = func(x, p) {
    v = math.mod(x, p);
    if ( v <= (p * 0.5) ) {
        x = x - v;
    } else {
        x = (x + p) - v;
    }
}

var find_in_array = func(arr,val) {
    forindex(var i; arr) {
        if ( arr[i] == val ) {
            return i;
        }
    }
    return -1;
}

setlistener("/sim/multiplay/chat-history", func(p) {
    if (!starttime) {
        return;
    }
    var hist_vector = split("\n",p.getValue());
    if (size(hist_vector) > 0) {
        var last = hist_vector[size(hist_vector)-1];
        
        write("#" ~ (systime() - tacview.starttime)~"\n");
        write("0,Event=Message|Chat ["~hist_vector[size(hist_vector)-1]~"]\n");
        
    }
},0,0);

############### MIG21 SPECIFIC ##################

setlistener("/fdm/jsbsim/electric/output/recorder", func(p) {
    if (p.getValue() > 105) {
        startwrite(1);
    } elsif (stop_on_prop == 1) {
        stopwrite();
    }
},0,0);


setlistener("/sim/signals/exit", func(p) {
    if (!starttime) {
        return;
    }
    write("-"~myplaneID);
},0,0);
