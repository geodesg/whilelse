var Promise = function () {
    Promise.displayName = 'Promise';
    var prototype = Promise.prototype;
    function Promise(raw) {
        var this$ = this;
        this$.raw = raw;
    }
    prototype.chain = function chain(d, opts) {
        var this$ = this;
        this$.done(function function_acriHt9LlVlb(result) {
            if (opts && opts['done']) {
                opts['done'](result);
            } else {
                d.resolve(result);
            }
        });
        this$.progress(function function_acLhcAzAbetT(result) {
            if (opts && opts['progress']) {
                opts['progress'](result);
            } else {
                d.notify(result);
            }
        });
        this$.fail(function function_acjI72MV5oXM(result) {
            if (opts && opts['fail']) {
                opts['fail'](result);
            } else {
                d.reject(result);
            }
        });
    };
    prototype.done = function done(f) {
        var this$ = this;
        this$.raw.done(f);
    };
    prototype.fail = function fail(f) {
        var this$ = this;
        this$.raw.fail(f);
    };
    prototype.progress = function progress(f) {
        var this$ = this;
        this$.raw.progress(f);
    };
    return Promise;
}();
function promise(cb) {
    var u;
    u = require('lib/utils');
    return new Promise(u.promise(cb));
}
var Unikey = function () {
    Unikey.displayName = 'Unikey';
    var prototype = Unikey.prototype;
    function Unikey() {
        var this$ = this;
        this$.raw = new (require('lib/unikey'))();
    }
    prototype.issue = function issue(name) {
        var this$ = this;
        return this$.raw.issue(name);
    };
    return Unikey;
}();
function xEach(collection, predicate) {
    var ret = [];
    for (i = 0; i < collection.length; i++) {
        ret.push(predicate(collection[i]));
    }
}
function repo() {
    return require('models/pig/common').repo;
}
function choose(arg) {
    return new Promise(require('ui').choose(arg));
}
module.exports = function () {
    var h;
    var actions;
    actions = require('modules/pig/node/actions');
    h = {
        selectAsTarget: function (arg) {
            var options = [];
            var unikey;
            var $el;
            $el = arg.$el;
            return promise(function function_acrhNPbdMfKA(d) {
                options = [];
                unikey = new Unikey();
                xEach([
                    '843',
                    '849',
                    '841',
                    '839',
                    '847',
                    962542,
                    962548
                ], function function_ac0lqejM3V0f(nodeId) {
                    var dataTypeNode;
                    dataTypeNode = repo().node(nodeId);
                    options.push({
                        _data_type: 'frontend/ui/choose/choose-option-struct_type',
                        key: unikey.issue(dataTypeNode.name()),
                        name: dataTypeNode.name(),
                        action: function () {
                            d.resolve({ target: repo().node(dataTypeNode.ni) });
                        }
                    });
                });
                xEach([
                    {
                        name: 'array',
                        type: 'array_type',
                        id: '855'
                    },
                    {
                        name: 'struct',
                        type: 'struct_type',
                        id: '6274'
                    },
                    {
                        name: 'enum',
                        type: 'enum_type',
                        id: '7311'
                    },
                    {
                        name: 'function',
                        type: 'function_type',
                        id: 'acMEzD5XxCyL'
                    },
                    {
                        name: 'hash with type',
                        type: 'hash_type',
                        id: 'acpEQrl95cnH'
                    },
                    {
                        name: 'box',
                        type: 'box',
                        id: 'acH2WpDR2dpN'
                    },
                    {
                        name: 'computed_box',
                        type: 'computed_box',
                        id: 'acTfBiQeUIbA'
                    }
                ], function function_acz8jJVYYz4R(item) {
                    options.push({
                        _data_type: 'frontend/ui/choose/choose-option-struct_type',
                        key: unikey.issue(item.name),
                        name: item.name,
                        action: function () {
                            d.resolve({ nodeType: repo().node(item.id) });
                        }
                    });
                });
                options.push({
                    _data_type: 'frontend/ui/choose/choose-option-struct_type',
                    key: '\\',
                    name: 'other',
                    action: function () {
                        actions.searchSelect({ type: repo().nodes['837'] }).done(function (dataType) {
                            d.resolve({ target: dataType });
                        });
                    }
                });
                choose({
                    _data_type: 'frontend/ui/choose/choose-param-struct_type',
                    $anchor: $el,
                    title: 'Select Type',
                    options: options
                }).chain(d);
            });
        }
    };
    return h;
}();