# Slua Repl

## Features
Slua Repl is aimed to provide an alternative to the [@philanc/slua](https://github.com/philanc/slua) shell, which uses [simplified linenoise](https://github.com/philanc/slua/blob/master/src/linenoise.md) to replace readline.
Based on [Resty Repl](https://github.com/saks/lua-resty-repl), it also preserves some APIs from Resty Repl, but only supports linux.
Many features come from Resty Repl, including:
* Pretty print for object
* A Powerful and flexible command system
* Ability to view and replay history
* Ability to see a context and source of the place in code from where repl was started
* Tab completion

Additional features (for slua 5.4 & lua with simplified linenoise):
* Tab completion
* Single line editing
* Save, load, view and replay history
* Portable REPL
* Add support for Lua 5.2+

## Installation

```shell
./install.sh
```

Temporarily run:
```shell
./run.sh
```

Uninstallation (standalone, auto-generated) AFTER running install.sh:
```shell
./unist.sh
```

## Compatibility

* (Full) @philanc/slua on Linux
* (No additional feature) lua on Linux
* (Unknown) Other platforms

## "Bugs"
* No support with multi-line editing
* No support with many special keys
* No support for lua-linenoise
