# Forge CLI

## Setting the forge API source location

Forge will default to using `forge-api.alces-flight.com/v1` as its metadata
server. This can be changed to a different address by setting 
`cw_FORGE_API_URL` env var.
Note: that the `/v1` path is important and must be set in the url.

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

