**Whilelse** is a software development system currently under development
that aims to simplify programming by representing code as a graph instead
of plain text and providing an efficient keyboard-centric editor.

## Getting started

[Getting Started Guide](docs/getting-started.md)

## Running on a development machine

Install the following:

* [Ruby
  2.2.0+](https://www.ruby-lang.org/en/documentation/installation/)
* [Node.js](https://nodejs.org/en/download/package-manager/)
* [supervisord](http://supervisord.org/installing.html) (requires Python)
* [nginx](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/)

Install dependencies (Bundler / npm):

    ./bin/setup

Start supervisord, which will start all components:

    ./bin/run

Open:

    http://localhost:8888/


## Tests

See [acceptance/README.md](acceptance/README.md).

## Deploying

There is a script that can set up everything on a clean Ubuntu 15.10.

Make sure you have SSH key authentication set up:

    ssh root@myserver "lsb_release -d"
    # => Description:    Ubuntu 15.10

Create a `deploy/config.local` file:

    deployhost=myserver
    deploydir=/srv/whilelse

Run: `./deploy/setup`.

## Contributing

[Contributing](docs/contributing.md)
