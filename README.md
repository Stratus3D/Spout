# Spout [![Build Status](https://travis-ci.org/Stratus3D/Spout.svg?branch=master)](https://travis-ci.org/Stratus3D/Spout)

**A TAP producer that integrates with existing ExUnit tests via an ExUnit formatter**

Spout provides a simple way to generate TAP output without having to modify existing test code.

## Installation

Add Spout as a test dependency in your project:

    def deps do
      [{:spout, "~> 1.0.0"}]
    end

## Usage

Add Spout as a ExUnit formatter in your `test/test_helper.exs` file:

    ExUnit.configure formatters: [Spout]
    ExUnit.start()

If you want to keep using the default formatter alongside Spout your `test/test_helper.exs` file should look like this:

    ExUnit.configure formatters: [Spout, ExUnit.CLIFormatter]
    ExUnit.start()

### Options

`Spout` accepts one option that you can set in your `config.exs` file:

* `file` (binary) - defaults to printing to STDOUT if this option is not specified. This is the file TAP output will be written to.

Example configuration:

    config :spout,
      file: "tap_output.tap"

## Similar Projects

* A TAP producer for Erlang's Common Test: [https://github.com/Stratus3D/cttap](https://github.com/Stratus3D/cttap)
* Another TAP producer for Elixir: [https://github.com/joshwlewis/tapex](https://github.com/joshwlewis/tapex)

## TODO

* Sort output. It currently outputs test result lines in the same random order the test were run in. I think we can sort on filename and line number.
* Add color

## Known Issues

No known issues.

## Contributing

Feel free to create an issue or pull request on GitHub ([https://github.com/Stratus3D/spout/issues](https://github.com/Stratus3D/spout/issues)) if you find a bug or see something that could be improved.
