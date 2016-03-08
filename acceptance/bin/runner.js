// Usage:
//   node runner.js {run|watch}
//
console.log("Acceptance Test Runner");
var fs = require('fs');
var sys = require('sys')
var exec = require('child_process').exec;
var spawn = require('child_process').spawn;
var path = require('path');

var last_test = null;

var argWatch    = process.argv[2] == 'watch'
//var argParallel = process.argv[3] == 'parallel' TODO: implement serial running

function run(command, args, callback) {
  console.log(command, args.join(' '));

  var p = spawn(command, args);
  p.stdout.on('data', function (data) { process.stdout.write(data.toString()); })
  p.stderr.on('data', function (data) { process.stdout.write(data.toString()); })
  p.on('close', function (code) {
    console.log("Exit " + code);
    if (code == 0) {
      callback(null);
    } else {
      callback('exit code ' + code);
    }
  });
}

function run_quiet(command, args) {
  spawn(command, args);
}

function run_test_cached(name, callback){
  var p, output;
  p = spawn('casperjs', ['test', name]);
  output = '';
  p.stdout.on('data', function(data){ output += data; });
  p.stderr.on('data', function(data){ output += data; });
  p.on('close', function(code){
    console.log(output + "Exit: " + code);
    callback(code == 0 ? null : "exit code " + code)
  });
};

function run_test_remember_failing(test_path) {
  run_test_cached(test_path, function (err) {
    if (err) {
      last_test = test_path;
    }
  });
}
function run_all() {
  console.log("Running all tests in paralllel...")
  dir = 'gen/tests';
  fs.readdir(dir, function(err, files){
    var i, len, f;
    for (i = 0, len = files.length; i < len; ++i) {
      f = files[i];
      run_test_remember_failing(dir + "/" + f);
    }
  });
}

function run_js(file) {
  run('casperjs', ['test', file], function (err) {

  });
}

function watch() {
  console.log("Listening for file system changes...");
  fs.watch('src', { recursive: true, persistent: true }, function (event, filename) {
    if (/\.ls$/.test(filename)) {
      src = 'src/' + filename;
      dst = 'gen/' + filename.replace(/\.ls$/, '.js');
      run('lsc', ['-co', path.dirname(dst), src], function (err) {
        if (! err) {
          if (filename.indexOf('tests/') == 0) {
            last_test = dst;
            run_js(dst);
          } else if (last_test) {
            console.log("Running last test: " + last_test);
            run_js(last_test);
          }
        }
      });
    }
  });

  fs.watch('/Users/lev/tmp/keys', { recursive: true, persistent: true }, function (event, filename) {
    if (filename == 'f2.key') {
      if (last_test) {
        console.log("Running last test: " + last_test);
        run_js(last_test);
      } else {
        console.log("No last test.");
      }
    }
    if (filename == 'm-f2.key') {
      console.log("Running all tests");
      run_all();
    }
  });

  fswatch('/Users/lev/tmp/screenshots', function (filename) {
    if (filename == 'casper.png') {
      setTimeout(function() {
        run_quiet('open', ['/Users/lev/tmp/screenshots/casper.png']);
      }, 100);
    }
  });
}

var fswatch_files = {}
function fswatch(path, callback) {
  fs.watch(path, { recursive: true, persistent: true }, function (event, filename) {
    file = path + "/" + filename;
    if (! fswatch_files[file]) {
      // ignore changes for a bit
      fswatch_files[file] = true;
      setTimeout(function() {
        fswatch_files[file] = false;
      }, 100);
      callback(filename);
    }
  });
}


//------------------------------------------------------------

if (argWatch) {
  watch();
} else {
  run_all();
}
