function readFile(file, callback) {
    require('fs').readFile(file, function (err, data) {
        if (err)
            throw err;
        callback(data);
    });
}
filename = 'counter.txt';
contents = __AWAIT(readFile(filename));
console.log(contents);
