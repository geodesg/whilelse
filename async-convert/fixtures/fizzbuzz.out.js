function aMod(a, m, callback) {
    setImmediate(function () {
        callback(a % m);
    });
}
function aConcat(a, b, callback) {
    setImmediate(function () {
        callback('' + a + b);
    });
}
function num_to_str(num) {
    return '' + num;
}
function aFizzbuzz(n, callback1) {
    var i = 0;
    var s = '';
    var r = [];
    var whileCont2 = function () {
        callback1(r);
    };
    var whileIter3 = function () {
        if (i < n) {
            i = i + 1;
            s = '';
            var ifCont4 = function () {
                var ifCont8 = function () {
                    var ifCont12 = function () {
                        r.push(s);
                        whileIter3();
                    };
                    if (s == '') {
                        s = num_to_str(s);
                        ifCont12();
                    } else {
                        ifCont12();
                    }
                };
                aMod(i, 5, function (tmp10) {
                    var tmp9 = tmp10 == 0;
                    if (tmp9) {
                        aConcat(s, 'Buzz', function (tmp11) {
                            s = tmp11;
                            ifCont8();
                        });
                    } else {
                        ifCont8();
                    }
                });
            };
            aMod(i, 3, function (tmp6) {
                var tmp5 = tmp6 == 0;
                if (tmp5) {
                    aConcat(s, 'Fizz', function (tmp7) {
                        s = tmp7;
                        ifCont4();
                    });
                } else {
                    ifCont4();
                }
            });
        } else {
            whileCont2();
        }
    };
    whileIter3();
}