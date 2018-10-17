# Paladin

tldr; Shotgun for crystal projects

Rebuilds and restarts a given target when any of the given files are modified
or files matching given globs are added/deleted.

## Installation

Add it to your development dependencies:

``` yaml
development_dependencies:
  paladin:
    github: jreinert/paladin
```

## Usage

```
bin/paladin [options] target file [files ...]
    -w PORT, --websocket-port=PORT      Start a websocket server at http://localhost:PORT
                                        that notifies clients when the target has been restarted

    -t STRING, --reload-trigger=STRING  Send reload message to websocket clients when STRING
                                        appears on the standard output of the built target

    -h, --help                          Show this message
```

## Contributing

1. Fork it (<https://github.com/jreinert/paladin/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [jreinert](https://github.com/jreinert) Joakim Reinert - creator, maintainer
