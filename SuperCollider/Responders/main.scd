var createMainResponders, setupLFO;

createMainResponders = {|self|
    var units = List[];
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

    // don't assign "group 1" to LFOs (master)
    // units.removeAt(0);

    // setup LFOs
    lfos.up = XchnLFO.connect(units);
    lfos.down = XchnLFO.connect(units.reverse);
    lfos.random = XchnLFO.connect(units);

    lfos.up.type = \circle;
    lfos.down.type = \circle;
    lfos.random.type = \random;

    setupLFO.(self, "main", lfos);
};

setupLFO = {|self, prefix, lfos|
    self.setupLFOs(prefix, lfos);

    self.addToCleanup(
        OSCFunc({|msg|
            if(lfos.down.isRunning) {
                lfos.down.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
            };
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.up.start }, { lfos.up.stop });
        }, "/main/lfo/up/toggle")
    );

    self.addToCleanup(
        OSCFunc({|msg|
            if(lfos.up.isRunning) {
                lfos.up.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
            };
            if(lfos.random.isRunning) {
                lfos.random.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/random/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.down.start }, { lfos.down.stop });
        }, "/main/lfo/down/toggle")
    );

    self.addToCleanup(
        OSCFunc({|msg|
            if(lfos.up.isRunning) {
                lfos.up.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/up/toggle", 0);
            };
            if(lfos.down.isRunning) {
                lfos.down.stop;
                XchnNetwork.remote.sendMsg("/main/lfo/down/toggle", 0);
            };
            (msg[1].booleanValue).if({ lfos.random.start }, { lfos.random.stop });
        }, "/main/lfo/random/toggle")
    );
};

// return
{|self|
    createMainResponders.(self)
};
