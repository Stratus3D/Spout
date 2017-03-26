# Spout [![Build Status](https://travis-ci.org/Stratus3D/Spout.svg?branch=master)](https://travis-ci.org/Stratus3D/Spout)

*A TAP producer that integrates with existing ExUnit tests via an ExUnit formatter*

A TAP producer that integrates with existing ExUnit test suites via a ExUnit formatter. Spout provides a simple way to generate TAP output without having to modify existing test code.

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

## Similar Projects

* A TAP producer for Erlang's Common Test: [https://github.com/Stratus3D/cttap](https://github.com/Stratus3D/cttap)

## TODO

* Add option to specify filename
* Sort output. It currently outputs test result lines in the same random order the test were run in. I think we can sort on filename and line number.

## Known Issues

No known issues.

## Contributing

Feel free to create an issue or pull request on GitHub ([https://github.com/Stratus3D/spout/issues](https://github.com/Stratus3D/spout/issues)) if you find a bug or see something that could be improved.
