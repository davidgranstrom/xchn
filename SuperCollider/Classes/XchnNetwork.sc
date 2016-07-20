XchnNetwork {
    classvar <>local;
    classvar <>remote;

    *new {
        ^super.new;
    }

    *disconnect {
        local !? { local.disconnect };
        remote !? { remote.disconnect };
    }

    sendToLocal {|... args|
        // "local: %: % %\n".postf(*args);
        local.sendMsg(*args);
    }

    sendToRemote {|... args|
        // "remote: %: % %\n".postf(*args);
        remote.sendMsg(*args);
    }
}
