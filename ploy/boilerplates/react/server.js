var webpack = require('webpack');
var WebpackDevServer = require('webpack-dev-server');
var config = require('./webpack.config');

var host = 'localhost';
var port = parseInt(process.argv[2] || '3000');

new WebpackDevServer(webpack(config), {
  publicPath: config.output.publicPath,
  hot: true,
  historyApiFallback: true
}).listen(port, host, function (err, result) {
  if (err) {
    return console.log(err);
  }

  console.log("Listening at http://" + host + ":" + port + "/");
});
