function asyncAdd(a, b, __ASYNC) {
    return callback(a + b);
}
function ifExample(__ASYNC) {
    if (__AWAIT(asyncAdd(1, 2)) < 4) {
        return __AWAIT(asyncAdd(3, 4));
    } else {
        return __AWAIT(asyncAdd(5, 6));
    }
}