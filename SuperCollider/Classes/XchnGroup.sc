XchnGroup {
    var listenPrefix, sendAddresses, controlSpec;
    var leftChannel, rightChannel;
    var cleanup;

    *new {|listenPrefix, sendAddresses, controlSpec|
        ^super.newCopyArgs(listenPrefix, sendAddresses, controlSpec).init;
    }

    init {
        var leftAddress = (listenPrefix ++ "/volume/L").asSymbol;
        var rightAddress = (listenPrefix ++ "/volume/R").asSymbol;

        leftChannel = XchnUnitState(leftAddress, sendAddresses.left, controlSpec);
        rightChannel = XchnUnitState(rightAddress, sendAddresses.right, controlSpec);

        cleanup = List[];

        // setup responders
        OSCdef(leftAddress, {|msg|
            var val = msg[1];
            leftChannel.remoteValue = val;
        }, leftAddress);

        this.addToCleanup(OSCdef(leftAddress));

        OSCdef(rightAddress, {|msg|
            var val = msg[1];
            rightChannel.remoteValue = val;
        }, rightAddress);

        this.addToCleanup(OSCdef(rightAddress));

        this.attachLFO;
    }

    attachLFO {
        var rateSpec = ControlSpec(1/60, 1, \exp, 0, 1/10);
        var intSpec = ControlSpec(0, 1, \lin, 0, 0);

        // connect parameters
        var sineLFO = XchnLFO.connect([ leftChannel, rightChannel ]);
        var randLFO = XchnLFO.connect([ leftChannel, rightChannel ]);

        var addr;

        sineLFO.type = \stereo;
        sineLFO.rate = rateSpec.default;
        sineLFO.minVal = intSpec.default;

        randLFO.type = \random;
        randLFO.rate = rateSpec.default;
        randLFO.minVal = intSpec.default;

        // send defaults to remote
        XchnNetwork.remoteAddress.sendMsg(listenPrefix ++ "/lfo/rate", rateSpec.unmap(rateSpec.default));
        XchnNetwork.remoteAddress.sendMsg(listenPrefix ++ "/lfo/int", intSpec.unmap(intSpec.default));

        // setup responders
        addr = (listenPrefix ++ "/lfo/rate").asSymbol;
        OSCdef(addr, {|msg|
            sineLFO.rate = rateSpec.map(msg[1]);
            randLFO.rate = rateSpec.map(msg[1]);
        }, addr);

        this.addToCleanup(OSCdef(addr));

        addr = (listenPrefix ++ "/lfo/int").asSymbol;
        OSCdef(addr, {|msg|
            sineLFO.minVal = 1 - intSpec.map(msg[1]);
            randLFO.minVal = 1 - intSpec.map(msg[1]);
        }, addr);

        this.addToCleanup(OSCdef(addr));

        addr = (listenPrefix ++ "/lfo/sine/toggle").asSymbol;
        OSCdef(addr, {|msg|
            if(randLFO.isRunning) {
                randLFO.stop;
                XchnNetwork.remoteAddress.sendMsg(listenPrefix ++ "/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ sineLFO.start }, { sineLFO.stop });
        }, addr);

        this.addToCleanup(OSCdef(addr));

        addr = (listenPrefix ++ "/lfo/random/toggle").asSymbol;
        OSCdef(addr, {|msg|
            if(sineLFO.isRunning) {
                sineLFO.stop;
                XchnNetwork.remoteAddress.sendMsg(listenPrefix ++ "/lfo/sine/toggle", 0);
            };
            (msg[1].booleanValue).if({ randLFO.start }, { randLFO.stop });
        }, addr);

        this.addToCleanup(OSCdef(addr));
    }

    addToCleanup {|obj|
        cleanup.add(obj)
    }

    free {
        cleanup.do(_.free);
    }
}
