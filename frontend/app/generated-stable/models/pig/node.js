function box() {
    return require('lib/box').box.apply(this, arguments);
}
function compute() {
    return require('lib/box').compute.apply(this, arguments);
}
function filter(collection, predicate) {
    var ret = [];
    for (i = 0; i < collection.length; i++) {
        if (predicate(collection[i]))
            ret.push(collection[i]);
    }
    return ret;
}
function map(collection, predicate) {
    var ret = [];
    for (i = 0; i < collection.length; i++) {
        ret.push(predicate(collection[i]));
    }
    return ret;
}
function repo() {
    return require('models/pig/common').repo;
}
function each(collection, predicate) {
    var ret = [];
    for (i = 0; i < collection.length; i++) {
        ret.push(predicate(collection[i]));
    }
}
function in$(needle, haystack) {
    return haystack.indexOf(needle) != -1;
}
function push(list, item) {
    list.push(item);
}
function addRefToList(list, ref, beforeRef) {
    var index;
    if (beforeRef) {
        index = list.indexOf(beforeRef);
        if (index == -1) {
            throw 'before-ref not found in ref list';
        } else
            null;
        list.splice(index, 0, ref);
    } else {
        list.push(ref);
    }
    return list;
}
function rmRefFromList(list, ref) {
    var index;
    index = list.indexOf(ref);
    if (index == -1) {
        throw 'ref not found in reflist';
    } else
        null;
    list.splice(index, 1);
    return list;
}
function pig() {
    return require('models/pig');
}
function pushUndo(ctyp, args) {
    pig().pushUndo(ctyp, args);
}
function command(ctyp, args) {
    pig().command(ctyp, args);
}
function applyPointy(ctyp, args) {
    return pig().applyPointy(ctyp, args);
}
function issueNewId(repo) {
    return pig().issueNewId(repo);
}
function activity(name, cb) {
    return pig().activity(name, cb);
}
function deepCopyContents(old, young) {
    var ati, ref$, val, i$, len$, ref, target, newChild, results$ = [];
    for (ati in ref$ = old.attrs()) {
        val = ref$[ati];
        console.log(ati, old.repo.nodes[ati]);
        young.cSetAttr(old.repo.nodes[ati], val);
    }
    for (i$ = 0, len$ = (ref$ = old.refs()).length; i$ < len$; ++i$) {
        ref = ref$[i$];
        target = ref.target() || fn$();
        if (ref.dep()) {
            newChild = young.cAddComponent(ref.type(), target.type(), target.name());
            results$.push(deepCopyContents(target, newChild));
        } else {
            results$.push(young.cAddLink(ref.type(), target));
        }
    }
    return results$;
    function fn$() {
        throw 'ref target not found';
    }
}
function find(collection, predicate) {
    var i = 0;
    for (i = 0; i < collection.length; i++) {
        if (predicate(collection[i])) {
            return collection[i];
        } else
            null;
    }
    return null;
}
function eachPair(hash, cb) {
    var key, value, results = [];
    for (key in hash) {
        value = hash[key];
        results.push(cb(key, value));
    }
    return results;
}
var Attr = function () {
    Attr.displayName = 'Attr';
    var prototype = Attr.prototype;
    function Attr(ati, type, value) {
        var this$ = this;
        this$.objectId = generateObjectId();
        this$.ati = ati;
        this$._type = type;
        this$._value = value;
    }
    prototype.type = function type() {
        var this$ = this;
        return this$._type;
    };
    prototype.value = function value() {
        var this$ = this;
        return this$._value;
    };
    return Attr;
}();
function concat(concatee, concated) {
    if (Object.prototype.toString.call(concatee) == '[object Array]') {
        return concatee.concat(concated);
    } else {
        return '' + concatee + concated;
    }
}
module.exports = function () {
    var Node = function () {
        Node.displayName = 'Node';
        var prototype = Node.prototype;
        function Node(repo, ni, nti, name, attrs, refRiList, inrefRiList) {
            var this$ = this;
            this$.objectId = generateObjectId();
            this$.name$box = box(this$.objectId + '-acRHRpeUbQVz', undefined);
            this$.attrs$box = box(this$.objectId + '-acqTUkMIKZCp', undefined);
            this$.refs$box = box(this$.objectId + '-achjao46dQSn', undefined);
            this$.inrefs$box = box(this$.objectId + '-ac2t7W8QwsZX', undefined);
            this$.type$box = box(this$.objectId + '-ach9omC01jfH', undefined);
            this$.parentRef$box = box(this$.objectId + '-acQF5QNTdek1', undefined);
            this$.parent$box = box(this$.objectId + '-acviugs20aHJ', undefined);
            this$.attrList$box = box(this$.objectId + '-actWa2fPvnFe', undefined);
            this$.ancestors$box = box(this$.objectId + '-ac5818wAoM9c', undefined);
            this$.sourceName$box = box(this$.objectId + '-acTycs0hJy6R', undefined);
            this$.inspect$box = box(this$.objectId + '-acucVYm3fEK3', undefined);
            this$.crumbs$box = box(this$.objectId + '-acuVP4RwhC0p', undefined);
            this$.fq$box = box(this$.objectId + '-accefErHYV0k', undefined);
            this$.schema$box = box(this$.objectId + '-ac84f2oWzxS1', undefined);
            this$.superType$box = box(this$.objectId + '-acG4dyEbWx23', undefined);
            function generateObjectId() {
                return 'node-' + ni;
            }
            this$.repo = repo;
            this$.ni = ni;
            this$.objectId = 'node-' + ni;
            this$.nti = nti;
            this$.name$set(name);
            this$.attrs$set(attrs || {});
            this$.refRiList = refRiList || [];
            this$.inrefRiList = inrefRiList || [];
            repo.nodes[ni] = this$;
        }
        prototype.closestAncestorOfType = function closestAncestorOfType(type, includeSelf) {
            var this$ = this;
            var iterNode;
            iterNode = this$;
            if (includeSelf && iterNode.type() == type) {
                return iterNode;
            } else
                null;
            while (iterNode = iterNode.parent()) {
                if (iterNode.type() == type) {
                    return iterNode;
                } else
                    null;
            }
        };
        prototype.refsWithType = function refsWithType(type) {
            var this$ = this;
            return filter(this$.refs(), function (ref) {
                return ref.type() == type;
            });
        };
        prototype.refWithType = function refWithType(type) {
            var this$ = this;
            return this$.refsWithType(type)[0];
        };
        prototype.rn = function rn(type) {
            var this$ = this;
            var ref;
            if (ref = this$.refWithType(type)) {
                return ref.target();
            } else
                null;
        };
        prototype.rns = function rns(type) {
            var this$ = this;
            return map(this$.refsWithType(type), function (ref) {
                return ref.target();
            });
        };
        prototype.inrefsWithType = function inrefsWithType(type) {
            var this$ = this;
            return filter(this$.inrefs(), function (ref) {
                return ref.type() == type;
            });
        };
        prototype.inrefNodesWithType = function inrefNodesWithType(type) {
            var this$ = this;
            return map(this$.inrefsWithType(type), function (ref) {
                return ref.source();
            });
        };
        prototype.isSubtypeOf = function isSubtypeOf(testType) {
            var this$ = this;
            var iterType;
            if (this$.type() == repo().nodes['1']) {
                iterType = this$;
                while (iterType) {
                    if (iterType == testType) {
                        return true;
                    } else
                        null;
                    iterType = iterType.superType();
                }
                return false;
            } else
                null;
        };
        prototype.isA = function isA(testType) {
            var this$ = this;
            return this$.type().isSubtypeOf(testType);
        };
        prototype.compatibleTypes = function compatibleTypes() {
            var this$ = this;
            var list;
            var expandList;
            var expandee;
            var directSubtypes;
            if (this$.type() == repo().nodes['1']) {
                list = [this$];
                expandList = [this$];
                while (expandList.length > 0) {
                    expandee = expandList.shift();
                    directSubtypes = map(expandee.inrefsWithType(repo().nodes['386']), function (r) {
                        return r.source();
                    });
                    each(directSubtypes, function function_acIVEAnYskrW(subtype) {
                        if (!in$(subtype, list)) {
                            push(list, subtype);
                            push(expandList, subtype);
                        } else
                            null;
                    });
                    each(expandee.rns(repo().nodes['ac1YxsKHnFEL']), function function_acYSluH1bQqg(subtype) {
                        if (!in$(subtype, list)) {
                            push(list, subtype);
                            push(expandList, subtype);
                        } else
                            null;
                    });
                }
                return list;
            } else {
                throw 'compatibleTypes only avalable for node types';
            }
        };
        prototype.a = function a(attrType) {
            var this$ = this;
            if (!attrType) {
                throw 'no attr type given';
            } else
                null;
            if (attrType == repo().nodes['5']) {
                return this$.name();
            } else {
                return this$.attrs()[attrType.ni];
            }
        };
        prototype.nearbySibling = function nearbySibling(direction) {
            var this$ = this;
            var children = [];
            var i;
            children = this$.parent().rns(this$.parentRef().type());
            i = children.indexOf(this$);
            if (i == -1) {
                throw 'Couldn\'t find node among the children of its parent';
            } else
                null;
            return children[i + direction];
        };
        prototype.nextSibling = function nextSibling() {
            var this$ = this;
            return this$.nearbySibling(1);
        };
        prototype.prevSibling = function prevSibling() {
            var this$ = this;
            return this$.nearbySibling(-1);
        };
        prototype.setName = function setName(name) {
            var this$ = this;
            this$.name$set(name);
        };
        prototype.addRef = function addRef(ref, beforeRef) {
            var this$ = this;
            this$.refs$set(addRefToList(this$.refs(), ref, beforeRef));
        };
        prototype.addInref = function addInref(ref) {
            var this$ = this;
            this$.inrefs$set(addRefToList(this$.inrefs(), ref, null));
        };
        prototype.rmRef = function rmRef(ref) {
            var this$ = this;
            this$.refs$set(rmRefFromList(this$.refs(), ref));
        };
        prototype.rmInref = function rmInref(ref) {
            var this$ = this;
            this$.inrefs$set(rmRefFromList(this$.inrefs(), ref));
        };
        prototype.setType = function setType(type) {
            var this$ = this;
            this$.type$set(type);
        };
        prototype.setAttr = function setAttr(type, value) {
            var this$ = this;
            var a;
            a = this$.attrs();
            if (value != null && value != undefined) {
                a[type.ni] = value;
            } else {
                delete a[type.ni];
            }
            this$.attrs$set(a);
        };
        prototype.cSetName = function cSetName(name) {
            var this$ = this;
            pushUndo('name', {
                ni: this$.ni,
                name: this$.name()
            });
            command('name', {
                ni: this$.ni,
                name: name
            });
            applyPointy('name', {
                node: this$,
                name: name
            });
        };
        prototype.cSetType = function cSetType(nodeType) {
            var this$ = this;
            pushUndo('ntyp', {
                ni: this$.ni,
                nti: this$.type().ni
            });
            command('ntyp', {
                ni: this$.ni,
                nti: nodeType.ni
            });
            applyPointy('ntyp', {
                node: this$,
                nodeType: nodeType
            });
        };
        prototype.cSetAttr = function cSetAttr(attrType, value) {
            var this$ = this;
            if (attrType == repo().nodes['5']) {
                this$.cSetName(value);
            } else {
                pushUndo('attr', {
                    ni: this$.ni,
                    ati: attrType.ni,
                    val: this$.a(attrType)
                });
                command('attr', {
                    ni: this$.ni,
                    ati: attrType.ni,
                    val: value
                });
                applyPointy('attr', {
                    node: this$,
                    attrType: attrType,
                    value: value
                });
            }
        };
        prototype.cAddComponent = function cAddComponent(refType, nodeType, name, args) {
            var this$ = this;
            var beforeRef;
            var ni;
            var ri;
            var bri;
            beforeRef = (args || {})['beforeRef'];
            if (!refType) {
                throw 'ref type missing';
            } else
                null;
            if (!nodeType) {
                throw 'node type missing';
            } else
                null;
            ni = issueNewId(this$.repo);
            ri = issueNewId(this$.repo);
            bri = beforeRef && beforeRef.ri;
            pushUndo('del', { ni: ni });
            command('comp', {
                ri: ri,
                rti: refType.ni,
                sni: this$.ni,
                ni: ni,
                nti: nodeType.ni,
                name: name,
                bri: bri
            });
            return applyPointy('comp', {
                ri: ri,
                source: this$,
                refType: refType,
                ni: ni,
                nodeType: nodeType,
                name: name,
                beforeRef: beforeRef
            });
        };
        prototype.cAddLink = function cAddLink(refType, target) {
            var this$ = this;
            var ri;
            if (!refType) {
                throw 'ref type missing';
            } else
                null;
            if (!target) {
                throw 'target missing';
            } else
                null;
            ri = issueNewId(this$.repo);
            pushUndo('ulnk', { ri: ri });
            command('link', {
                ri: ri,
                sni: this$.ni,
                rti: refType.ni,
                gni: target.ni
            });
            return applyPointy('link', {
                ri: ri,
                source: this$,
                refType: refType,
                target: target
            });
        };
        prototype.cDelete = function cDelete() {
            var this$ = this;
            var inlinksCount;
            var refCount;
            var ref;
            var nextSibling;
            var siblingParentRef;
            var bri;
            inlinksCount = this$.inrefs().length - 1;
            refCount = this$.refs().length;
            if (inlinksCount + refCount > 0) {
                throw 'Can\'t remove. Threre are ' + refCount + ' components and links and ' + inlinksCount + ' incoming links';
            } else
                null;
            ref = this$.parentRef();
            if ((nextSibling = this$.nextSibling()) && (siblingParentRef = nextSibling.parentRef())) {
                bri = siblingParentRef.ri;
            } else
                null;
            pushUndo('comp', {
                ri: ref.ri,
                sni: this$.parent().ni,
                rti: ref.type().ni,
                ni: this$.ni,
                name: this$.name(),
                nti: this$.type().ni,
                bri: bri,
                attrs: this$.attrs()
            });
            applyPointy('del', { node: this$ });
            command('del', { ni: this$.ni });
        };
        prototype.cForceDelete = function cForceDelete() {
            var this$ = this;
            activity('Forced Delete', function function_acrEEda0aB6d() {
                var refs = [];
                var ref;
                refs = map(this$.refs(), function (r) {
                    return r;
                });
                while (ref = refs.pop()) {
                    if (ref.dep()) {
                        ref.target().cForceDelete();
                    } else {
                        ref.cUnlink();
                    }
                }
                refs = filter(this$.inrefs(), function (r) {
                    return !r.dep();
                });
                while (ref = refs.pop()) {
                    if (!ref.dep()) {
                        ref.cUnlink();
                    } else
                        null;
                }
                this$.cDelete();
            });
        };
        prototype.cMove = function cMove(args) {
            var this$ = this;
            var source;
            var refType;
            var beforeRef;
            var bri;
            var sibling;
            var siblingParentRef;
            var undoBri;
            source = args['source'];
            refType = args['refType'];
            beforeRef = args['beforeRef'];
            if (!source) {
                throw 'source missing';
            } else
                null;
            if (!refType) {
                throw 'ref-type missing';
            } else
                null;
            if (beforeRef) {
                bri = beforeRef.ri;
            } else
                null;
            if ((sibling = this$.nextSibling()) && (siblingParentRef = sibling.parentRef())) {
                undoBri = siblingParentRef.ri;
            } else
                null;
            pushUndo('move', {
                ni: this$.ni,
                sni: this$.parent().ni,
                rti: this$.parentRef().type().ni,
                bri: undoBri
            });
            command('move', {
                ni: this$.ni,
                sni: source.ni,
                rti: refType.ni,
                bri: bri
            });
            return applyPointy('move', {
                node: this$,
                source: source,
                refType: refType,
                beforeRef: beforeRef
            });
        };
        prototype.deepCopy = function deepCopy(args) {
            var this$ = this;
            var newParent;
            var refType;
            var beforeRef;
            newParent = args['newParent'];
            refType = args['refType'];
            beforeRef = args['beforeRef'];
            return activity('Copy', function function_acY7bVnA0uz1() {
                var newNode;
                newParent = newParent || this$.parent();
                refType = refType || this$.parentRef().type();
                newNode = newParent.cAddComponent(refType, this$.type(), this$.name(), { beforeRef: beforeRef });
                deepCopyContents(this$, newNode);
                return newNode;
            });
        };
        prototype.name = function () {
            var this$ = this;
            return this$.name$box.get();
        };
        prototype.name$set = function (value) {
            this$ = this;
            this$.name$box.set(value);
        };
        prototype.attrs = function () {
            var this$ = this;
            return this$.attrs$box.get();
        };
        prototype.attrs$set = function (value) {
            this$ = this;
            this$.attrs$box.set(value);
        };
        prototype.refs = function () {
            var this$ = this;
            if (!this$.refs$boxInited) {
                this$.refs$boxInited = true;
                compute(this$.objectId + '-achjao46dQSn', function () {
                    this$.refs$box.set(function () {
                        return map(this$.refRiList, function (ri) {
                            2;
                            return this$.repo.ref(ri);
                        });
                    }());
                });
            }
            return this$.refs$box.get();
        };
        prototype.refs$set = function (value) {
            this$ = this;
            this$.refs$box.set(value);
        };
        prototype.inrefs = function () {
            var this$ = this;
            if (!this$.inrefs$boxInited) {
                this$.inrefs$boxInited = true;
                compute(this$.objectId + '-ac2t7W8QwsZX', function () {
                    this$.inrefs$box.set(function () {
                        return map(this$.inrefRiList, function (ri) {
                            return this$.repo.ref(ri);
                        });
                    }());
                });
            }
            return this$.inrefs$box.get();
        };
        prototype.inrefs$set = function (value) {
            this$ = this;
            this$.inrefs$box.set(value);
        };
        prototype.type = function () {
            var this$ = this;
            if (!this$.type$boxInited) {
                this$.type$boxInited = true;
                compute(this$.objectId + '-ach9omC01jfH', function () {
                    this$.type$box.set(function () {
                        return this$.repo.node(this$.nti);
                    }());
                });
            }
            return this$.type$box.get();
        };
        prototype.type$set = function (value) {
            this$ = this;
            this$.type$box.set(value);
        };
        prototype.parentRef = function () {
            var this$ = this;
            if (!this$.parentRef$boxInited) {
                this$.parentRef$boxInited = true;
                compute(this$.objectId + '-acQF5QNTdek1', function () {
                    this$.parentRef$box.set(function () {
                        return find(this$.inrefs(), function (r) {
                            return r.dep();
                        });
                    }());
                });
            }
            return this$.parentRef$box.get();
        };
        prototype.parentRef$set = function (value) {
            this$ = this;
            this$.parentRef$box.set(value);
        };
        prototype.parent = function () {
            var this$ = this;
            if (!this$.parent$boxInited) {
                this$.parent$boxInited = true;
                compute(this$.objectId + '-acviugs20aHJ', function () {
                    this$.parent$box.set(function () {
                        if (this$.parentRef()) {
                            return this$.parentRef().source();
                        } else {
                            return null;
                        }
                    }());
                });
            }
            return this$.parent$box.get();
        };
        prototype.parent$set = function (value) {
            this$ = this;
            this$.parent$box.set(value);
        };
        prototype.attrList = function () {
            var this$ = this;
            if (!this$.attrList$boxInited) {
                this$.attrList$boxInited = true;
                compute(this$.objectId + '-actWa2fPvnFe', function () {
                    this$.attrList$box.set(function () {
                        var list = [];
                        eachPair(this$.attrs(), function function_ac8HfAAYjNmi(ati, val) {
                            list.push(new Attr(ati, repo().node(ati), val));
                        });
                        return list;
                    }());
                });
            }
            return this$.attrList$box.get();
        };
        prototype.attrList$set = function (value) {
            this$ = this;
            this$.attrList$box.set(value);
        };
        prototype.ancestors = function () {
            var this$ = this;
            if (!this$.ancestors$boxInited) {
                this$.ancestors$boxInited = true;
                compute(this$.objectId + '-ac5818wAoM9c', function () {
                    this$.ancestors$box.set(function () {
                        var parent;
                        if (parent = this$.parent()) {
                            return concat(parent.ancestors(), [parent]);
                        } else {
                            return [];
                        }
                    }());
                });
            }
            return this$.ancestors$box.get();
        };
        prototype.ancestors$set = function (value) {
            this$ = this;
            this$.ancestors$box.set(value);
        };
        prototype.sourceName = function () {
            var this$ = this;
            if (!this$.sourceName$boxInited) {
                this$.sourceName$boxInited = true;
                compute(this$.objectId + '-acTycs0hJy6R', function () {
                    this$.sourceName$box.set(function () {
                        var s;
                        var nti;
                        var typeSuffix;
                        if (this$.name()) {
                            s = '';
                            each(this$.ancestors(), function function_ac1YM8Qxj8zm(node) {
                                if (node.ni != '9' && node.ni != '112') {
                                    s += node.name() + '/';
                                } else
                                    null;
                            });
                            switch (this$.type().ni) {
                            case '1':
                            case '7':
                                typeSuffix = '';
                                break;
                            case '2':
                                typeSuffix = '-a';
                                break;
                            case '3':
                                typeSuffix = '-r';
                                break;
                            default:
                                typeSuffix = '-' + this$.type().name();
                                break;
                            }
                            return s + this$.name() + typeSuffix;
                        } else
                            null;
                    }());
                });
            }
            return this$.sourceName$box.get();
        };
        prototype.sourceName$set = function (value) {
            this$ = this;
            this$.sourceName$box.set(value);
        };
        prototype.inspect = function () {
            var this$ = this;
            if (!this$.inspect$boxInited) {
                this$.inspect$boxInited = true;
                compute(this$.objectId + '-acucVYm3fEK3', function () {
                    this$.inspect$box.set(function () {
                        return this$.ni + '.' + (this$.name() || ' ') + '-' + this$.type().name();
                    }());
                });
            }
            return this$.inspect$box.get();
        };
        prototype.inspect$set = function (value) {
            this$ = this;
            this$.inspect$box.set(value);
        };
        prototype.crumbs = function () {
            var this$ = this;
            if (!this$.crumbs$boxInited) {
                this$.crumbs$boxInited = true;
                compute(this$.objectId + '-acuVP4RwhC0p', function () {
                    this$.crumbs$box.set(function () {
                        var parentCrumbs = '';
                        var typeSuffix;
                        parentCrumbs = this$.parent() && this$.parent().ni != '9' && this$.parent().crumbs() || '';
                        switch (this$.type().ni) {
                        case '1':
                        case '7':
                            typeSuffix = '-T';
                            break;
                        case '2':
                            typeSuffix = '-A';
                            break;
                        case '3':
                            typeSuffix = '-R';
                            break;
                        default:
                            typeSuffix = '-' + this$.type().name();
                            break;
                        }
                        return parentCrumbs + '.' + this$.ni + (this$.name() && '-' + this$.name() || '') + typeSuffix;
                    }());
                });
            }
            return this$.crumbs$box.get();
        };
        prototype.crumbs$set = function (value) {
            this$ = this;
            this$.crumbs$box.set(value);
        };
        prototype.fq = function () {
            var this$ = this;
            if (!this$.fq$boxInited) {
                this$.fq$boxInited = true;
                compute(this$.objectId + '-accefErHYV0k', function () {
                    this$.fq$box.set(function () {
                        var iter;
                        var containerFq;
                        if (this$.name()) {
                            iter = this$.parent();
                            containerFq = '';
                            while (iter && iter.ni != '9') {
                                if (iter.name()) {
                                    containerFq = iter.name() + '.' + containerFq;
                                } else
                                    null;
                                iter = iter.parent();
                            }
                            return containerFq + this$.name() + '-' + this$.type().name();
                        } else
                            null;
                    }());
                });
            }
            return this$.fq$box.get();
        };
        prototype.fq$set = function (value) {
            this$ = this;
            this$.fq$box.set(value);
        };
        prototype.schema = function () {
            var this$ = this;
            if (!this$.schema$boxInited) {
                this$.schema$boxInited = true;
                compute(this$.objectId + '-ac84f2oWzxS1', function () {
                    this$.schema$box.set(function () {
                        var ni;
                        var node;
                        if (this$.type() == repo().nodes['1']) {
                            ni = this$.ni;
                            node = this$;
                            return schemas[ni] = schemas[ni] || new (require('models/pig/schema'))(node);
                        } else {
                            throw this$.inspect() + ' is not a node type, it doesn\'t have a schema';
                        }
                    }());
                });
            }
            return this$.schema$box.get();
        };
        prototype.schema$set = function (value) {
            this$ = this;
            this$.schema$box.set(value);
        };
        prototype.superType = function () {
            var this$ = this;
            if (!this$.superType$boxInited) {
                this$.superType$boxInited = true;
                compute(this$.objectId + '-acG4dyEbWx23', function () {
                    this$.superType$box.set(function () {
                        if (this$.type() == repo().nodes['1']) {
                            return this$.rn(repo().nodes['386']);
                        } else
                            null;
                    }());
                });
            }
            return this$.superType$box.get();
        };
        prototype.superType$set = function (value) {
            this$ = this;
            this$.superType$box.set(value);
        };
        return Node;
    }();
    return Node;
}();