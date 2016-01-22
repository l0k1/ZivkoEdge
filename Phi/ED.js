define([
        'knockout', 'text!Models/EFIS/ED.svg', 'sprintf', 
], function(ko, svgString, sprintf ) {

    function ViewModel(params) {
        var self = this;
        params = params||{}
        
        self.rateLimit = params.rateLimit || 100;

        self.propertyMap = {
            heading : 'heading',
        }

        this.heading = ko.observable(0).extend({
            fgprop : self.propertyMap.heading
        }).extend({rateLimit: self.rateLimit });
        
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
