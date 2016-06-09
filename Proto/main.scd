(
    var trackNo1 = 3;
    var maxFaderValue = 0.707;
    var pollTime = 1/25; // poll interval for server side LFO's

    var localAddress = "127.0.0.1"; // address to Reaper
    var localPort = 8000;
    var remoteAddress = "192.168.0.2"; // address to iOS device
    var remotePort = 9000;

    q = q ? ();

    q.init = {|self|
        self.all = ();
        self.setupOSC();
        self.createResponders();
    };

    q.createMasterResponders = {|self|
        var eqDefault = (spec: ControlSpec(0, 1, \lin, 0, 0.5));
        var eq, volume, label;

        eq = [
            (listenAddress: '/master/eq/low'),
            (listenAddress: '/master/eq/lowmid'),
            (listenAddress: '/master/eq/highmid'),
            (listenAddress: '/master/eq/high'),
        ];

        volume = (
            listenAddress: '/master/volume',
            spec: ControlSpec(0, 0.716, \lin, 0, 0)
        );

        eq.do {|params|
            var addr = params.listenAddress;
            params.parent_(eqDefault);
            self.all.put(addr, XchnUnit(addr, addr, params.spec));
        };

        self.all.put(
            volume.listenAddress,
            XchnUnit(volume.listenAddress, volume.listenAddress, volume.spec)
        );
    };

    q.createVolumeResponders = {|self|
        var default = (spec: ControlSpec(0, 0.716, \lin, 0, 0.716));
        var relative, absolute, all;

        relative = [
            (listenAddress: '/relative/1', sendAddress: '/track/2/volume'),
            (listenAddress: '/relative/2', sendAddress: '/track/5/volume'),
            (listenAddress: '/relative/3', sendAddress: '/track/8/volume'),
            (listenAddress: '/relative/4', sendAddress: '/track/11/volume'),
            (listenAddress: '/relative/5', sendAddress: '/track/14/volume'),
        ];

        absolute = [
            (listenAddress: '/abs/main/1', sendAddress: '/track/3/volume'),
            (listenAddress: '/abs/main/2', sendAddress: '/track/4/volume'),
            (listenAddress: '/abs/group1/1', sendAddress: '/track/6/volume'),
            (listenAddress: '/abs/group1/2', sendAddress: '/track/7/volume'),
            (listenAddress: '/abs/group2/1', sendAddress: '/track/9/volume'),
            (listenAddress: '/abs/group2/2', sendAddress: '/track/10/volume'),
            (listenAddress: '/abs/group3/1', sendAddress: '/track/12/volume'),
            (listenAddress: '/abs/group3/2', sendAddress: '/track/13/volume'),
            (listenAddress: '/abs/group4/1', sendAddress: '/track/15/volume'),
            (listenAddress: '/abs/group4/2', sendAddress: '/track/16/volume'),
        ];

        (relative ++ absolute).do {|params|
            params.parent_(default);
            self.all.put(
                params.listenAddress,
                XchnUnit(
                    params.listenAddress,
                    params.sendAddress,
                    params.spec
                )
            );
        };

    };

    q.createFxResponders = {|self|
        var default = (spec: ControlSpec(0, 1, \lin));
        var fx = [
            (
                listenAddr: '/fx/main',
                sendX: [
                    '/input/1/L/fx-select/x',
                    '/input/1/R/fx-select/x'
                ],
                sendY: [
                    '/input/1/L/fx-select/y',
                    '/input/1/R/fx-select/y'
                ]
            ),
            (
                listenAddr: '/fx/group1',
                sendX: [
                    '/input/2/L/fx-select/x',
                    '/input/2/R/fx-select/x'
                ],
                sendY: [
                    '/input/2/L/fx-select/y',
                    '/input/2/R/fx-select/y'
                ]
            ),
            (
                listenAddr: '/fx/group2',
                sendX: [
                    '/input/3/L/fx-select/x',
                    '/input/3/R/fx-select/x'
                ],
                sendY: [
                    '/input/3/L/fx-select/y',
                    '/input/3/R/fx-select/y'
                ]
            ),
            (
                listenAddr: '/fx/group3',
                sendX: [
                    '/input/4/L/fx-select/x',
                    '/input/4/R/fx-select/x'
                ],
                sendY: [
                    '/input/4/L/fx-select/y',
                    '/input/4/R/fx-select/y'
                ]
            ),
            (
                listenAddr: '/fx/group4',
                sendX: [
                    '/input/5/L/fx-select/x',
                    '/input/5/R/fx-select/x'
                ],
                sendY: [
                    '/input/5/L/fx-select/y',
                    '/input/5/R/fx-select/y'
                ]
            )
        ];

        fx.do {|params|
            var addr = params.listenAddr;
            params.parent_(default);
            self.all.put(
                addr,
                XchnXYPad(
                    addr,
                    params.sendX,
                    params.sendY,
                    params.spec
                );
            );
        };
    };

    q.setupOSC = {|self|
        var reaper = NetAddr(localAddress, localPort);
        var touchOSC = NetAddr(remoteAddress, remotePort);

        XchnNetwork.localAddress = reaper;
        XchnNetwork.remoteAddress = touchOSC;
    };

    q.createResponders = {|self|
        self.createMasterResponders();
        self.createFxResponders();
        self.createVolumeResponders();
    };

    q.cleanup = {|self|
        XchnNetwork.disconnect;
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

