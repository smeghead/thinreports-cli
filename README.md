# Thinreports::CLI

[![Gem Version](https://badge.fury.io/rb/thinreports-cli.svg)](https://badge.fury.io/rb/thinreports-cli)
![CI workflow](https://github.com/smeghead/thinreports-cli/actions/workflows/ruby.yml/badge.svg)

**Unofficial** and **Experimental** Thinreports command-line tool.

## Installation

    $ gem install thinreports-cli --pre

## Commands

### $ thinreports upgrade

Upgrade .tlf schema to 0.9.x from 0.8.x:

```
$ thinreports upgrade /path/to/old-0.8.x.tlf /path/to/new-0.9.x.tlf
```

### $ thinreports generate

Generate PDF.

```
$ thinreports generate /path/to/parameter.json /path/to/output.pdf
```

* parameter.json sample
```json
{
  "pages": [
    {
      "template": "example/page1.tlf",
      "items": {
        "text": {"value": "山田 太郎"}
      }
    },
    {
      "template": "example/page2.tlf",
      "items": {
        "text": {"value": "静岡県"}
      }
    }
  ]
}
```

## Requirements

 - Ruby 2.0.0+
 - thinreports 0.9.x

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hidakatsuya/thinreports-cli.

## Plan

 - Write tests
 - Implement `thinreports generate --json /path/to/data.json /path/to/result.pdf` command

## Copyright

Copyright © 2016 Katsuya Hidaka. See MIT-LICENSE for further details.
