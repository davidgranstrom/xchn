XchnXYPad : XchnNetwork {
    var <>listenAddress, <>sendXAddress, sendYAddress, <>controlSpec;
    var inputValues, controller;

    *new {|listenAddress, sendXAddress, sendYAddress, controlSpec|
        ^super.newCopyArgs(listenAddress, sendXAddress, sendYAddress, controlSpec).init;
    }

    init {
        inputValues = ();
        controller = SimpleController(inputValues);

        // listen for changes from "outside"
        controller.put(\value, {|obj, what, args|
            var x = obj.x;
            var y = obj.y;

            sendXAddress.do {|addr|
                this.sendToLocal(addr, controlSpec.map(x));
            };

            sendYAddress.do {|addr|
                this.sendToLocal(addr, controlSpec.map(y));
            };

            this.sendToRemote(listenAddress, x, y);
        });

        // listen to changes from remote
        controller.put(\remoteValue, {|obj, what, args|
            var x = obj.x;
            var y = obj.y;

            sendXAddress.do {|addr|
                this.sendToLocal(addr, controlSpec.map(x));
            };

            sendYAddress.do {|addr|
                this.sendToLocal(addr, controlSpec.map(y));
            };
        });

        OSCdef(listenAddress, {|msg|
            var x = msg[1];
            var y = msg[2];
            this.remoteValue = (x: x, y: y);
        }, listenAddress);

        this.value = (
            x: controlSpec.default,
            y: controlSpec.default
        );
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
