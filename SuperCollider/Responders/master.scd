var createMasterResponders;

createMasterResponders = {|self|
    var eqDefault = (spec: ControlSpec(0, 1, \lin, 0, 0.5));
    var eq, volume, volumeUnit;

    eq = [
        (listen: "/master/eq/low", send: "/master/eq/low"),
        (listen: "/master/eq/lowmid", send: "/master/eq/lowmid"),
        (listen: "/master/eq/highmid", send: "/master/eq/highmid"),
        (listen: "/master/eq/high", send: "/master/eq/high"),
    ];

    volume = (
        listen: "/master/volume",
        send: "/master/volume",
        spec: ControlSpec(0, 0.716, \lin, 0, 0)
    );

    eq.do {|params|
        var unit;

        params.parent_(eqDefault);

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
        // var unit = self.all.master[volume.listen.asSymbol];
        volumeUnit.remoteValue = msg[1];
    }, volume.listen);

    // eq reset button
    OSCdef('/master/eq/reset', {|msg|
        self.all.master.eq.do {|unit|
            unit.value = unit.controlSpec.default;
        }
    }, "/master/eq/reset")
};

// return
{|self|
    createMasterResponders.(self);
};
