function client() {
    return GLOBALS.redisClient = GLOBALS.redisClient || require('redis').createClient();
}
function set(key, value, __ASYNC) {
    return client().set(key, value, function (err, reply) {
        if (err)
            throw err;
        else
            callback(reply == 'OK');
    });
}
function get(key, __ASYNC) {
    return client().get(key, function (err, reply) {
        if (err)
            throw err;
        else
            callback(reply);
    });
}
function redisExample(__ASYNC) {
    __AWAIT(set('x', 'ahoi'));
    console.log(__AWAIT(get('x')));
}