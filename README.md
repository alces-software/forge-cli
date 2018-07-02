# Forge CLI

## Installation

The `forge-cli` is a utility that is packaged with `flight direct` and thus
does not have an official independent install process.

For development purposes follow these steps to setup a quasi `flight direct`
environment (your mileage may vary):

1. Install the required version of `flight-direct`. See:
https://github.com/alces-software/flight-direct
1. Source the runtime `flight` environment: `flight-direct/etc/runtime.sh`
1. Change to the `forge-cli` source code directory: `cd <source-code-dir>`
1. Install the required gems: `bundle install`
1. Then run the forge-cli directly: `bin/forge`
