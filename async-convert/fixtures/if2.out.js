function asyncAdd(a, b, callback) {
    return callback(a + b);
}
function if2Example(callback1) {
    var x = 0;
    var ifCont2 = function () {
        callback1(x);
    };
    asyncAdd(1, 2, function (tmp4) {
        var tmp3 = tmp4 < 4;
        if (tmp3) {
            asyncAdd(10, 11, function (tmp5) {
                x = tmp5;
                ifCont2();
            });
        } else {
            x = 20;
            ifCont2();
        }
    });
}