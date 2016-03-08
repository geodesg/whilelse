function asyncAdd(a, b, callback) {
    return callback(a + b);
}
function whileExample(callback1) {
    var i = 0;
    var whileCont2 = function () {
        callback1(i);
    };
    var whileIter3 = function () {
        if (i < 5) {
            asyncAdd(i, 1, function (tmp4) {
                i = tmp4;
                console.log(i);
                whileIter3();
            });
        } else {
            whileCont2();
        }
    };
    whileIter3();
}