# pylons types
# 2014 format and later
var STARTFINISH = 0;
var DOUBLE = 1;
var SINGLE = 2;

# at 20 frames per second and 200kts groundspeed, the plane will move roughly 5 meters per frame

var pylon = {
    new: func(ident, lat,lon,alt,hdg,type) {
        # nodes getting initialized to the wrong lat/lon, timer so that nodes can get initialized
        var m = {parents: [pylon]};
        #print("pylon " ~ type ~ " created");
        m.type = type;
        m.lat = lat;
        m.lon = lon;
        m.alt = (alt * FT2M) + 21; # set altitude to median crossing point
        m.hdg = hdg;
        m.coord = geo.Coord.new().set_latlon(m.lat, m.lon, m.alt);
        m._l = geo.Coord.new();
        m._r = geo.Coord.new();
        if (m.type == STARTFINISH or m.type == DOUBLE) {
            m.leftbound = geo.Coord.new().set_latlon(m.coord.lat(), m.coord.lon(), m.coord.alt()).apply_course_distance(m.hdg - 90, 8.7);
            m.rightbound = geo.Coord.new().set_latlon(m.coord.lat(), m.coord.lon(), m.coord.alt()).apply_course_distance(m.hdg + 90, 8.7);
            m.align = geo.Coord.new().set_latlon(m.coord.lat(), m.coord.lon(), m.coord.alt()).apply_course_distance(m.hdg, 100);
        } else {
            m.leftbound = geo.Coord.new().set_latlon(m.coord.lat(), m.coord.lon(), m.coord.alt()).apply_course_distance(m.hdg - 90, 3.5);
            m.rightbound = geo.Coord.new().set_latlon(m.coord.lat(), m.coord.lon(), m.coord.alt()).apply_course_distance(m.hdg + 90, 100);
            m.align = geo.Coord.new().set_latlon(m.coord.lat(), m.coord.lon(), m.coord.alt()).apply_course_distance(m.hdg, 100);
        }
        m.load_n = ident;
        #print("setting up pylon " ~ m.load_n);
        return m;
    },
    is_between_bounds: func() {
        me.planecoord = geo.aircraft_position();
        me.phead = heading_node.getValue();
        me.leftbearing = geo.normdeg180(me.phead - me.planecoord.course_to(me.leftbound));
        me.rightbearing = geo.normdeg180(me.phead - me.planecoord.course_to(me.rightbound));
        if (math.abs(me.forwardbackdist()) < 8) {
            if ((me.leftbearing > 0 and me.rightbearing < 0) or (me.leftbearing < 0 and me.rightbearing > 0)) {
                return 1;
            } elsif (!missedflag and starttime) {
                screen.log.write("Missed pylon!");
                missedflag = 1;
            } else {
                missedflag = 0;
            }
        }
        return 0;
    },
    forwardbackdist: func() {
        me.planecoord = geo.aircraft_position();
        me._a =  alt_node.getValue() * FT2M;
        me._l.set_latlon(me.leftbound.lat(), me.leftbound.lon(), me._a);
        me._r.set_latlon(me.rightbound.lat(), me.rightbound.lon(), me._a);
        return vector.Math.distance_from_point_to_line(me.planecoord,me._l,me._r);
    },
    leftrightdist: func() {
        me.planecoord = geo.aircraft_position();
        return vector.Math.distance_from_point_to_line(me.planecoord,me.coord,me.align);
    },
};

var pylons = [];
var race_wps = [];
var splits = [];

var create_track = func(arr) {
    if (size(arr) == 0) {
        print("Cannot create track with 0 pylons!");
        return;
    }
    foreach(var py; arr) {
        append(pylons,pylon.new(py[0],py[1],py[2],py[3],py[4],py[5]))
    }
}

var wp = {
    new: func(pylon) {
        #print("starting wp creation: " ~ pylon);
        var m = {parents: [wp]};
        m.passed = 0;
        m.penalty = 0;
        m.pylon = -1;
        foreach(m.p; pylons) {
            if (m.p.load_n == pylon) {
                m.pylon = m.p;
                #print("pylon set to " ~ pylon);
            }
        }
        if (m.pylon == -1) {
            print("ERROR! Waypoint not assigned to valid pylon!");
        }
        return m;
    },

    check_penalties: func() {
        me.planecoord = geo.aircraft_position();
        me.plane_altm = alt_node.getValue() * FT2M;
        if (me.plane_altm < (me.pylon.alt - 6)) {
            # too low
            screen.log.write("Too low! +2 second penalty.");
            penaltime = penaltime + 2;
        } elsif (me.plane_altm > (me.pylon.alt + 5.5)) {
            # too high
            screen.log.write("Too high! +2 second penalty.");
            penaltime = penaltime + 2;
        }
        if (me.planecoord.distance_to(me.pylon.leftbound) < 4) {
            # collision w/ left pylon or pylon
            screen.log.write("Pylon collision! +3 second penalty.");
            penaltime = penaltime + 3;
        } elsif (me.pylon.type != SINGLE and me.planecoord.distance_to(me.pylon.rightbound) < 4) {
            # collision w/ right pylon
            screen.log.write("Pylon collision! +3 second penalty.");
            penaltime = penaltime + 3;
        }
        if (me.pylon.type != SINGLE and math.abs(roll_node.getValue()) > 10) {
            # too much roll
            screen.log.write("Incorrect level flying (roll)! +2 second penalty.");
            penaltime = penaltime + 2;
        }
        if (me.pylon.type != SINGLE and math.abs(vspeed_node.getValue()) > 25) {
            # too much climb/dive
            screen.log.write("Incorrect level flying (vertical speed)! +2 second penalty.");
            penaltime = penaltime + 2;
        }
    }

};

