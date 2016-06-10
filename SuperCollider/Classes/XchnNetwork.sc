XchnNetwork {
    classvar <>localAddress;
    classvar <>remoteAddress;

    *new {
        ^super.new;
    }

    *disconnect {
        localAddress !? { localAddress.disconnect };
        remoteAddress !? { remoteAddress.disconnect };
    }

    sendToLocal {|... args|
        "local: %: % %\n".postf(*args);
        localAddress.sendMsg(*args);
    }

    sendToRemote {|... args|
        "remote: %: % %\n".postf(*args);
        remoteAddress.sendMsg(*args);
    }
}
