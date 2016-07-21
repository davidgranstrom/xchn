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
    }, "/master/eq/reset")
};

// return
{|self|
    createMasterResponders.(self);
};
