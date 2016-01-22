define([
        'knockout', 'text!Models/EFIS/HSI.svg', 'sprintf', 'jquery'
], function(ko, svgString, sprintf, jquery) {

    function ViewModel(params, componentInfo) {

        var self = this;
        params = params || {}

        propertyMap = {
            heading : 'heading',
            groundspeed : 'groundspeed',
            airspeed : 'airspeed',
            windDir: 'windDir',
            windSpeed: 'windSpeed',
            latitude: 'latitude',
            longitude: 'longitude',
        }

        for ( var k in propertyMap) {
            self[k] = ko.observable(0).extend({
                fgprop : propertyMap[k]
            }).extend({
                rateLimit : params.rateLimit || 100
            });
        }

        this.compassAnimation = ko.pureComputed(function() {
            return "rotate(" + (-self.heading()) + " 540 385)";
        });

        this.headingTextAnimation = ko.pureComputed(function() {
            return sprintf.sprintf("%03d", Math.round(self.heading()));
        });

        this.latitudeText = ko.pureComputed(function() {
            return self.formatDeg( false, self.latitude() );
        });

        this.longitudeText = ko.pureComputed(function() {
            return self.formatDeg( true, self.longitude() );
        });

        this.iasText = ko.pureComputed(function() {
            return sprintf.sprintf("%3d", Math.round(self.airspeed()));
        });

        this.windText = ko.pureComputed(function() {
            return sprintf.sprintf("%3d/%02d", Math.round(self.windDir()), self.windSpeed());
        });

        this.gsText = ko.pureComputed(function() {
            return sprintf.sprintf("%3d", Math.round(self.groundspeed()));
        });

        this.adfVisible = ko.pureComputed(function() {
            return false;
        });

        this.vorVisible = ko.pureComputed(function() {
            return false;
        });

        this.vorLine1 = ko.pureComputed(function() {
            return "";
        });
        this.vorLine2 = ko.pureComputed(function() {
            return "";
        });
        this.vorLine3 = ko.pureComputed(function() {
            return "";
        });
        this.vorLine4 = ko.pureComputed(function() {
            return "";
        });
        this.vorLine5 = ko.pureComputed(function() {
            return "";
        });
        this.adfLine1 = ko.pureComputed(function() {
            return "";
        });
        this.adfLine2 = ko.pureComputed(function() {
            return "";
        });
        this.adfLine3 = ko.pureComputed(function() {
            return "";
        });
        this.adfLine4 = ko.pureComputed(function() {
            return "";
        });
        this.adfLine5 = ko.pureComputed(function() {
            return "";
        });
    }
    
    ViewModel.prototype.formatDeg = function(isLongitude, v ) {
        var NSEW = [ [ "N", "S" ], [ "E", "W" ] ];
        var format = [ "%s %02d_%04.2f", "%s %03d_%04.2f" ];

        var idx1 = isLongitude ? 1 : 0;
        var idx2 = 0;
        if( v < 0 ) {
          idx2 = 1;
          v = -v;
        }
        var deg = Math.floor(v);
        var min = (v - deg) * 60;
        return sprintf.sprintf( format[idx1], NSEW[idx1][idx2], deg, min );
    }

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new ViewModel(params, componentInfo);
            },
        },
        template : ko.utils.getXMLRootElement(svgString)
    };
});
