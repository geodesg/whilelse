function asyncAdd(a, b, __ASYNC) {
    return callback(a + b);
}
function if2Example(__ASYNC) {
    var x = 0;
    if (__AWAIT(asyncAdd(1, 2)) < 4) {
        x = __AWAIT(asyncAdd(10, 11));
    } else {
        x = 20;
    }
    return x;
}