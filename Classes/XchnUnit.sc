XchnUnit : XchnNetwork {
    var <>listenAddress, <>sendAddress, <>controlSpec;
    var inputValue, controller;

    *new {|listenAddress, sendAddress, controlSpec|
        ^super.newCopyArgs(listenAddress, sendAddress, controlSpec).initXchnUnit;
    }

    initXchnUnit {
        inputValue = Ref();
        controller = SimpleController(inputValue);

        // listen for changes from "outside"
        controller.put(\value, {|obj, what, args|
            var val = obj.value;
            this.sendToLocal(sendAddress, controlSpec.map(val));
            this.sendToRemote(listenAddress, val);
        });

        // listen to changes from remote
        controller.put(\remoteValue, {|obj, what, args|
            var val = obj.value;
            this.sendToLocal(sendAddress, controlSpec.map(val));
        });

        // responder for remote osc
        OSCdef(listenAddress, {|msg|
            var val = msg[1];
            this.remoteValue = val;
        }, listenAddress);

        // set default
        inputValue.value = controlSpec.unmap(controlSpec.default);
    }

    value_ {|val|
        inputValue.value_(val).changed(\value);
    }

    remoteValue_ {|val|
        inputValue.value_(val).changed(\remoteValue);
    }

    value {
        ^inputValue.value;
    }

    free {
        OSCdef(listenAddress).free;
    }
}

XchnXYPad : XchnNetwork {
    var <>listenAddress, <>sendXAddress, sendYAddress, <>controlSpec;

    *new {|listenAddress, sendXAddress, sendYAddress, controlSpec|
        ^super.newCopyArgs(listenAddress, sendXAddress, sendYAddress, controlSpec).initXchnMultiUnit;
    }

    initXchnMultiUnit {
        this.setupResponders();
    }

    setupResponders {
        OSCdef(listenAddress, {|msg|
            var x = msg[1];
            var y = msg[2];

            sendXAddress.do {|addr|
                this.sendToLocal(addr, controlSpec.map(x));
            };

            sendYAddress.do {|addr|
                this.sendToLocal(addr, controlSpec.map(y));
            };
        }, listenAddress);

        // OSCdef(lfoAddress, {|msg|
        //     var val = msg[3];
        //     this.sendToLocal(listenAddress, controlSpec.map(inputValue + val)); // clamp values in sendToReaper func
        // }, lfoAddress);
    }
}
