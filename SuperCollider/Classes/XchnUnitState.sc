// ===========================================================================
// Title         : XchnUnitState
// Description   : Tracks state between remote and local applications
// Copyright (c) : David Granström 2016
// ===========================================================================

XchnUnitState : XchnNetwork {
    var <>listenAddress, <>sendAddress, <>controlSpec;
    var inputValue;

    *new {|listenAddress, sendAddress, controlSpec|
        ^super.newCopyArgs(listenAddress, sendAddress, controlSpec).init;
    }

    init {
        inputValue = Ref();
        this.setupController(inputValue);
        this.value = controlSpec.unmap(controlSpec.default);
    }

    setupController {|model|
        // keep track of current state
        var controller = SimpleController(model);

        // send state to local and remote addresses
        controller.put(\value, {|obj, what, args|
            var val = obj.value;
            this.sendToLocal(sendAddress, controlSpec.map(val));
            this.sendToRemote(listenAddress, val);
        });

        // send state to local address
        controller.put(\remoteValue, {|obj, what, args|
            var val = obj.value;
            this.sendToLocal(sendAddress, controlSpec.map(val));
        });

        // send state to remote address
        controller.put(\localValue, {|obj, what, args|
            var val = obj.value;
            this.sendToRemote(sendAddress, controlSpec.unmap(val));
        });
    }

    value_ {|val|
        inputValue.value_(val).changed(\value);
    }

    remoteValue_ {|val|
        inputValue.value_(val).changed(\remoteValue);
    }

    localValue_ {|val|
        inputValue.value_(val).changed(\localValue);
    }

    value {
        ^inputValue.value;
    }
}
