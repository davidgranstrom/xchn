(
    var localAddress = "127.0.0.1"; // address to Reaper
    var localPort = 8000;
    var remoteAddress = "192.168.0.2"; // address to iOS device
    var remotePort = 9000;

    var updateInterval = 30; // update interval (in Hz) for server side LFOs

    q = q ? ();

    q.init = {|self|
        self.all = ();
        self.all.master = ();
        self.all.master.eq = ();
        self.all.groups = ();
        self.all.absolute = ();
        self.all.fx = ();

        XchnLFO.updateInterval = updateInterval;

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
        var path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "Responders";

        [ "master", "group", "main", "fx" ].do {|name|
            var file = (path +/+ name ++ ".scd").load;
            file.(self);
        };
    };

    q.setupLFOs = {|self, prefix, lfos|
        var rateSpec = ControlSpec(1/60, 4, \exp, 0, 1/10);
        var intSpec = ControlSpec(1, 0, \lin, 0, 1);

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
        self.addToCleanup(
            OSCFunc({|msg|
                lfos.do {|lfo| lfo.rate = rateSpec.map(msg[1]) };
            }, "/%/lfo/rate".format(prefix))
        );

        self.addToCleanup(
            OSCFunc({|msg|
                lfos.do {|lfo| lfo.minVal = intSpec.map(msg[1]) };
            }, ("/%/lfo/int".format(prefix)))
        );

        self.addToCleanup({ lfos.do(_.free) });
    };

    q.addToCleanup = {|self, thing|
        var func;
        self.cleanupList ?? { self.cleanupList = List[] };

        if(thing.isFunction.not) {
            func = { thing.free }
        };

        self.cleanupList.add(func ? thing);
        // return item
        thing;
    };

    q.dealloc = {|self|
        XchnNetwork.disconnect;

        self.cleanupList !? {
            self.cleanupList.do(_.value);
            self.cleanupList = List[];
        };
    };

    s.waitForBoot {
        q.dealloc;
        q.init;
        s.sync;
        CmdPeriod.doOnce { q.dealloc; };
    };
)
