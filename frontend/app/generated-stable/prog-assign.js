function repo() {
    return require('models/pig/common').repo;
}
function posi() {
    return require('modules/pig/posi/main');
}
module.exports = function () {
    var h;
    return h = {
        'apply-surch-result': function (node, result) {
            return node.cAddLink(repo().nodes['820'], result.node);
        },
        'get-expr-type': function (node) {
            var rvalue;
            if (rvalue = node.rn(repo().nodes['4506'])) {
                posi().handlerFor(repo().nodes['911']).getExprType(rvalue);
            } else
                null;
        }
    };
}();