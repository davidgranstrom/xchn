XchnXYPad : XchnNetwork {
    var <>listenAddress, <>sendAddress, <>controlSpec;
    var inputValues;

    *new {|listenAddress, sendAddress, controlSpec|
        ^super.newCopyArgs(listenAddress, sendAddress, controlSpec).init;
    }

    init {
        inputValues = ();
        this.setupController();

        // listen for remote osc
        OSCdef(listenAddress, {|msg|
            var x = msg[1];
            var y = msg[2];
            this.remoteValue = (x: x, y: y);
        }, listenAddress);

        // set default value
        this.value = (
            x: controlSpec.default,
            y: controlSpec.default
        );
    }

    setupController {
        var controller = SimpleController(inputValues);

        // listen for changes from "outside"
        controller.put(\value, {|obj, what, args|
            var x = obj.x;
            var y = obj.y;

            sendAddress.x.do {|addr|
                this.sendToLocal(addr, controlSpec.map(x));
            };

            sendAddress.y.do {|addr|
                this.sendToLocal(addr, controlSpec.map(y));
            };

            this.sendToRemote(listenAddress, x, y);
        });

        // listen to changes from remote
        controller.put(\remoteValue, {|obj, what, args|
            var x = obj.x;
            var y = obj.y;

            sendAddress.x.do {|addr|
                this.sendToLocal(addr, controlSpec.map(x));
            };

            sendAddress.y.do {|addr|
                this.sendToLocal(addr, controlSpec.map(y));
            };
        });
    }

    value_ {|obj|
        inputValues.x = obj.x ? inputValues.x;
        inputValues.y = obj.y ? inputValues.y;
        inputValues.changed(\value);
    }

    remoteValue_ {|obj|
        inputValues.x = obj.x ? inputValues.x;
        inputValues.y = obj.y ? inputValues.y;
        inputValues.changed(\remoteValue);
    }

    value {
        ^inputValues;
    }

    free {
        OSCdef(listenAddress).free;
    }
}