var starttime = 0;
var penaltime = 0;
var dnf = 0;

var registered = "";

var gforce_node = props.globals.getNode("accelerations/pilot/z-accel-fps_sec");
var vspeed_node = props.globals.getNode("velocities/vertical-speed-fps");
var roll_node = props.globals.getNode("orientation/roll-deg");
var alt_node = props.globals.getNode("position/altitude-ft");
var heading_node = props.globals.getNode("orientation/heading-deg");
var gs_node = props.globals.getNode("velocities/groundspeed-kt");
var smoke_node = props.globals.getNode("sim/multiplay/generic/int[0]");
var screen_node = props.globals.getNode("/instrumentation/efis/current-screen-name");
var g = 0;
var gflag_11 = 0;
var gflag_12 = 0;
var smokeflag = 0;
var missedflag = 0;
var ftime = 0;
var _m = 0;
var _s = 0;
var _gs = 0;

var raceloop = func() {
    for (i = 0; i < size(race_wps); i = i + 1) {
        if (!race_wps[i].passed) {
            break;
        }
    }

    # check g force
    if (starttime) {
        g = gforce_node.getValue() * -0.0310810;
        if (g < 11) {
            gflag_11 = 0;
            gflag_12 = 0;
        } elsif (g >= 11 and g < 12) {
            if (!gflag_11) {
                screen.log.write("Over G! +1 second penalty.");
                penaltime = penaltime + 1;
                gflag_11 = 1;
            }
        } elsif (g > 12) {
            if (!gflag_12) {
                screen.log.write("Over max G! DNF!");
                dnf = 1;
                gflag_12 = 1;
            }
        }

        # check smoke
        if (!smokeflag) {
            if (!smoke_node.getValue()) {
                smokeflag = 1;
                screen.log.write("Insufficient smoke! +1 second penalty.");
                penaltime = penaltime + 1;
            }
        }
    }

    if (i == 0) {
        if (race_wps[i].pylon.is_between_bounds()) {
            race_wps[i].check_penalties();
            starttime = systime();
            screen.log.write("Race started!");
            race_wps[i].passed = 1;
            _gs = gs_node.getValue();
            if (screen_node.getValue() == "prd") {
                Edge540.efis.knobPressed(1);
            }
            if (_gs > 202) {
                screen.log.write("Maximum start speed exceeded! DNF!");
                dnf = 1;
            } elsif (_gs > 200) {
                screen.log.write("Start speed exceeds 200kts! +1 second penalty.");
                penaltime = penaltime + 1;
            }
            foreach(var s; Edge540.efis.screens) {
                if (s.getName() == "result") {
                    s.entryinfo.setText(sprintf("Entry %3.2fkt +%is",_gs,penaltime));
                }
            }
        }
    } elsif ( i == (size(race_wps) - 1) ) {
        if (race_wps[i].pylon.is_between_bounds()) {
            race_wps[i].check_penalties();
            ftime = (systime() - starttime + penaltime);
            screen.log.write("Race over!");
            screen.log.write(sprintf("Your time was: %3.2f", ftime));
            if (penaltime > 0) {
                screen.log.write("You had " ~ int(penaltime) ~ " seconds of penalty time.");
            }
            if (screen_node.getValue() == "rd") {
                Edge540.efis.knobPressed(1);
            }
            foreach(var s; Edge540.efis.screens) {
                if (s.getName() == "result") {
                    s.finishtime.setText("FINISH " ~ format_time_text(ftime));
                }
            }
            print("racetime: " ~ ftime);
            penaltime = 0;
            gflag_11 = 0;
            gflag_12 = 0;
            smokeflag = 0;
            starttime = 0;
            foreach (var w; race_wps) {
                w.passed = 0;
            }
        }
    } elsif (race_wps[i].pylon.is_between_bounds()) {
        race_wps[i].passed = 1;
        race_wps[i].check_penalties();
        ftime = systime() - starttime;
        if (i == splits[0]) {
            foreach(var s; Edge540.efis.screens) {
                if (s.getName() == "result") {
                    s.split1.setText("split1 " ~ format_time_text(ftime));
                }
            }
        } elsif (i == splits[1]) {
            foreach(var s; Edge540.efis.screens) {
                if (s.getName() == "result") {
                    s.split2.setText("split2 " ~ format_time_text(ftime));
                }
            }
        } elsif (i == splits[2]) {
            foreach(var s; Edge540.efis.screens) {
                if (s.getName() == "result") {
                    s.split3.setText("split3 " ~ format_time_text(ftime));
                }
            }
        }
        #screen.log.write("Pylon passed!");
    }
}

var format_time_text = func(time) {
        _m = int(ftime/60);
        _s = math.mod(ftime, 60);
        if (_s < 10) {
            return _m~":0"~sprintf("%2.3f",_s);
        } else {
            return _m~":0"~sprintf("%2.3f",_s);
        }
}

var find_next_pos = func() {
    var nextpos = -1;
    foreach(var w; race_wps) {
        if (!w.passed and w.position < nextpos) {
            nextpos = w.position;
        }
    }
}


var t_main = maketimer(0.0, func() {raceloop();});
