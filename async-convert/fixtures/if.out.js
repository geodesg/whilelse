function asyncAdd(a, b, callback) {
    return callback(a + b);
}
function ifExample(callback1) {
    var ifCont2 = function () {
        callback1();
    };
    asyncAdd(1, 2, function (tmp4) {
        var tmp3 = tmp4 < 4;
        if (tmp3) {
            asyncAdd(3, 4, function (tmp5) {
                callback1(tmp5);
            });
        } else {
            asyncAdd(5, 6, function (tmp6) {
                callback1(tmp6);
            });
        }
    });
}