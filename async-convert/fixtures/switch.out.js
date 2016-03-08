function asyncSwitch(n, callback1) {
    var negative = false;
    var switch2Cont = function () {
        var ifCont5 = function () {
            callback1();
        };
        if (negative) {
            callback1('NEGATIVE');
        } else {
            ifCont5();
        }
    };
    var tmp3 = n;
    var switch2Flag = false;
    var switch2Case0 = function () {
        callback1('one');
    };
    var switch2Case1 = function () {
        callback1('two');
    };
    var switch2Case2 = function () {
        var ifCont4 = function () {
            switch2Cont();
        };
        if (n > 0) {
            callback1('something else');
        } else {
            negative = true;
            ifCont4();
        }
    };
    if (tmp3 === 1) {
        switch2Case0();
    } else {
        if (tmp3 === 2) {
            switch2Case1();
        } else {
            switch2Case2();
        }
    }
}