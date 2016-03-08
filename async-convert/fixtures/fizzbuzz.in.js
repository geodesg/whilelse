function aMod(a, m, __ASYNC) {
    setImmediate(function () {
        callback(a % m);
    });
}
function aConcat(a, b, __ASYNC) {
    setImmediate(function () {
        callback('' + a + b);
    });
}
function num_to_str(num) {
    return '' + num;
}
function aFizzbuzz(n, __ASYNC) {
    var i = 0;
    var s = '';
    var r = [];
    while (i < n) {
        i = i + 1;
        s = '';
        if (__AWAIT(aMod(i, 3)) == 0) {
            s = __AWAIT(aConcat(s, 'Fizz'));
        }
        if (__AWAIT(aMod(i, 5)) == 0) {
            s = __AWAIT(aConcat(s, 'Buzz'));
        }
        if (s == '') {
            s = num_to_str(s);
        }
        r.push(s);
    }
    return r;
}
