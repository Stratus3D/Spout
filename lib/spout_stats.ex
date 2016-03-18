defmodule SpoutStats do

  @moduledoc """
  A struct to keep track of test values and tests themselves.

  It is used to build the TAP output file.
  """
  defstruct errors: 0,
  failures: 0,
  skipped: 0,
  tests: 0,
  total: 0,
  time: 0,
  timestamp: nil,
  test_cases: []

  @type t :: %__MODULE__{
    errors: non_neg_integer,
    failures: non_neg_integer,
    skipped: non_neg_integer,
    tests: non_neg_integer,
    total: non_neg_integer,
    time: non_neg_integer,
    timestamp: :os.timestamp,
    test_cases: [ExUnit.Test.t]
  }
end
