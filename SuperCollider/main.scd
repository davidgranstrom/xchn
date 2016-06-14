(
    var localAddress = "127.0.0.1"; // address to Reaper
    var localPort = 8000;
    var remoteAddress = "192.168.0.2"; // address to iOS device
    var remotePort = 9000;

    var updateInterval = 30; // update interval for server side LFOs
    var cleanup = List[];

    q = q ? ();

    q.init = {|self|
        // storage for responders
        self.all = ();
        self.all.master = ();
        self.all.master.eq = ();
        self.all.groups = ();
        self.all.absolute = ();
        self.all.fx = ();

        self.setupOSC();
        self.createResponders();
    };

    q.setupOSC = {|self|
        var reaper = NetAddr(localAddress, localPort);
        var touchOSC = NetAddr(remoteAddress, remotePort);

        XchnNetwork.local = reaper;
        XchnNetwork.remote = touchOSC;
    };

    q.createResponders = {|self|
        self.createMasterResponders();
        self.createGroupResponders();
        self.createMainResponders();
        self.createFxResponders();
    };

    q.createMasterResponders = {|self|
        var eqDefault = (spec: ControlSpec(0, 1, \lin, 0, 0.5));
        var eq, volume, label;

        eq = [
            (address: '/master/eq/low'),
            (address: '/master/eq/lowmid'),
            (address: '/master/eq/highmid'),
            (address: '/master/eq/high'),
        ];

        volume = (
            address: '/master/volume',
            spec: ControlSpec(0, 0.716, \lin, 0, 0)
        );

        eq.do {|params|
            var addr = params.address;
            params.parent_(eqDefault);
            self.all.master.eq.put(addr, XchnUnitState(addr, addr, params.spec));
        };

        self.all.master.put(
            volume.address,
            XchnUnitState(
                volume.address,
                volume.address,
                volume.spec
            )
        );

        OSCdef(volume.address, {|msg|
            var unit = self.all.master[volume.address];
            unit.remoteValue = msg[1];
        }, volume.address);

        // eq reset button
        OSCdef('/master/eq/reset', {|msg|
            self.all.master.eq.do {|unit|
                unit.value = eqDefault.spec.default;
            }
        }, '/master/eq/reset')
    };

    q.createGroupResponders = {|self|
        var spec = ControlSpec(0, 0.716, \lin, 0, 0.716); // 0.716 is 0dB in Reaper
        var units, groups = [
            (listen: '/group1/volume/L', send: '/track/3/volume'),
            (listen: '/group1/volume/R', send: '/track/4/volume'),

            (listen: '/group2/volume/L', send: '/track/6/volume'),
            (listen: '/group2/volume/R', send: '/track/7/volume'),

            (listen: '/group3/volume/L', send: '/track/9/volume'),
            (listen: '/group3/volume/R', send: '/track/10/volume'),

            (listen: '/group4/volume/L', send: '/track/12/volume'),
            (listen: '/group4/volume/R', send: '/track/13/volume'),

            (listen: '/group5/volume/L', send: '/track/15/volume'),
            (listen: '/group5/volume/R', send: '/track/16/volume')
        ];

        units = groups.collect {|params|
            var unit, resp;

            self.all.groups.put(
                params.listen,
                unit = XchnUnitState(
                    params.listen,
                    params.send,
                    spec
                )
            );

            resp = OSCFunc({|msg|
                var val = msg[1];
                unit.remoteValue = val;
            }, params.listen);

            self.addToCleanup(resp);

            unit;
        };

        // stereo pairs
        units.clump(2).do {|channels, i|
            var lfos = ();

            lfos.sine = XchnLFO.connect(channels);
            lfos.random = XchnLFO.connect(channels);
            lfos.sine.type = \stereo;
            lfos.random.type = \random;

            self.setupLFOUnit("group" ++ (i + 1), lfos);
        };
    };

    q.createMainResponders = {|self|
        var units = List[];
        var rateSpec = ControlSpec(1/60, 1, \exp, 0, 1/10);
        var intSpec = ControlSpec(1, 0, \lin, 0, 1);
        var lfos = ();

        var spec = ControlSpec(0, 0.716, \lin, 0, 0.716); // 0.716 is 0dB in Reaper
        var absolute = [
            (
                listen: '/group1/abs/volume',
                send: '/track/2/volume'
            ),
            (
                listen: '/group2/abs/volume',
                send: '/track/5/volume'
            ),
            (
                listen: '/group3/abs/volume',
                send: '/track/8/volume'
            ),
            (
                listen: '/group4/abs/volume',
                send: '/track/11/volume'
            ),
            (
                listen: '/group5/abs/volume',
                send: '/track/14/volume'
            )
        ];

        absolute.do {|params|
            var unit;
            self.all.absolute.put(
                params.listen,
                unit = XchnUnitState(
                    params.listen,
                    params.send,
                    spec
                )
            );

            OSCdef(params.listen, {|msg|
                unit.remoteValue = msg[1];
            }, params.listen);

            units.add(unit);
        };

        // setup LFOs
        lfos.up = XchnLFO.connect(units);
        lfos.down = XchnLFO.connect(units.reverse);
        lfos.random = XchnLFO.connect(units);

        lfos.up.type = \circle;
        lfos.down.type = \circle;
        lfos.random.type = \random;

        self.setupMainLFOs("main", lfos);
    };

    q.createFxResponders = {|self|
        var default = (spec: ControlSpec(0, 1, \lin));
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
            createAddresses.(numInputs, "R", "x"),
            createAddresses.(numInputs, "L", "y"),
            createAddresses.(numInputs, "R", "y"),
        ].flatten;

        fx.do {|params|
            var unit, resp;

            params.parent_(default);

            self.all.fx.put(
                params.listen,
                unit = XchnUnitState(
                    params.listen,
                    params.send,
                    params.spec
                );
            );

            resp = OSCFunc({|msg|
                unit.remoteValue = msg[1];
            }, params.listen);

            self.addToCleanup(resp);
        };

        self.createGlobalFxParameters();
    };

    q.setupLFOUnit = {|self, prefix, lfos|
        var resp;

        self.setupLFOs(prefix, lfos);

        resp = OSCFunc({|msg|
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/%/lfo/random/toggle".format(prefix), 0);
            };
            (msg[1].booleanValue).if({ lfos.sine.start }, { lfos.sine.stop });
        }, "/%/lfo/sine/toggle".format(prefix));

        self.addToCleanup(resp);

        resp = OSCFunc({|msg|
            if(lfos.sine.isRunning) {
                lfos.sine.stop;
                XchnNetwork.remote.sendMsg("/%/lfo/sine/toggle".format(prefix), 0);
            };
            (msg[1].booleanValue).if({ lfos.random.start }, { lfos.random.stop });
        }, "/%/lfo/random/toggle".format(prefix));

        self.addToCleanup(resp);
    };

    q.setupMainLFOs = {|self, prefix, lfos|
        var resp;

        self.setupLFOs(prefix, lfos);

        resp = OSCFunc({|msg|
            if(lfos.down.isRunning) {
                lfos.down.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
            };
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.up.start }, { lfos.up.stop });
        }, "/main/lfo/up/toggle");

        self.addToCleanup(resp);

        resp = OSCFunc({|msg|
            if(lfos.up.isRunning) {
                lfos.up.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
            };
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.down.start }, { lfos.down.stop });
        }, "/main/lfo/down/toggle");

        self.addToCleanup(resp);

        resp = OSCFunc({|msg|
            if(lfos.up.isRunning) {
                lfos.up.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
            };
            if(lfos.down.isRunning) {
                lfos.down.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.random.start }, { lfos.random.stop });
        }, "/main/lfo/random/toggle");

        self.addToCleanup(resp);
    };

    q.setupLFOs = {|self, prefix, lfos|
        var rateSpec = ControlSpec(1/60, 1, \exp, 0, 1/10);
        var intSpec = ControlSpec(1, 0, \lin, 0, 1);
        var resp;

        lfos.do {|lfo|
            lfo.rate = rateSpec.default;
            lfo.minVal = intSpec.default;
        };

        // send defaults to remote
        XchnNetwork.remote.sendMsg("/%/lfo/rate".format(prefix), rateSpec.unmap(rateSpec.default));
        XchnNetwork.remote.sendMsg("/%/lfo/int".format(prefix), intSpec.unmap(intSpec.default));
        XchnNetwork.remote.sendMsg("/%/lfo/sine/toggle".format(prefix), 0);
        XchnNetwork.remote.sendMsg("/%/lfo/random/toggle".format(prefix), 0);

        // setup responders
        resp = OSCFunc({|msg|
            lfos.do {|lfo| lfo.rate = rateSpec.map(msg[1]) };
        }, "/%/lfo/rate".format(prefix));

        self.addToCleanup(resp);

        resp = OSCFunc({|msg|
            lfos.do {|lfo| lfo.minVal = intSpec.map(msg[1]) };
        }, ("/%/lfo/int".format(prefix)));

        self.addToCleanup(resp);
    };

    q.createGlobalFxParameters = {|self|
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

        self.setupLFOUnit("fx/global/reverb", lfos.reverb);
        self.setupLFOUnit("fx/global/distortion", lfos.distortion);
        self.setupLFOUnit("fx/global/grain", lfos.grain);

        params.keys.do {|name|
            var addr = "/fx/global/%/value".format(name);

            OSCdef(addr, {|msg|
                params[name].values.do {|unit|
                    unit.remoteValue = msg[1];
                };
            }, addr);
        };
    };

    q.addToCleanup = {|self, thing|
        cleanup.add(thing);
    };

    q.cleanup = {|self|
        XchnNetwork.disconnect;
        self.all.do {|dict| dict.do(_.free) };
        cleanup.do(_.free);
    };

    s.waitForBoot {
        q.init;
        s.sync;
        CmdPeriod.doOnce { q.cleanup; };
    };
)

~reaperPort = NetAddr("127.0.0.1", 8000);
~reaperPort.sendMsg("/input/2/R/fx-select/y", 0.5);

OSCFunc.trace(true, true);
OSCFunc.trace(false);

q.all.relative['/relative/1'].value = 0;
q.all.relative['/relative/1'].value;
q.all.relative['/relative/2'].value;

q.all.fx['/fx/main'].value = (x: 0.5, y: 0.5);
q.all.fx['/fx/main'].value

s.plotTree;

