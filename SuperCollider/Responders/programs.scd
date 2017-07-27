// Random/sequential mute program
var randMute = {|self|
    var units, candidates, seqCandidates, createRoutine;
    var resetAllRoutines, runMuteAlgo;

    var numCandidates = 1;
    var waitTime = 1;
    var muteAlgoPlaying = false;
    var seqAlgoPlaying = false;
    var activeRoutines = List[];

    var spec = ControlSpec(0, 1, \lin, 1, 0);
    var tracks = [
        (listen: '/group1/mute/L', send: '/track/2/mute'),
        (listen: '/group1/mute/R', send: '/track/3/mute'),

        (listen: '/group2/mute/L', send: '/track/5/mute'),
        (listen: '/group2/mute/R', send: '/track/6/mute'),

        (listen: '/group3/mute/L', send: '/track/8/mute'),
        (listen: '/group3/mute/R', send: '/track/9/mute'),

        (listen: '/group4/mute/L', send: '/track/11/mute'),
        (listen: '/group4/mute/R', send: '/track/12/mute'),

        (listen: '/group5/mute/L', send: '/track/14/mute'),
        (listen: '/group5/mute/R', send: '/track/15/mute'),

        (listen: '/group6/mute/L', send: '/track/17/mute'),
        (listen: '/group6/mute/R', send: '/track/18/mute'),

        (listen: '/group7/mute/L', send: '/track/20/mute'),
        (listen: '/group7/mute/R', send: '/track/21/mute'),

        // (listen: '/group8/mute/L', send: '/track/23/mute'),
        // (listen: '/group8/mute/R', send: '/track/24/mute'),
    ];

    units = tracks.collect {|params|
        var unit = XchnUnitState(
            params.listen,
            params.send,
            spec
        );

        self.addToCleanup(
            OSCFunc({|msg|
                var val = msg[1];
                unit.remoteValue = val;
            }, params.listen)
        );

        unit;
    };

    // remove master channels from candidates
    units.removeAt(0); // channel 1
    units.removeAt(0); // channel 2

    candidates = Pxrand(units, inf).asStream;
    seqCandidates = Pseq(units, inf).asStream;
    createRoutine = {|pattern, timingOffset=0|
        Routine {
            loop {
                var unit = pattern.next;
                unit.value = 1;
                (waitTime + timingOffset).wait;
                unit.value = 0;
            };
        };
    };

    resetAllRoutines = {
        activeRoutines.do {|r| r.stop; };
        activeRoutines = List[];
        // reset all mutes
        units.do {|unit|
            unit.value = 0;
        };
    };

    runMuteAlgo = {
        numCandidates.do {|i|
            var routine = createRoutine.(candidates, i * rrand(0.1, 0.5));
            routine.play;
            activeRoutines.add(routine);
        };
    };

    OSCdef(\muteAlgo, {|msg|
        if (msg[1] == 1) {
            if (seqAlgoPlaying) {
                resetAllRoutines.();
                seqAlgoPlaying = false;
                XchnNetwork.remote.sendMsg("/muteAlgoSeq/toggle", 0);
            };

            runMuteAlgo.();
            muteAlgoPlaying = true;
        } {
            resetAllRoutines.();
            muteAlgoPlaying = false;
        }
    }, "/muteAlgo/toggle");

    OSCdef(\muteAlgoSeq, {|msg|
        if (msg[1] == 1) {
            var routine;

            if (muteAlgoPlaying) {
                resetAllRoutines.();
                muteAlgoPlaying = false;
                XchnNetwork.remote.sendMsg("/muteAlgo/toggle", 0);
            };

            routine = createRoutine.(seqCandidates, 0);
            routine.play;
            activeRoutines.add(routine);
            seqAlgoPlaying = true;
        } {
            resetAllRoutines.();
            seqAlgoPlaying = false;
        }
    }, "/muteAlgoSeq/toggle");

    OSCdef(\muteAlgoRate, {|msg|
        var rate = msg[1].linexp(0, 1, 2, 0.08);
        waitTime = rate;
    }, "/muteAlgo/rate");

    // 1 - 4 candidates in parallel
    4.do {|i|
        i = i + 1;
        OSCdef(("muteAlgoCandidates" ++ i).asSymbol, {|msg|
            if (msg[1] == 1) {
                numCandidates = i;
                if (muteAlgoPlaying) {
                    resetAllRoutines.();
                    runMuteAlgo.();
                }
            }
        }, "/muteAlgo/candidates/%/1".format(i));
    };

    // initialize remote controller
    XchnNetwork.remote.sendMsg("/muteAlgo/candidates/1/1", 1);
};

var bloom = {|self|
    var units, spawnThread, routine;
    var updateInterval = 1/25;
    var activeThreads = List[];

    var spec = ControlSpec(0, 0.716, \lin, 0, 0.716); // 0.716 is 0dB in Reaper
    var tracks = [
        (listen: '/bloom/1', send: '/track/25/volume'),
        (listen: "/bloom/2", send: "/track/26/volume"),
        (listen: "/bloom/3", send: "/track/27/volume"),
        (listen: "/bloom/4", send: "/track/28/volume"),
        (listen: "/bloom/5", send: "/track/29/volume"),
        (listen: "/bloom/6", send: "/track/30/volume"),
        (listen: "/bloom/7", send: "/track/31/volume"),
        // (listen: "/bloom/8", send: "/track/32/volume"),
    ];

    units = tracks.collect {|params|
        var unit = XchnUnitState(
            params.listen,
            params.send,
            spec
        );

        self.addToCleanup(
            OSCFunc({|msg|
                var val = msg[1];
                unit.remoteValue = val;
            }, params.listen)
        );

        unit;
    };

    // remove master group from candidates
    units.removeAt(0);

    spawnThread = {|unit, startVal=1, endVal=0|
        var ref = Ref(1);
        var duration = rrand(20.0, 60.0);
        var t = fork {
            var val, env = Env([ startVal, endVal ], [ duration ], \lin).asStream;
            while { (val = env.next) != endVal } {
                unit.value = val;
                updateInterval.wait;
            };
            // we might not reach endVal exactly before the loop is terminated
            unit.value = endVal;
            ref.value = 0;
        };
        activeThreads.add(t);
        // return the ref so we can know when the thread is finished
        ref;
    };

    routine = Routine {
        loop {
            var others = units.copy;
            var chosen = others.takeAt(rrand(0, others.size - 1));
            var condition = Condition.new;
            var threads;
            // start fading out
            threads = others.collect {|unit| spawnThread.(unit, unit.value, 0) };
            fork {
                while { threads.collect {|ref| ref.value }.sum != 0 } {
                    // loop here until we know all threads are finished
                    updateInterval.wait;
                };
                // remove all saved threads
                activeThreads = List[];
                // return control back to main routine
                condition.unhang;
            };
            condition.hang;
            // wait a little before going back up
            rrand(1.0, 5.0).wait;
            // start fading up
            threads = others.collect {|unit| spawnThread.(unit, 0, 1) };
            fork {
                while { threads.collect {|ref| ref.value }.sum != 0 } {
                    // loop here until we know all threads are finished
                    updateInterval.wait;
                };
                // remove all saved threads
                activeThreads = List[];
                // return control back to main routine
                condition.unhang;
            };
            condition.hang;
        };
    };

    OSCdef(\bloomAlgo, {|msg|
        if (msg[1] == 1) {
            routine.reset;
            routine.play;
        } {
            activeThreads.do(_.stop);
            activeThreads = List[];
            routine.stop;
        }
    }, "/bloomAlgo/toggle");
};

// return
{|self|
    randMute.(self);
    bloom.(self);
}
