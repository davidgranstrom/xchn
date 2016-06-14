(
    var localAddress = "127.0.0.1"; // address to Reaper
    var localPort = 8000;
    var remoteAddress = "192.168.0.2"; // address to iOS device
    var remotePort = 9000;

    var updateInterval = 30; // update interval for server side LFOs

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
        // self.createFxResponders();
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
            XchnUnitState(volume.address, volume.address, volume.spec)
        );

        // eq reset button
        OSCdef('/master/eq/reset', {|msg|
            self.all.master.eq.do {|unit|
                unit.value = eqDefault.default;
            }
        }, '/master/eq/reset')
    };

    q.createGroupResponders = {|self|
        var spec = ControlSpec(0, 0.716, \lin, 0, 0.716); // 0.716 is 0dB in Reaper
        var groups = [
            (
                listen: '/group1',
                send: (
                    left: '/track/3/volume',
                    right: '/track/4/volume'
                ),
            ),
            (
                listen: '/group2',
                send: (
                    left: '/track/6/volume',
                    right: '/track/7/volume'
                ),
            ),
            (
                listen: '/group3',
                send: (
                    left: '/track/9/volume',
                    right: '/track/10/volume'
                ),
            ),
            (
                listen: '/group4',
                send: (
                    left: '/track/12/volume',
                    right: '/track/13/volume'
                ),
            ),
            (
                listen: '/group5',
                send: (
                    left: '/track/15/volume',
                    right: '/track/16/volume'
                ),
            )
        ];

        groups.do {|params|
            self.all.groups.put(
                params.listen,
                XchnGroup(
                    params.listen,
                    params.send,
                    spec
                )
            );
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

            units.add(unit);
        };

        // setup LFOs
        lfos.up = XchnLFO.connect(units);
        lfos.down = XchnLFO.connect(units.reverse);
        lfos.random = XchnLFO.connect(units);

        lfos.up.type = \circle;
        lfos.down.type = \circle;
        lfos.random.type = \random;

        lfos.do {|lfo|
            lfo.rate = rateSpec.default;
            lfo.minVal = intSpec.default;
        };

        // send defaults to remote
        XchnNetwork.remote.sendMsg("/main/lfo/rate", rateSpec.unmap(rateSpec.default));
        XchnNetwork.remote.sendMsg("/main/lfo/int", intSpec.unmap(intSpec.default));
        XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
        XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
        XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);

        OSCdef('/main/lfo/rate', {|msg|
            lfos.do {|lfo| lfo.rate = rateSpec.map(msg[1]) };
        }, '/main/lfo/rate');

        OSCdef('/main/lfo/int', {|msg|
            lfos.do {|lfo| lfo.minVal = intSpec.map(msg[1]) };
        }, '/main/lfo/int');

        OSCdef('/main/lfo/up/toggle', {|msg|
            if(lfos.down.isRunning) {
                lfos.down.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
            };
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.up.start }, { lfos.up.stop });
        }, '/main/lfo/up/toggle');

        OSCdef('/main/lfo/down/toggle', {|msg|
            if(lfos.up.isRunning) {
                lfos.up.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
            };
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.down.start }, { lfos.down.stop });
        }, '/main/lfo/down/toggle');

        OSCdef('/main/lfo/random/toggle', {|msg|
            if(lfos.up.isRunning) {
                lfos.up.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
            };
            if(lfos.down.isRunning) {
                lfos.down.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.random.start }, { lfos.random.stop });
        }, '/main/lfo/random/toggle');
    };

    q.createFxResponders = {|self|
        var default = (spec: ControlSpec(0, 1, \lin));
        var fx = [
            (
                listenAddress: '/fx/main',
                sendAddress: (
                    x: [
                        '/input/1/L/fx-select/x',
                        '/input/1/R/fx-select/x'
                    ],
                    y: [
                        '/input/1/L/fx-select/y',
                        '/input/1/R/fx-select/y'
                    ]
                )
            ),
            (
                listenAddress: '/fx/group1',
                sendAddress: (
                    x: [
                        '/input/2/L/fx-select/x',
                        '/input/2/R/fx-select/x'
                    ],
                    y: [
                        '/input/2/L/fx-select/y',
                        '/input/2/R/fx-select/y'
                    ]
                )
            ),
            (
                listenAddress: '/fx/group2',
                sendAddress: (
                    x: [
                        '/input/3/L/fx-select/x',
                        '/input/3/R/fx-select/x'
                    ],
                    y: [
                        '/input/3/L/fx-select/y',
                        '/input/3/R/fx-select/y'
                    ]
                )
            ),
            (
                listenAddress: '/fx/group3',
                sendAddress: (
                    x: [
                        '/input/4/L/fx-select/x',
                        '/input/4/R/fx-select/x'
                    ],
                    y: [
                        '/input/4/L/fx-select/y',
                        '/input/4/R/fx-select/y'
                    ]
                )
            ),
            (
                listenAddress: '/fx/group4',
                sendAddress: (
                    x: [
                        '/input/5/L/fx-select/x',
                        '/input/5/R/fx-select/x'
                    ],
                    y: [
                        '/input/5/L/fx-select/y',
                        '/input/5/R/fx-select/y'
                    ]
                )
            )
        ];

        fx.do {|params|
            var addr = params.listenAddress;
            params.parent_(default);
            self.all.fx.put(
                addr,
                XchnXYPad(
                    addr,
                    params.sendAddress,
                    params.spec
                );
            );
        };
    };

    q.cleanup = {|self|
        XchnNetwork.disconnect;
        self.all.do {|dict| dict.do(_.free) };
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

