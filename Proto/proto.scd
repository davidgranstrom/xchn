(
    var maxFaderValue = 0.707;
    var pollTime = 1/25;

    q = q ? ();

    q.init = {|self|
        self.setupOSC();
        self.buses = ();

        // self.createBuses();
        self.createBus('lfo');
        s.sync;
        self.makeSynthDefs();
        s.sync;

        Synth(\lfo, [\out, self.buses.lfo]);

        self.readBusValues();
    };

    q.createBus = {|self, name|
        var bus = Bus.control(s, 1);

        bus.set(maxFaderValue);
        self.buses.put(name.asSymbol, bus);
    };

    q.setupOSC = {|self|
        self.osc = NetAddr("127.0.0.1", 8000);
    };

    q.sendMessage = {|... args|
        var self = args[0];
        var msg = args[1..];

        self.osc.sendMsg(*msg);
    };

    q.makeSynthDefs = {|self|
        SynthDef(\lfo, {|out| 
            var lfo = LFDNoise3.kr(3).range(0, maxFaderValue);
            Out.kr(out, lfo);
        }).add;
    };

    q.readBusValues = {|self|
        Routine {
            inf.do {
                self.buses.do {|bus|
                    bus.get({|val|
                        self.sendMessage("/track/3/volume", val);
                    });
                };

                pollTime.wait;
            }
        }.play;
    };

    q.start = {|self|

    };

    q.cleanup = {|self|

    };

s.waitForBoot {
    q.init;
    s.sync;
    CmdPeriod.doOnce { q.cleanup; };
};
)



q.sendMessage

q.sendMessage("/track/3/volume", 0);

x = NetAddr("127.0.0.1", 8000);
x.sendMsg("/track/4/volume 0");

x.sendMsg("/track/3/volume", 0);


