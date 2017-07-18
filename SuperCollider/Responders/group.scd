var createGroupResponders, setupLFO;

createGroupResponders = {|self|
    var units = List[];
    var spec = ControlSpec(0, 0.716, \lin, 0, 0.716); // 0.716 is 0dB in Reaper
    var groups = [
        (listen: '/group1/volume/L', send: '/track/2/volume'),
        (listen: '/group1/volume/R', send: '/track/3/volume'),

        (listen: '/group2/volume/L', send: '/track/5/volume'),
        (listen: '/group2/volume/R', send: '/track/6/volume'),

        (listen: '/group3/volume/L', send: '/track/8/volume'),
        (listen: '/group3/volume/R', send: '/track/9/volume'),

        (listen: '/group4/volume/L', send: '/track/11/volume'),
        (listen: '/group4/volume/R', send: '/track/12/volume'),

        (listen: '/group5/volume/L', send: '/track/14/volume'),
        (listen: '/group5/volume/R', send: '/track/15/volume'),

        (listen: '/group6/volume/L', send: '/track/17/volume'),
        (listen: '/group6/volume/R', send: '/track/18/volume'),

        (listen: '/group7/volume/L', send: '/track/20/volume'),
        (listen: '/group7/volume/R', send: '/track/21/volume'),

        (listen: '/group8/volume/L', send: '/track/23/volume'),
        (listen: '/group8/volume/R', send: '/track/24/volume'),
    ];

    groups.do {|params|
        var unit;
        self.all.groups.put(
            params.listen,
            unit = XchnUnitState(
                params.listen,
                params.send,
                spec
            )
        );

        self.addToCleanup(
            OSCFunc({|msg|
                var val = msg[1];
                unit.remoteValue = val;
            }, params.listen)
        );

        units.add(unit);
    };

    // stereo pairs
    units.clump(2).do {|channels, i|
        var lfos = ();

        lfos.sine = XchnLFO.connect(channels);
        lfos.random = XchnLFO.connect(channels);
        lfos.sine.type = \stereo;
        lfos.random.type = \random;

        setupLFO.(self, "group" ++ (i + 1), lfos);
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
    createGroupResponders.(self);
}
