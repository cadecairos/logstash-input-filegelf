FILEGELF LOGSTASH INPUT
=======================

This [Logstash](http://logstash.net) input plugin will read in one or more files
of GELF formatted data.

## Setup

To run this plugin, launch logstash, defining the path to this plugin.

`bin/logstash --pluginpath /path/to/plugin/root -f stashe.conf`

Here's a sample config:

```
input {
  filegelf {
    path => '/abs/path/to/gelf.logs'
  }
}

output {
  stdout {
    codec => rubydebug
  }
}
```

## Settings

#### remap - default => false

Set to either true or false to have GELF fields remapped to Logstash events fields

Converted fields are:

* `full\_message` becomes event["message"].
* if there is no `full\_message`, `short\_message` becomes event["message"].

#### strip_leading_underscore - default => true

Strips leading underscores on fields in the event. Set to true or false.

For example, '_foo' becomes 'foo'
