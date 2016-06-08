(
    var trackNo1 = 3;
    var maxFaderValue = 0.707;
    var pollTime = 1/25; // poll interval for server side LFO's

    var localAddress = "127.0.0.1"; // address to Reaper
    var localPort = 8000;
    var remoteAddress = "192.168.0.2"; // address to iOS device
    var remotePort = 9000;

    q = q ? ();
    q.dispatcher = ();

    // This callback can be called by LFO which will 
    q.dispatcher.fxSelect = {|self, channel, value|
        var x = controller.fxSelect.x;
        var y = controller.fxSelect.y;

        self.sendToReaper("/input/%/L/fx-select/x".format(channel), x);
        self.sendToReaper("/input/%/L/fx-select/y".format(channel), y);
        self.sendToReaper("/input/%/R/fx-select/x".format(channel), x);
        self.sendToReaper("/input/%/R/fx-select/y".format(channel), y);
    };

    q.init = {|self|
        self.setupOSC();
        self.buses = ();

        // self.createBuses();
        s.sync;
        self.makeSynthDefs();
        s.sync;

        10.do {|i|
            var id = ("lfo" ++ i).asSymbol;
            var freq = 1/2;
            self.createBus(id);
            Synth(\lfo, [\out, self.buses[id], \freq, freq]);
        };

        self.readBusValues();
    };

    q.createBus = {|self, name|
        var bus = Bus.control(s, 1);

        bus.set(maxFaderValue);
        self.buses.put(name.asSymbol, bus);
    };

    q.setupOSC = {|self|
        self.oscReaper = NetAddr(localAddress, localPort);
        self.oscRemoteSend = NetAddr(remoteAddress, remotePort);
    };

    q.sendToReaper = {|... args|
        var self = args[0];
        var msg = args[1..];

        self.oscReaper.sendMsg(*msg);
    };

    q.makeSynthDefs = {|self|
        SynthDef(\lfo, {|out, phase=0, freq|
            var lfo = SinOsc.kr(SinOsc.kr(1/3, Rand(0, 2pi)).range(freq, 2*freq), phase).range(0, maxFaderValue);
            Out.kr(out, lfo);
        }).add;
    };

    q.readBusValues = {|self|
        Routine {
            inf.do {
                self.buses.do {|bus, i|
                    bus.get({|val|
                        // self.sendToReaper("/track/%/volume".format(i + trackNo1), val);
                        self.oscRemoteSend.sendMsg("/1/multifader1/%".format(i + 1), val);
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


plot { SinOsc.ar }

NetAddr.langPort;

OSCFunc.trace(false);

n = NetAddr("192.168.0.2", 9000);

n.sendMsg("/1/multifader1/1", 0.5);
n.sendMsg("/1/group/1/volume", 0);
n.sendMsg("/1/chan/1/volume", 0);

(
    OSCdef(\multifader1, {|... args|
        args.postln;
    }, '/1/multifader4/1');
)


SendReply


n = NetAddr("127.0.0.1", 8000);


OSCFunc.trace(false);
OSCFunc.trace(true);


x = Xchn();

y = XchnSingleUnit();
y.listenAddress = '/1/mainout';

OSCdef('mainout', {|msg|
    y.send = msg;
},)


