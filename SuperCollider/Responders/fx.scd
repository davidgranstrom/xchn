var createFxResponders, createGlobalFxParameters, setupLFO;

createFxResponders = {|self|
    var default = (spec: ControlSpec(1, 0, \lin));
    var fx, numInputs = 5;

    var createAddresses = {|numInputs, channel, param|
        (1..numInputs).collect {|i|
            var listen = "/fx/select/group%".format(i).asSymbol;
            var send = "/input/%/%/fx-select/%".format(i, channel, param).asSymbol;

            (listen: listen, send: send);
        };
    };

    fx = [
        createAddresses.(numInputs, "L", "x"),
        createAddresses.(numInputs, "L", "y"),
        createAddresses.(numInputs, "R", "x"),
        createAddresses.(numInputs, "R", "y"),
    ];

    fx.do {|parameters, msgIdx|
        parameters.do {|params|
            var unit;

            params.parent_(default);

            self.all.fx.put(
                params.listen,
                unit = XchnUnitState(
                    params.listen,
                    params.send,
                    params.spec
                );
            );

            self.addToCleanup(
                OSCFunc({|msg|
                    unit.remoteValue = msg[1 + (msgIdx % 2)];
                }, params.listen)
            );
        };
    };

    createGlobalFxParameters.(self);
};

createGlobalFxParameters = {|self|
    var params = (reverb: (), distortion: (), grain: ());
    var lfos = (reverb: (), distortion: (), grain: ());
    var specs = ();

    specs.reverb = (
        cfreq: ControlSpec(0, 1, \lin, 0, 0.5),
        roomSize: ControlSpec(0, 1, \lin, 0, 0.5),
    );

    specs.distortion = (
        gain: ControlSpec(0, 1, \lin, 0, 0),
    );

    specs.grain = (
        density: ControlSpec(0, 1, \lin, 0, 0.1),
    );

    params.reverb.cfreq = XchnUnitState(
        '/fx/global/reverb/value',
        '/reverb/bpf/cfreq',
        specs.reverb.cfreq
    );

    params.reverb.roomSize = XchnUnitState(
        '/fx/global/reverb/value',
        '/reverb/roomSize',
        specs.reverb.roomSize
    );

    params.distortion.gain = XchnUnitState(
        '/fx/global/distortion/value',
        '/distortion/gain',
        specs.distortion.gain
    );

    params.grain.density = XchnUnitState(
        '/fx/global/grain/value',
        '/grain/density',
        specs.grain.density
    );

    lfos.reverb.sine = XchnLFO.connect(params.reverb.values);
    lfos.reverb.random = XchnLFO.connect(params.reverb.values);

    lfos.distortion.sine = XchnLFO.connect(params.distortion.values);
    lfos.distortion.random = XchnLFO.connect(params.distortion.values);

    lfos.grain.sine = XchnLFO.connect(params.grain.values);
    lfos.grain.random = XchnLFO.connect(params.grain.values);

    lfos.do {|lfo|
        lfo.sine.type = \mono_sine;
        lfo.random.type = \mono_random;
    };

    setupLFO.(self, "fx/global/reverb", lfos.reverb);
    setupLFO.(self, "fx/global/distortion", lfos.distortion);
    setupLFO.(self, "fx/global/grain", lfos.grain);

    params.keys.do {|name|
        var addr = "/fx/global/%/value".format(name);

        OSCdef(addr, {|msg|
            params[name].values.do {|unit|
                unit.remoteValue = msg[1];
            };
        }, addr);
    };
};

setupLFO = {|self, prefix, lfos|
    self.setupLFOs(prefix, lfos);

    self.addToCleanup(
        OSCFunc({|msg|
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/%/lfo/random/toggle".format(prefix), 0);
            };
            (msg[1].booleanValue).if({ lfos.sine.start }, { lfos.sine.stop });
        }, "/%/lfo/sine/toggle".format(prefix))
    );

    self.addToCleanup(
        OSCFunc({|msg|
            if(lfos.sine.isRunning) {
                lfos.sine.stop;
                XchnNetwork.remote.sendMsg("/%/lfo/sine/toggle".format(prefix), 0);
            };
            (msg[1].booleanValue).if({ lfos.random.start }, { lfos.random.stop });
        }, "/%/lfo/random/toggle".format(prefix))
    );
};

// return
{|self|
    createFxResponders.(self);
}
