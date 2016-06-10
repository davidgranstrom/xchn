XchnUnit : XchnNetwork {
    var <>listenAddress, <>sendAddress, <>controlSpec;
    var <>inputValue;
    var <>pollTime = 30;

    var lfo, lfotype, lfoAddress;

    *new {|listenAddress, sendAddress, controlSpec|
        ^super.newCopyArgs(listenAddress, sendAddress, controlSpec).initXchnUnit;
    }

    initXchnUnit {
        // inputValue = Ref(controlSpec.default);
        inputValue = controlSpec.default;

        this.sendToLocal(sendAddress, inputValue, true); // prime with default value

        lfoAddress = (listenAddress ++ "_lfo").asSymbol; // "address" is unique
        this.createSynthDef(lfoAddress);

        this.setupResponders();
    }

    setupResponders {
        OSCdef(listenAddress, {|msg|
            var val = msg[1];
            inputValue = val;
            this.sendToLocal(sendAddress, controlSpec.map(val));
        }, listenAddress);

        OSCdef(lfoAddress, {|msg|
            var val = msg[3];
            this.sendToLocal(sendAddress, controlSpec.map(inputValue + val)); // clamp values in sendToReaper func
        }, lfoAddress);
    }

    createSynthDef {|lfoAddr, type='random'|
        SynthDef(lfoAddr, {|rate=1, minVal=0, maxVal=1|
            var lfo = LFDNoise1.kr(rate).range(minVal, maxVal);
            SendReply.kr(Impulse.kr(pollTime), lfoAddr, lfo);
        }).add;
    }

    lfoType_ {|type|
        lfotype = type;
        this.createSynthDef(lfoAddress, type);
    }

    lfoType {
        ^lfotype;
    }

    enableLFO {
        lfo ?? { lfo = Synth(lfoAddress) };
        OSCdef(lfoAddress).enable;
    }

    disableLFO {
        lfo !? { lfo.release; lfo = nil };
        OSCdef(lfoAddress).disable;
    }

    free {
        OSCdef(listenAddress).free;
        OSCdef(lfoAddress).free;
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
