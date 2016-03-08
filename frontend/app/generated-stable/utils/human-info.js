function repo() {
    return require('models/pig/common').repo;
}
var BNode = function () {
    BNode.displayName = 'BNode';
    var prototype = BNode.prototype;
    function BNode(el) {
        var this$ = this;
        if (this$.objectId)
            this$.objectId = generateObjectId();
        this$.el = el;
    }
    prototype.node = function node() {
        var this$ = this;
        var node;
        node = repo().node(this$.ni());
        if (!node) {
            throw 'node not found';
        } else
            null;
        return node;
    };
    prototype.ni = function ni() {
        var this$ = this;
        var ni;
        if (this$.el.length == 0) {
            throw 'node element blank';
        } else
            null;
        ni = this$.el.data('ni');
        if (!ni) {
            throw 'data.ni missing';
        } else
            null;
        return ni;
    };
    prototype.parent = function parent() {
        var this$ = this;
        var pEl;
        pEl = this$.el;
    };
    prototype.parentRef = function parentRef() {
        var this$ = this;
        var el;
        el = this$.el.closest('.posi-ref');
    };
    return BNode;
}();
var BAttrT = function () {
    BAttrT.displayName = 'BAttrT';
    var prototype = BAttrT.prototype;
    function BAttrT(el) {
        var this$ = this;
        if (this$.objectId)
            this$.objectId = generateObjectId();
        this$.el = el;
    }
    prototype.ati = function ati() {
        var this$ = this;
        var ati;
        ati = this$.el.data('ati');
        if (!ati) {
            throw 'data.ati not found';
        } else
            null;
        return ati;
    };
    prototype.typeNode = function typeNode() {
        var this$ = this;
        var type;
        type = repo().node(this$.ati());
        if (!type) {
            throw 'attr type node not found';
        } else
            null;
        return type;
    };
    prototype.parent = function parent() {
        var this$ = this;
        var el;
        el = this$.el.closest('.posi-node');
        if (!el) {
            throw 'no parent node found for attrt';
        } else
            null;
        return new BNode(el);
    };
    return BAttrT;
}();
var BAttr = function () {
    BAttr.displayName = 'BAttr';
    var prototype = BAttr.prototype;
    function BAttr(el) {
        var this$ = this;
        if (this$.objectId)
            this$.objectId = generateObjectId();
        this$.el = el;
    }
    prototype.attrt = function attrt() {
        var this$ = this;
        var attrtEl;
        attrtEl = this$.el.closest('.posi-attrt');
        if (!attrtEl) {
            throw 'posi-attrt not found';
        } else
            null;
        return new BAttrT(attrtEl);
    };
    prototype.typeNode = function typeNode() {
        var this$ = this;
        return this$.attrt().typeNode();
    };
    prototype.parent = function parent() {
        var this$ = this;
        return this$.attrt().parent();
    };
    return BAttr;
}();
module.exports = function () {
    function humanize(s) {
        return s;
    }
    function nodeTitle(node) {
        var s;
        s = '';
        if (node.name()) {
            s += '"' + node.name() + '" ';
        } else
            null;
        s += humanize(node.type().name());
        return s;
    }
    return function (elem) {
        var attr;
        var s = '';
        var bNode;
        var parentRef;
        var proptEl;
        var nodeEl;
        if (elem.hasClass('posi-node')) {
            bNode = new BNode(elem);
            s = nodeTitle(bNode.node());
            if (parentRef = bNode.node().parentRef()) {
                s += ', "';
                s += parentRef.type().name();
                s += '" property of ';
                s += nodeTitle(parentRef.source());
            } else
                null;
            return s;
        } else
            null;
        if (elem.hasClass('posi-attr')) {
            attr = new BAttr(elem);
            return attr.typeNode().name() + ' attribute of ' + nodeTitle(attr.parent().node());
        } else
            null;
        if (elem.hasClass('blank')) {
            s = 'blank';
            proptEl = elem.closest('.posi-propt');
            if (proptEl.length > 0) {
                nodeEl = proptEl.closest('.posi-node');
                bNode = new BNode(nodeEl);
                s += ' "';
                s += proptEl.data('name');
                s += '" property of ';
                s += nodeTitle(bNode.node());
                return s;
            } else
                null;
        } else
            null;
        return 'wip';
    };
}();