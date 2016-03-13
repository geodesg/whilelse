// Usage:
//   node runner.js {run|watch} {parallel|serial}
//
console.log("Acceptance Test Runner");
var fs = require('fs');
var sys = require('sys')
var exec = require('child_process').exec;
var spawn = require('child_process').spawn;
var path = require('path');

var last_test = null;

var argWatch    = process.argv[2] == 'watch'
var argParallel = process.argv[3] == 'parallel'
var maxRunning = parseInt(process.argv[3] || "4");

var homeDir = process.env['HOME'];
var keysDir = homeDir + '/tmp/keys';
var screenshotsDir = homeDir + '/tmp/screenshots';


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
    //console.log(output + "Exit: " + code);
    callback(
      (code == 0 ? null : "exit code " + code),
      output
     )
  });
};

function run_test_remember_failing(test_path, finishedCb) {
  run_test_cached(test_path, function (err, output) {
    if (err) {
      last_test = test_path;
    }
    if (finishedCb) {
      finishedCb(err, output);
    }
  });
}
function run_all(finishCb) {
  console.log("Running all tests, " + maxRunning + " at a time...")
  dir = 'gen/tests';
  fs.readdir(dir, function(err, files){
    var i, len;
    var steps = [], stepIndex = -1, running = 0, failed = 0;
    for (i = 0, len = files.length; i < len; ++i) {
      (function() {
        var f = files[i];
        var index = i;
        steps.push({
          name: f,
          func: function() {
            run_test_remember_failing(dir + "/" + f, function(err, output) {
              stepFinished(index, err, output);
            });
          }
        });
      })();
    }
    function stepFinished(index, err, output) {
      running--;
      if (err) {
        failed++;
      }
      var step = steps[index];
      step.err = err;
      step.output = output;
      if (step.err) {
        console.log("\nTEST FAILED: " + step.name);
        console.log(step.output);
        console.log(step.err);
        console.log("");
      }
      if (stepIndex < steps.length) {
        if (running < maxRunning) {
          runNext();
        }
      } else {
        maybeFinish();
      }
    }
    function runNext() {
      stepIndex ++;
      var step = steps[stepIndex];
      if (step) {
        console.log("Running test " + (stepIndex+1) + " of " + (steps.length));
        running++;
        step.func();
      } else {
        maybeFinish();
      }
    }
    function maybeFinish() {
      if (stepIndex == steps.length && running == 0) {
        if (failed) {
          console.log("" + failed + " FAILED:");
          for (var i = 0; i < steps.length; i++) {
            var step = steps[i];
            if (step.err) {
              console.log(" - " + step.name);
            }
          }
          console.log("FAIL");
          if (finishCb) {
            finishCb('failed');
          }
        } else {
          console.log("SUCCESS");
          if (finishCb) {
            finishCb(null);
          }
        }
      }
    }
    while (running < maxRunning) {
      runNext();
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

  if (keysDir) {
    fs.watch(keysDir, { recursive: true, persistent: true }, function (event, filename) {
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
  }

  if (screenshotsDir) {
    fswatch(screenshotsDir, function (filename) {
      if (filename == 'casper.png') {
        setTimeout(function() {
          run_quiet('open', [screenshotsDir + '/casper.png']);
        }, 100);
      }
    });
  }
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
  run_all(function(err) {
    process.exit(err ? -1 : 0);
  });
}
