# Guardian

tldr; Shotgun for crystal projects

Rebuilds and restarts a given target when any of the given files are modified
or files matching given globs are added/deleted.

## Installation

Add it to your development dependencies:

``` yaml
development_dependencies:
  guardian:
    github: jreinert/guardian
```

## Usage

`bin/guardian my_app shard.lock 'src/**/*.cr'`

## Contributing

1. Fork it (<https://github.com/jreinert/guardian/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [jreinert](https://github.com/jreinert) Joakim Reinert - creator, maintainer
