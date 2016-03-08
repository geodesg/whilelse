function asyncAdd(a, b, callback) {
    return callback(a + b);
}
function asyncExample(callback1) {
    asyncAdd(1, 2, function (tmp3) {
        asyncAdd(3, 4, function (tmp4) {
            var tmp2 = tmp3 + tmp4;
            console.log(tmp2);
            callback1();
        });
    });
}