function client() {
    return GLOBALS.redisClient = GLOBALS.redisClient || require('redis').createClient();
}
function set(key, value, callback) {
    return client().set(key, value, function (err, reply) {
        if (err)
            throw err;
        else
            callback(reply == 'OK');
    });
}
function get(key, callback) {
    return client().get(key, function (err, reply) {
        if (err)
            throw err;
        else
            callback(reply);
    });
}
function redisExample(callback1) {
    set('x', 'ahoi', function () {
        get('x', function (tmp2) {
            console.log(tmp2);
            callback1();
        });
    });
}