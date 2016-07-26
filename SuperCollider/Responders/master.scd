var createMasterResponders;

createMasterResponders = {|self|
    var eq, volume, volumeUnit;

    eq = [
        (
            listen: "/master/eq/low",
            send: "/master/eq/low",
            spec: ControlSpec(0, 0.5, \lin, default: 0) // 10Hz - 547Hz
        ),
        (
            listen: "/master/eq/lowmid",
            send: "/master/eq/lowmid",
            spec: ControlSpec(0.3, 0.5, \lin, default: 0.5) // 0, -12
        ),
        (
            listen: "/master/eq/highmid",
            send: "/master/eq/highmid",
            spec: ControlSpec(0.3, 0.5, \lin, default: 0.5) // 0, -12
        ),
        (
            listen: "/master/eq/high",
            send: "/master/eq/high",
            spec: ControlSpec(0.5, 1, \lin, default: 1) // 547Hz - 30kHz
        ),
        (
            listen: "/master/eq/lowshelf",
            send: "/master/eq/lowshelf",
            spec: ControlSpec(0.3, 0.55, \lin, default: 0.5)
        ),
        (
            listen: "/master/eq/highshelf",
            send: "/master/eq/highshelf",
            spec: ControlSpec(0.3, 0.55, \lin, default: 0.5)
        )
    ];

    volume = (
        listen: "/master/volume",
        send: "/master/volume",
        spec: ControlSpec(0, 0.716, \lin, 0, 0)
    );

    eq.do {|params|
        var unit;

        self.all.master.eq.put(
            params.listen.asSymbol,
            unit = XchnUnitState(
                params.listen,
                params.send,
                params.spec
            )
        );

        OSCdef(params.listen.asSymbol, {|msg|
            unit.remoteValue = msg[1];
        }, params.listen);
    };

    self.all.master.put(
        volume.listen.asSymbol,
        volumeUnit = XchnUnitState(
            volume.listen,
            volume.send,
            volume.spec
        )
    );

    OSCdef(volume.listen.asSymbol, {|msg|
        volumeUnit.remoteValue = msg[1];
    }, volume.listen);

    // eq reset button
    OSCdef('/master/eq/reset', {|msg|
        self.all.master.eq.values.do {|unit|
            var spec = unit.controlSpec;
            unit.value = spec.unmap(spec.default);
        }
    }, "/master/eq/reset");

    OSCdef('/master/eq/shelf/reset', {|msg|
        var lowUnit = self.all.master.eq['/master/eq/lowshelf'];
        var highUnit = self.all.master.eq['/master/eq/highshelf'];
        var lowSpec = lowUnit.controlSpec;
        var highSpec = highUnit.controlSpec;

        lowUnit.value = lowSpec.unmap(lowSpec.default);
        highUnit.value = highSpec.unmap(highSpec.default);

    }, "/master/eq/shelf/reset");
};

// return
{|self|
    createMasterResponders.(self);
};
