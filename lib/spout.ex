defmodule Spout do
  @moduledoc """
  * A ExUnit.Formatter implementation that generates a TAP output.

  The report is written to a file in the _build directory.
  """

  use GenEvent

  ## Formatter callbacks: may use opts in the future to configure file name pattern
  def init(_opts) do
    {:ok, []}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, _config) do
    # do the real magic
    #suites = Enum.map config, &generate_testsuite_tap/1

    # save the report in an xml file
    #file = File.open! get_file_name(config), [:write]
    #IO.binwrite file, result
    #File.close file

    # Release handler
    :remove_handler
  end

  def handle_event({:test_finished, %ExUnit.Test{state: nil}}, config) do
    {:ok, config}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:skip, _}}}, config) do
    {:ok, config}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:failed, _failed}}}, config) do
    {:ok, config}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:invalid, _module}}}, config) do
    {:ok, config}
  end

  def handle_event(_event, config) do
    {:ok, config}
  end
end
