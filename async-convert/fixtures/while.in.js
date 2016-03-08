function asyncAdd(a, b, __ASYNC) {
    return callback(a + b);
}
function whileExample(__ASYNC) {
    var i = 0;
    while (i < 5) {
        i = __AWAIT(asyncAdd(i, 1));
        console.log(i);
    }
    return i;
}