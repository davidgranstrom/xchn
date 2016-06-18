var createMasterResponders;

createMasterResponders = {|self|
    var eqDefault = (spec: ControlSpec(0, 1, \lin, 0, 0.5));
    var eq, volume, label;

    eq = [
        (address: '/master/eq/low'),
        (address: '/master/eq/lowmid'),
        (address: '/master/eq/highmid'),
        (address: '/master/eq/high'),
    ];

    volume = (
        address: '/master/volume',
        spec: ControlSpec(0, 0.716, \lin, 0, 0)
    );

    eq.do {|params|
        var addr = params.address;
        params.parent_(eqDefault);
        self.all.master.eq.put(addr, XchnUnitState(addr, addr, params.spec));
    };

    self.all.master.put(
        volume.address,
        XchnUnitState(
            volume.address,
            volume.address,
            volume.spec
        )
    );

    OSCdef(volume.address, {|msg|
        var unit = self.all.master[volume.address];
        unit.remoteValue = msg[1];
    }, volume.address);

    // eq reset button
    OSCdef('/master/eq/reset', {|msg|
        self.all.master.eq.do {|unit|
            unit.value = eqDefault.spec.default;
        }
    }, '/master/eq/reset')
};

// return
{|self|
    createMasterResponders.(self);
};
