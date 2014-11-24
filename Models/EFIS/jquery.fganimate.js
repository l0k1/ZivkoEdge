(function($) {
  
  function makeTranslate(a) {
    return makeTransform("translate", a);
  }

  function makeRotate(a) {
    return makeTransform("rotate", a);
  }
  
  function makeTransform( type, a ) {
    var t = type.concat("(");
    if( a != null ) {
      a.forEach( function(ele) {
        t = t.concat(ele).concat(" ");
      });
    }
    return t.concat(") ");
  }

  $.fn.fgAnimateSVG = function(props) {
    if (props) {
      if (props.type == "transform" && props.transforms) {
        var a = "";
        props.transforms.forEach(function(transform) {
          switch (transform.type) {
            case "rotate":
              a = a.concat(makeRotate([ transform.props.a, transform.props.x, transform.props.y ]));
              break;
            case "translate":
              a = a.concat(makeTranslate([ transform.props.x, transform.props.y ]));
              break;
          }
        });
        this.attr("transform", a);
      
      } else if( props.type == "text" ) {
        var tspans = this.children("tspan");
        if( 0 == tspans.length ) {
          this.text(props.text);
        } else {
          tspans.text(props.text);
        }
      }
    }
    return this;
  };

}(jQuery));