XchnLFO {
    var <units;
    var <address;
    var <>updateInterval;

    var lfo, <>type, <minVal, <maxVal, <rate;
    var latch, currentUnitValues;

    *new {|units|
        ^super.newCopyArgs(units).init;
    }

    *connect {|units|
        ^XchnLFO.new(units);
    }

    init {
        address = ("/lfo_" ++ Server.default.nextNodeID).asSymbol;
        updateInterval = 30;
        minVal = 0;
        maxVal = 1;
        type = \stereo;

        this.makeSynthDefs;
        this.invalidateLatch;

        OSCdef(address, {|msg|
            var val = msg[3..];
            val.do {|x, i|
                // skip check ("or:{}") for efficiency if latched value is already reached.
                if(latch[i] or:{x.equalWithPrecision(currentUnitValues[i], 0.05)}) {
                    latch[i] = true;
                };

                if(latch[i]) {
                    units[i].value = x;
                };
            };
        }, address);
    }

    invalidateLatch {
        latch = Array.fill(units.size, { false });
    }

    rate_ {|val=1|
        rate = val;
        lfo !? { lfo.set(\rate, val) };
    }

    minVal_ {|val|
        minVal = val;
        lfo !? { lfo.set(\minVal, val) };
    }

    maxVal_ {|val|
        maxVal = val;
        lfo !? { lfo.set(\maxVal, val) };
    }

    start {
        lfo ?? {
            currentUnitValues = units.collect(_.value);
            lfo = Synth(
                (address ++ "_" ++ type).asSymbol, [
                \minVal, minVal,
                \maxVal, maxVal,
                \rate, rate
            ]).onFree { this.invalidateLatch };
        };
    }

    stop {
        lfo !? {
            lfo.free;
            lfo = nil;
        };
    }

    toggle {
        lfo.isNil.if({ this.start }, { this.stop });
    }

    isRunning {
        ^lfo.notNil;
    }

    makeSynthDefs {
        SynthDef((address ++ "_stereo").asSymbol, {|rate=0.5, minVal=0, maxVal=1|
            var circle = Pan2.kr(DC.kr(1), SinOsc.kr(rate));
            SendReply.kr(Impulse.kr(updateInterval), address, circle.linlin(0, 1, minVal, maxVal));
        }).add;

        SynthDef((address ++ "_circle").asSymbol, {|rate=0.5, minVal=0, maxVal=1|
            var circle = PanAz.kr(units.size, DC.kr(1), LFSaw.kr(rate), 1, 2, 0);
            SendReply.kr(Impulse.kr(updateInterval), address, circle.linlin(0, 1, minVal, maxVal));
        }).add;

        SynthDef((address ++ "_random").asSymbol, {|rate=0.5, minVal=0, maxVal=1|
            var rand = LFDNoise1.kr(rate ! units.size);
            SendReply.kr(Impulse.kr(updateInterval), address, rand.range(minVal, maxVal));
        }).add;

        // mono
        SynthDef((address ++ "_mono_random").asSymbol, {|rate=0.5, minVal=0, maxVal=1|
            var rand = LFDNoise1.kr(rate);
            SendReply.kr(Impulse.kr(updateInterval), address, rand.range(minVal, maxVal));
        }).add;

        SynthDef((address ++ "_mono_sine").asSymbol, {|rate=0.5, minVal=0, maxVal=1|
            var sine = SinOsc.kr(rate);
            SendReply.kr(Impulse.kr(updateInterval), address, sine.range(minVal, maxVal));
        }).add;
    }

    free {
        this.stop;
        OSCdef(address).free;
    }
}

