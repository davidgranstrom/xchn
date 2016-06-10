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

    sendToLocal {|addr, msg, forwardToRemote=false|
        "network: %: %\n".postf(addr, msg);
        localAddress.sendMsg(addr, msg);
        if(forwardToRemote) {
            this.sendToRemote(addr, msg);
        }
    }

    sendToRemote {|addr, msg|
        remoteAddress.sendMsg(addr, msg);
    }
}
