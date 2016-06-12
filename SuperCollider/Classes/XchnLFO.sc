XchnLFO {
    var <units;
    var <address, <listenAddress, <type, lfo;
    var <>updateInterval;

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

    type_ {|argType|
        type = argType;
        this.createLFO(address, type);
    }

    rate_ {|rate=1|
        lfo.set(\rate, rate);
    }

    start {
        currentUnitValues = units.collect(_.value);
        lfo ?? { lfo = Synth(address) };
    }

    stop {
        lfo !? { lfo.free; lfo = nil };
        this.invalidateLatch;
    }

    toggle {
        if(lfo.isNil) {
            currentUnitValues = units.collect(_.value);
            lfo = Synth(address);
        } {
            lfo.free;
            lfo = nil;
            this.invalidateLatch;
        }
    }

    listenAddress_ {|addr|
        listenAddress = addr;
        OSCdef(addr, { this.toggle }, addr);
    }

    makeStereo {|address|
        SynthDef(address, {|rate=1, minVal=0, maxVal=1|
            // var left = SinOsc.kr(rate).range(minVal, maxVal);
            // var right = SinOsc.kr(rate, 0.75pi).range(minVal, maxVal);
            // SendReply.kr(Impulse.kr(updateInterval), address, [ left, right ]);
            var circle = Pan2.kr(DC.kr(1), SinOsc.kr(rate));
            SendReply.kr(Impulse.kr(updateInterval), address, circle);
        }).add;
    }

    makeCircle {|address|
        SynthDef(address, {|rate=0.5, minVal=0, maxVal=1|
            var circle = PanAz.kr(units.size, DC.kr(1), LFSaw.kr(rate), 1, 2, 0);
            SendReply.kr(Impulse.kr(updateInterval), address, circle);
        }).add;
    }

    createLFO {|address, type=\leftRight|
        switch (type)
        { \stereo } {
            this.makeStereo(address);
        }
        { \circle } {
            this.makeCircle(address);
        };
    }

    free {
        this.stop;
        OSCdef(address).free;
        OSCdef(listenAddress).free;
    }
}

