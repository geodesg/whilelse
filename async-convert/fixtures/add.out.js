function asyncAdd(a, b, callback) {
    return callback(a + b);
}
function asyncExample(callback1) {
    asyncAdd(1, 2, function (tmp2) {
        console.log(tmp2);
        callback1();
    });
}