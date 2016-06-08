XchnNetwork {
    classvar <>localAddress;
    classvar <>remoteAddress;

    *new {
        ^super.new;
    }

    *disconnect {
        localAddress !? { localAddress.disconnect };
        remoteAddress !? { remoteAddress.disconnect };
    }

    sendToLocal {|addr, msg, forwardToRemote=false|
        "network: %: %\n".postf(addr, msg);
        localAddress.sendMsg(addr, msg);
        if(forwardToRemote) {
            this.sendToRemote(addr, msg);
        }
    }

    sendToRemote {|addr, msg|
        remoteAddress.sendMsg(addr, msg);
    }
}

XchnUnit : XchnNetwork {
    var <>address, <>inputValue;
    var <>pollTime = 30;
    var lfo, lfotype, lfoAddress;

    *new {|address, defaultValue=0|
        ^super.new.address_(address.asSymbol).inputValue_(defaultValue).initXchnUnit;
    }

    initXchnUnit {
        this.sendToLocal(address, inputValue, true); // prime with default value

        lfoAddress = (address ++ "_lfo").asSymbol; // "address" is unique
        this.createSynthDef(lfoAddress);

        this.setupResponders();
    }

    setupResponders {
        OSCdef(address, {|msg|
            var val = msg[1];
            inputValue = val;
            this.sendToLocal(address, val);
        }, address);

        OSCdef(lfoAddress, {|msg|
            var val = msg[3];
            this.sendToLocal(address, inputValue + val); // clamp values in sendToReaper func
        }, lfoAddress);
    }

    createSynthDef {|lfoAddr, type='random'|
        SynthDef(lfoAddr, {|rate=1, minVal=0, maxVal=1|
            var lfo = LFDNoise1.kr(rate).range(minVal, maxVal);
            SendReply.kr(Impulse.kr(pollTime), lfoAddr, lfo);
        }).add;
    }

    action_ {|func|
        OSCdef(address, func, address);
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
        OSCdef(address).free;
        OSCdef(lfoAddress).free;
    }
}

