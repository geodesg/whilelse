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
var http = require('http');
var url = require('url');
var GLOBALS = {};
var port = parseInt(process.argv[2]);
function validateAndCoerceType(value, type) {
    return {
        valid: true,
        value: value
    };
}
function validateAndCoerce(value, spec, path) {
    switch (spec.type) {
    case 'string':
        return [
            true,
            value
        ];
    case 'integer':
        v = parseInt(value);
        if ('' + v == value) {
            return [
                true,
                v
            ];
        } else {
            return [
                false,
                [path + ' should be an integer']
            ];
        }
    case 'hash':
        if (Object.prototype.toString(value) == '[object Object]') {
            var coerced = {};
            var n = spec.fields.length;
            for (var i = 0; i < n; i++) {
                var name = spec.fields[i].name;
                var subspec = spec.fields[i].subtype;
                if (path.length > 0) {
                    subpath = path + '[' + name + ']';
                } else {
                    subpath = name;
                }
                r = validateAndCoerce(value[name], subspec, subpath);
                if (r[0] === false) {
                    return r;
                } else {
                    coerced[name] = r[1];
                }
            }
            return [
                true,
                coerced
            ];
        } else {
            return [
                false,
                [path + ' should be a hash']
            ];
        }
    default:
        return [
            false,
            ['can\'t handle ' + spec.type]
        ];
    }
}
var server = http.createServer(function (request, response) {
    var parsedUrl = url.parse(request.url, true);
    var coercedRequest;
    var requestParams = parsedUrl.query;
    var routeLine = request.method + ' ' + parsedUrl.pathname;
    console.log(routeLine, requestParams);
    switch (routeLine) {
    case 'GET /set':
        coercedRequest = [];
        var r = validateAndCoerce(requestParams, JSON.parse('{"type":"hash","fields":[{"name":"key","subtype":{"type":"string"}},{"name":"value","subtype":{"type":"string"}}]}'), '');
        if (r[0]) {
            for (name in r[1]) {
                var value = r[1][name];
                coercedRequest.push(value);
            }
        } else {
            response.writeHead(403, { 'Content-Type': 'application/json' });
            response.write(JSON.stringify({ error: { messages: r[1] } }));
            response.end('\n');
            return;
        }
        console.log('Coerced Request:', coercedRequest);
        var f = function function_acZ2dt7Ufav6(key, value, __ASYNC) {
            return __AWAIT(set(key, value));
        };
        var result = __AWAIT(f(coercedRequest[0], coercedRequest[1]));
        if (result._data_type == 'web/response-struct_type') {
            response.writeHead(result.status, result.headers);
            response.write(result.body);
        } else {
            content = JSON.stringify(result);
            console.log('Response: ', content);
            response.writeHead(200, { 'Content-Type': 'application/json' });
            response.write(content);
        }
        response.end('\n');
        return;
    case 'GET /get':
        coercedRequest = [];
        var r = validateAndCoerce(requestParams, JSON.parse('{"type":"hash","fields":[{"name":"key","subtype":{"type":"string"}}]}'), '');
        if (r[0]) {
            for (name in r[1]) {
                var value = r[1][name];
                coercedRequest.push(value);
            }
        } else {
            response.writeHead(403, { 'Content-Type': 'application/json' });
            response.write(JSON.stringify({ error: { messages: r[1] } }));
            response.end('\n');
            return;
        }
        console.log('Coerced Request:', coercedRequest);
        var f = function function_acH0mm5HDAtC(key, __ASYNC) {
            return __AWAIT(get(key));
        };
        var result = __AWAIT(f(coercedRequest[0]));
        if (result._data_type == 'web/response-struct_type') {
            response.writeHead(result.status, result.headers);
            response.write(result.body);
        } else {
            content = JSON.stringify(result);
            console.log('Response: ', content);
            response.writeHead(200, { 'Content-Type': 'application/json' });
            response.write(content);
        }
        response.end('\n');
        return;
    default:
        response.writeHead(404, { 'Content-Type': 'application/json' });
        response.write('{"error":{"message":"Not Found"}}');
        response.end('\n');
        return;
    }
});
server.listen(port);