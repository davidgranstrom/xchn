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
