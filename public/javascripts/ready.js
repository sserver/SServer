var ss = ss || [];

// Simulates document ready event (like jquery). Makes asyncronous stuff nicer by having
// a simple ready event that waits until something is loaded, or if called after load just
// passes through and executes the function.
//
// You can see an example of this in intx.facebook 
ss.ready = {
 "extend" : function(object) {
    object.readyLoaded = false;
    object.readyQueue = [];
    
    object.ssloaded = function() {
      object.readyLoaded = true;
      while(object.readyQueue.length > 0) {
        var func = object.readyQueue.shift();
        func.call(object);       
      };
    };
    
    object.ready = function(func) {
      if (!object.readyLoaded) {
        object.readyQueue.push(func);
      }else {
        setTimeout(function() {
          func.call(object);
        }, 0);
      }
    };
 }
};
