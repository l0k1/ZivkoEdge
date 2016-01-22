require.config({
    baseUrl : '/aircraft-dir',
    paths : {
        jquery : '/3rdparty/jquery/jquery-1.11.2.min',
        knockout : '/3rdparty/knockout/knockout-3.2.0',
        sprintf : '/3rdparty/sprintf/sprintf.min',
        text : '/3rdparty/require/text',
        fgcommand : '/lib/fgcommand',
        props : '/lib/props2',
        knockprops : '/lib/knockprops',
    },
    waitSeconds : 30,
}); 
        
require([   
        'knockout', 'jquery', 'knockprops'
], function(ko, jquery ) {
                
    ko.utils.knockprops.setAliases({
      heading: "/orientation/heading-magnetic-deg",
      roll: "/orientation/roll-deg",
      pitch: "/orientation/pitch-deg",
      slip: "/instrumentation/slip-skid-ball/indicated-slip-skid",
      accel: "/accelerations/pilot/z-accel-fps_sec",
      kollsmann: "/instrumentation/altimeter[1]/setting-inhg",
      pressureUnit: "/instrumentation/efis/config/pressure-unit",
      altitude: "/instrumentation/altimeter[1]/indicated-altitude-ft",
      airspeed: "/instrumentation/airspeed-indicator[1]/indicated-speed-kt",
      groundspeed: "/velocities/groundspeed-kt",
      windDir: "/environment/wind-from-heading-deg",
      windSpeed: "/environment/wind-speed-kt",
      latitude: "/position/latitude-deg",
      longitude: "/position/longitude-deg",
      // keep this the last entry to make sure all other values were initialized before
      selectedScreen: "/instrumentation/efis/current-screen-name",
    });

    function ViewModel() {
      var self = this;

      self.selectedScreen = ko.observable(0);

      self.clickPFD = function() {
        self.selectedScreen(0);
      }

      self.clickHSI = function() {
        self.selectedScreen(1);
      }

      self.clickED = function() {
        self.selectedScreen(2);
      }

      self.clickPRD = function() {
        self.selectedScreen(3);
      }

      self.clickRD = function() {
        self.selectedScreen(4);
      }

    }

    ko.utils.getXMLRootElement = function(xmlString) {
      return jquery('<div>') // wrap into detached <div> to get it's innerHTML
           .append(
           jquery(xmlString) // parse the file content
           .filter(":first")[0]) // get root element
           .html();
    }

    ko.components.register('PFD', {
        require : 'Phi/PFD'
    });

    ko.components.register('HSI', {
        require : 'Phi/HSI'
    });

    ko.components.register('ED', {
        require : 'Phi/ED'
    });

    ko.components.register('PRD', {
        require : 'Phi/PRD'
    });

    ko.components.register('RD', {
        require : 'Phi/RD'
    });

    ko.components.register('LedStrip', {
        require : 'Phi/LedStrip'
    });


    ko.applyBindings(new ViewModel(), document.getElementById('wrapper'));
});
