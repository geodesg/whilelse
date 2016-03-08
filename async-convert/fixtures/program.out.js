function readFile(file, callback) {
    require('fs').readFile(file, function (err, data) {
        if (err)
            throw err;
        callback(data);
    });
}
filename = 'counter.txt';
readFile(filename, function (tmp1) {
    contents = tmp1;
    console.log(contents);
});