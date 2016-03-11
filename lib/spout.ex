defmodule Spout do
  @moduledoc """
  * A ExUnit.Formatter implementation that generates a TAP output.

  The report is written to a file in the _build directory.
  """

  use GenEvent

  @default_tap_file "tap_output"

  ## Formatter callbacks: may use opts in the future to configure file name pattern
  def init(_opts) do
    {:ok, []}
  end

  def handle_event({:suite_started, _opts}, config) do
    # TODO: Add header
    {:ok, config}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, config) do
    # do the real magic
    #suites = Enum.map config, &generate_testsuite_tap/1

    # save the report in an xml file
    file = File.open! get_file_name(config), [:write]
    #IO.binwrite file, result
    File.close file

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

  # Private functions
  defp version() do
    "TAP version 13"
  end

  defp test_plan_line(num_tests) do
    :io_lib.format("1..~B", [num_tests])
  end

  # I can't think of a reason all the test suites would need to abort
  #defp bail_out(reason) do
  #    :io_lib.format("Bail out! ~s", [Reason])
  #end

  # I can't think of a reason all the test suites would need to be skipped
  #defp test_plan_line_skip(NumTests, Reason) do
  #    :io_lib.format("1..~B ~s", [NumTests, Reason])
  #end

  defp test_success(number, description) do
    :io_lib.format("ok ~B ~s", [number, description])
  end

  defp test_fail(number, description) do
    :io_lib.format("not ok ~B ~s", [number, description])
  end

  defp test_skip(number, description, reason) do
    :io_lib.format("ok ~B ~s # SKIP ~s", [number, description, reason])
  end

  defp test_todo(number, description, reason) do
    case reason do
      undefined ->
        :io_lib.format("not ok ~B ~s # TODO", [number, description])
      _ ->
        :io_lib.format("not ok ~B ~s # TODO ~s", [number, description, reason])
    end
  end

  defp diagnostic_line(message) do
    ["# "|message]
  end

  # We currently don't need this function
  #diagnostic_multiline(Message) when is_list(Message) ->
  #    diagnostic_multiline(list_to_binary(Message));
  #diagnostic_multiline(Message) when is_binary(Message) ->
  #    Lines = binary:split(Message, <<"~n">>, [global]),
  #    [diagnostic_line(Line) || Line <- Lines].

  defp get_file_name(_config) do
    report = Application.get_env :spout, :filename, "test_report.tap"
    Mix.Project.build_path <> "/" <> report
  end
end
