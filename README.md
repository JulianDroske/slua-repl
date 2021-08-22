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
* View and replay history
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

## Supports

* (Full support) @philanc/slua on Linux
* (Without any additional feature) lua on Linux
* (Unknown) Other platforms

## "Bugs"
* No multi-line editing support
* Not support for all special keys
* Editing after typing over one line

## TODO
* Edit a super long line
* Save and load REPL history
