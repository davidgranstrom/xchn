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
        // set default
        this.value = controlSpec.unmap(controlSpec.default);
    }

    setupController {|model|
        var controller = SimpleController(model);
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
}
