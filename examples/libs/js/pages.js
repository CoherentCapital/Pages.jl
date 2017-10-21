"use strict";

var Pages = (function () {

    var location = window.location,
        route = location.pathname,
        href = location.href;
    var sock = new WebSocket(href.replace("http","ws"));
    sock.onmessage = function( message ){
        var msg = JSON.parse(message.data);
        var type = msg.type,
            data = msg.data;
        switch(type) {
            case "script":
                eval(data);
                break
            case "say":
                console.log(data);
                break
        }
    }

    function callback(name,args) {
        sock.send(JSON.stringify({"name":name,"route":route,"args":args}))
    }
    function notify(name) {
        callback("notify",name);
    }
    function message(id,name,args) {
        callback("message",[id,name,args]);
    }
    function broadcast(name,args) {
        callback("broadcast",[name,args]);
    }

    sock.onopen = function () {
        callback("connected");
    };

    window.onbeforeunload = function () {
        callback("unloaded",route);
    };

    var addget = function (c, name) {
		Object.defineProperty(c, name, {
			get: function () { return eval(name); },
			enumerable: true,
			configurable: true
		});
		return c;
	};

    var c = {};
    c = addget(c, "sock");
    c = addget(c, "notify");
    c = addget(c, "message");
    c = addget(c, "broadcast");
    c = addget(c, "callback");
	return c;
})();
