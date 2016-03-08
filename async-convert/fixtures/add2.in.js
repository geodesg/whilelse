function asyncAdd(a, b, __ASYNC) {
    return callback(a + b);
}
function asyncExample(__ASYNC) {
    console.log(__AWAIT(asyncAdd(1, 2)) + __AWAIT(asyncAdd(3, 4)));
}