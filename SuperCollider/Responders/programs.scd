var randMute = {|self|
    var numCandidates = 1;
    var waitTime = 1;
    var spec = ControlSpec(0, 1, \lin, 1, 0);

    var tracks = [
        // (listen: '/group1/mute/L', send: '/track/2/mute'),
        // (listen: '/group1/mute/R', send: '/track/3/mute'),

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

        (listen: '/group8/mute/L', send: '/track/23/mute'),
        (listen: '/group8/mute/R', send: '/track/24/mute'),
    ];

    var units = tracks.collect {|params|
        XchnUnitState(
            params.listen,
            params.send,
            spec
        );
    };

    var muteAlgoPlaying = false;
    var seqAlgoPlaying = false;
    var activeRoutines = List[];

    var candidates = Pxrand(units, inf).asStream;
    var seqCandidates = Pseq(units, inf).asStream;
    var createRoutine = {|pattern, timingOffset=0|
        Routine {
            loop {
                var unit = pattern.next;
                unit.value = 1;
                (waitTime + timingOffset).wait;
                unit.value = 0;
            };
        };
    };

    var resetAllRoutines = {
        activeRoutines.do {|r| r.stop; };
        activeRoutines = List[];
        // reset all mutes
        units.do {|unit|
            unit.value = 0;
        };
    };

    OSCdef(\muteAlgo, {|msg|
        if (msg[1] == 1) {
            if (seqAlgoPlaying) {
                resetAllRoutines.();
                seqAlgoPlaying = false;
                XchnNetwork.remote.sendMsg("/muteAlgoSeq/toggle", 0);
            };

            numCandidates.do {|i|
                var routine = createRoutine.(candidates, i * rrand(0.1, 0.5));
                routine.play;
                activeRoutines.add(routine);
            };
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

    OSCdef(\muteAlgoCandidates, {|msg|
        var num = msg[1].linlin(0, 1, 1, 4).floor;
        numCandidates = num;
    }, "/muteAlgo/candidates");
};

// var bloom = {|self|
//     var lfos = ();
//     var spec = ControlSpec(0, 0.716, \lin, 0, 0.716); // 0.716 is 0dB in Reaper
//     var units = self.all.absolute.copy;
//     // don't assign "group 1" (master)
//     units.removeAt('/group1/abs/volume')

//     var routine = Routine {
//         loop {
//            var chosen = units.choose;
//            var others = units.reject {|unit| unit.key == chosen.key };
//            var condition = Condition.new;

//            fork {

//            }
//         }
//     }

// };

var createResponders = {|self|
    randMute.(self);
};

// return
{|self|
    createResponders.(self);
}
