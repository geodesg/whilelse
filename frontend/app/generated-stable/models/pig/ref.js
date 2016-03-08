function box() {
    return require('lib/box').box.apply(this, arguments);
}
function compute() {
    return require('lib/box').compute.apply(this, arguments);
}
function pig() {
    return require('models/pig');
}
function pushUndo(ctyp, args) {
    pig().pushUndo(ctyp, args);
}
function applyPointy(ctyp, args) {
    return pig().applyPointy(ctyp, args);
}
function command(ctyp, args) {
    pig().command(ctyp, args);
}
module.exports = function () {
    var Ref = function () {
        Ref.displayName = 'Ref';
        var prototype = Ref.prototype;
        function Ref(repo, ri, sni, rti, gni, dep) {
            var this$ = this;
            this$.objectId = generateObjectId();
            this$.source$box = box(this$.objectId + '-acq1tlO1JLkH', undefined);
            this$.type$box = box(this$.objectId + '-ac3dz9fVXhaj', undefined);
            this$.target$box = box(this$.objectId + '-acOdYckvgGCv', undefined);
            this$.dep$box = box(this$.objectId + '-acU7PqyXQPJO', undefined);
            this$.inspect$box = box(this$.objectId + '-acaIIJsq4GFG', undefined);
            function generateObjectId() {
                return 'ref-' + ri;
            }
            this$.ri = ri;
            repo.refs[ri] = this$;
            this$.source$set(repo.node(sni));
            this$.type$set(repo.node(rti));
            this$.target$set(repo.node(gni));
            this$.dep$set(dep);
        }
        prototype.nextSibling = function nextSibling() {
            var this$ = this;
            var refs;
            var i;
            refs = this$.source().refsWithType(this$.type());
            i = refs.indexOf(this$);
            if (i != -1) {
                return refs[i + 1];
            } else
                null;
        };
        prototype.setType = function setType(newRefType) {
            var this$ = this;
            this$.type$set(newRefType);
        };
        prototype.setSource = function setSource(newSource) {
            var this$ = this;
            this$.source$set(newSource);
        };
        prototype.cSetType = function cSetType(refType) {
            var this$ = this;
            pushUndo('rtyp', {
                ri: this$.ri,
                rti: this$.type().ni
            });
            applyPointy('rtyp', {
                ref: this$,
                refType: refType
            });
            command('rtyp', {
                ri: this$.ri,
                rti: refType.ni
            });
        };
        prototype.cUnlink = function cUnlink() {
            var this$ = this;
            if (this$.dep()) {
                throw 'Can\'t unlink component';
            } else {
                pushUndo('link', {
                    ri: this$.ri,
                    rti: this$.type().ni,
                    sni: this$.source().ni,
                    gni: this$.target().ni
                });
                applyPointy('ulnk', { ref: this$ });
                command('ulnk', { ri: this$.ri });
            }
        };
        prototype.source = function () {
            var this$ = this;
            return this$.source$box.get();
        };
        prototype.source$set = function (value) {
            this$ = this;
            this$.source$box.set(value);
        };
        prototype.type = function () {
            var this$ = this;
            return this$.type$box.get();
        };
        prototype.type$set = function (value) {
            this$ = this;
            this$.type$box.set(value);
        };
        prototype.target = function () {
            var this$ = this;
            return this$.target$box.get();
        };
        prototype.target$set = function (value) {
            this$ = this;
            this$.target$box.set(value);
        };
        prototype.dep = function () {
            var this$ = this;
            return this$.dep$box.get();
        };
        prototype.dep$set = function (value) {
            this$ = this;
            this$.dep$box.set(value);
        };
        prototype.inspect = function () {
            var this$ = this;
            if (!this$.inspect$boxInited) {
                this$.inspect$boxInited = true;
                compute(this$.objectId + '-acaIIJsq4GFG', function () {
                    this$.inspect$box.set(function () {
                        return this$.ri + '-' + this$.type().name() + '-dep' + this$.dep();
                    }());
                });
            }
            return this$.inspect$box.get();
        };
        prototype.inspect$set = function (value) {
            this$ = this;
            this$.inspect$box.set(value);
        };
        return Ref;
    }();
    return Ref;
}();