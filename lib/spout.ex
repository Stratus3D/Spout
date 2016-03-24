defmodule Spout do
  @moduledoc """
  * A ExUnit.Formatter implementation that generates a TAP output.

  The report is written to a file in the _build directory.
  """

  use GenEvent

  @default_tap_filename "tap_output"

  ## Formatter callbacks: may use opts in the future to configure file name pattern
  def init(_opts) do
    {:ok, []}
  end

  def handle_event({:suite_started, _opts}, config) do
    # TODO: Add header

    {:ok, config}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, config) do
    # Generate the TAP lines
    tap_output = tapify(config.test_cases, config.total)

    # Save the report to file
    file = File.open! get_file_name(config), [:write]
    List.foreach(fn(line) ->
      IO.binwrite(file, line)
    end, tap_output)
    File.close file

    # Release handler
    :remove_handler
  end

  def handle_event({:test_finished, %ExUnit.Test{state: nil}}, config) do
    {:ok, config}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:skip, _}} = test}, config) do
    data = {:testcase, test, :skipped, :timer.now_diff(timestamp(), config.timestamp)}
    {:ok, Keyword.put(config, :test_cases, [data|config.test_cases])}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:failed, _failed}} = test}, config) do
    return = :failed # TODO: Figure out the real return value
    data = {:testcase, test, return, :timer.now_diff(timestamp(), config.timestamp)}
    {:ok, Keyword.put(config, :test_cases, [data|config.test_cases])}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:invalid, _module}} = test}, config) do
    return = :invalid # TODO: Figure out the real return value
    data = {:testcase, test, return, :timer.now_diff(timestamp(), config.timestamp)}
    {:ok, Keyword.put(config, :test_cases, [data|config.test_cases])}
  end

  def handle_event(_event, config) do
    {:ok, config}
  end

  # Private functions
  defp tapify(data, total) do
    {output, _Count} = process_suites(data, 1, [])
    [version(), test_plan_line(total) |Enum.reverse(output)]
  end

  defp process_suites([], count, output) do
    {output, count}
  end
  defp process_suites([{:suites, suite, status, _Num, test_cases}|suites], count, output) do
    header = diagnostic_line(["Starting ", Atom.to_list(suite)])
    footer = case status do
                 :skipped ->
                     diagnostic_line(["Skipped ", Atom.to_list(suite)])
                 :ran ->
                     diagnostic_line(["Completed ", Atom.to_list(suite)])
             end
    {testcase_output, new_count} = process_testcases(test_cases, count, [header|output])
    process_suites(suites, new_count, [footer|testcase_output])
  end

  defp process_testcases([], count, output) do
    {output, count}
  end
  defp process_testcases([{:testcase, name, return, _Num}|test_cases], count, output) do
    # TODO: Figure out how to access the IO log here and log IO as diagnostic output
    line = case return do
        {:skip, :todo} ->
            test_todo(count, name, :undefined)
        {:skip, reason} ->
            test_skip(count, name, reason)
        {:error, reason} ->
            test_fail(count, [Atom.to_list(name), " reason: ", :io_lib.format("~w", [reason])])
        value ->
            test_success(count, [Atom.to_list(name), " return value: ", :io_lib.format("~w", [value])])
    end
    process_testcases(test_cases, count + 1, [line|output])
  end

  defp timestamp() do
    :os.timestamp()
  end

  # Private TAP functions
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
      :undefined ->
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
    report = Application.get_env :spout, :filename, @default_tap_filename
    Mix.Project.build_path <> "/" <> report
  end
end
