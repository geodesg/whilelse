function repo() {
    return require('models/pig/common').repo;
}
function utils() {
    return require('lib/utils');
}
function optionalModule(m) {
    return utils().optionalModule('modules/pig/posi/' + m);
}
function handlerFor(type) {
    if (!type) {
        throw 'no type given to handler-for';
    } else
        null;
    return optionalModule('noco/' + type.sourceName());
}
function isComposedType(typeNode) {
    return typeNode.type() != repo().nodes['851'];
}
function composerTypeHandler(typeNode) {
    if (isComposedType(typeNode)) {
        return handlerFor(typeNode.type());
    } else
        null;
}
function getExprType(node) {
    var handler;
    var hGetExprType;
    var nominalType;
    var typeHandler;
    var getEffectiveType;
    handler = handlerFor(node.type());
    if (handler && (hGetExprType = handler.getExprType)) {
        if (nominalType = hGetExprType(node)) {
            typeHandler = composerTypeHandler(nominalType);
            if (getEffectiveType = typeHandler && typeHandler.getEffectiveType) {
                return getEffectiveType(nominalType);
            } else {
                return nominalType;
            }
        } else
            null;
    } else
        null;
}
module.exports = function () {
    var h;
    return h = {
        applySurchResult: function (node, result) {
            node.cAddLink(repo().nodes['820'], result.node);
        },
        getExprType: function (node) {
            var lvalue;
            if (lvalue = node.rn(repo().nodes['4504'])) {
                return getExprType(lvalue);
            } else
                null;
        }
    };
}();