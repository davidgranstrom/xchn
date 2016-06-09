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
        self.createAddressSpace();
        self.createResponders();
    };

    q.createAddressSpace = {|self|
        var default = (spec: ControlSpec(0, 1, \lin));
        var single, multi;

        single = [
            (address: '/master/eq/low', defaultValue: 0.5),
            (address: '/master/eq/lowmid', defaultValue: 0.5),
            (address: '/master/eq/highmid', defaultValue: 0.5),
            (address: '/master/eq/high', defaultValue: 0.5),
            (address: '/master/volume', spec: ControlSpec(0, 0.716, \lin, 0, 0)), // TODO: Use a spec instead
        ];

        multi = [];

        // set defaults
        single.do(_.parent_(default));
        multi.do(_.parent_(default));

        self.singleUnits = single;
        self.multiUnits = multi;
    };

    q.setupOSC = {|self|
        var reaper = NetAddr(localAddress, localPort);
        var touchOSC = NetAddr(remoteAddress, remotePort);

        XchnNetwork.localAddress = reaper;
        XchnNetwork.remoteAddress = touchOSC;
    };

    q.createResponders = {|self|
        self.singleUnits.do {|params|
            var addr = params.address;
            self.all.put(
                addr,
                XchnUnit(addr, params.spec)
            );
        };

        /*
        // misc
        self.all.put(
            '/master/eq/reset',
            XchnUnit('/master/eq/reset').action_({|msg|
                var low = self.all('/master/eq/low');
                low.valueAction = 0.5;
            });
        );
        */
    };

    q.start = {|self|

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

q.all

OSCFunc.trace(true, true);
Pbind

n = NetAddr("192.168.0.2", 9000);
n.sendMsg("/master/eq/low", 0.5);
n.sendMsg("/master/volume", 0);
n.sendMsg("/master/eq/lowmid", 0.5);
n.sendMsg("/master/now/playing", "something awesome");

n.sendMsg("/fx/main", 0.5, 0.5);
n.sendMsg("/fx/group1", 0.5, 0.5);
n.sendMsg("/1/fx/group3", 0.5, 0.5);

n.sendMsg("/1/multifader4/1", 0);

n.sendMsg("/1/master/eq/low", 0.5);
n.sendMsg("/1/master/volume", 1);



x = OSCdef(\test, {|msg| msg.postln });

x.add({})
x.remove
x.func



