defmodule Spout do
  @moduledoc """
  * A ExUnit.Formatter implementation that generates a TAP output.

  The report is written to a file in the _build directory.
  """

  use GenEvent

  ## Formatter callbacks: may use opts in the future to configure file name pattern
  def init(opts) do
    #colorize = case get_in(opts, [:colors, :enabled]) do
    #  nil     -> IO.ANSI.enabled?
    #  enabled -> enabled
    #end

    io_device = get_io_device(opts)
    write_line(io_device, version())
    {:ok, %SpoutState{io_device: io_device, timestamp: timestamp()}}
  end

  def handle_event({:suite_started, _opts}, config) do
    # TODO: Add header
    {:ok, config}
  end

  def handle_event({:suite_finished, _run_us, _load_us}, config) do
    io = config.io_device

    write_line(io, test_plan_line(config.total))
    #IO.binwrite(io, "config: ")
    #IO.inspect(io, config, [])
    # TODO: Log the run and load times at the end of the test

    File.close io

    # Release handler
    :remove_handler
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:skip, _}} = test}, config) do
    data = {:testcase, test, :skip, :timer.now_diff(timestamp(), config.timestamp)}
    {:ok, log_testcase(config, data)}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:failed, _failed}} = test}, config) do
    return = :failed # TODO: Figure out the real return value
    data = {:testcase, test, return, :timer.now_diff(timestamp(), config.timestamp)}
    {:ok, log_testcase(config, data)}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: {:invalid, _module}} = test}, config) do
    return = :invalid # TODO: Figure out the real return value
    data = {:testcase, test, return, :timer.now_diff(timestamp(), config.timestamp)}
    {:ok, log_testcase(config, data)}
  end

  def handle_event({:test_finished, %ExUnit.Test{state: nil, tags: tags} = test}, config) do
    case tags do
       %{todo: true} ->
         data = {:testcase, test, {:skip, :todo}, :timer.now_diff(timestamp(), config.timestamp)}
         {:ok, log_testcase(config, data)}
      _ ->
         data = {:testcase, test, :ok, :timer.now_diff(timestamp(), config.timestamp)}
         {:ok, log_testcase(config, data)}
    end
  end

  def handle_event({:test_finished, %ExUnit.Test{} = test}, config) do
    IO.puts "Got an unexpect type of test: #{test}"
    {:ok, config}
  end

  def handle_event(_event, config) do
    {:ok, config}
  end

  # Private functions
  defp log_testcase(config, {_, test, return, _} = data) do
    new_count = config.total + 1

    # TODO: Figure out how to access the IO log here and log IO as diagnostic output
    line = case return do
        {:skip, :todo} ->
            test_todo(config.io_device, new_count, Atom.to_string(test.name), :undefined)
        {:skip, reason} ->
            test_skip(config.io_device, new_count, Atom.to_string(test.name), reason)
        {:error, reason} ->
            test_fail(config.io_device, new_count, [Atom.to_string(test.name), " reason: #{reason}"])
        value ->
            test_success(config.io_device, new_count, [Atom.to_string(test.name), " return value: #{value}"])
    end

    %{config | total: new_count, test_cases: [data|config.test_cases]}
  end

  defp timestamp() do
    :os.timestamp()
  end

  # Private TAP functions
  defp version() do
    "TAP version 13"
  end

  defp test_plan_line(num_tests) do
    "1..#{num_tests}"
  end

  # I can't think of a reason all the test suites would need to abort
  #defp bail_out(reason) do
  #    :io_lib.format("Bail out! ~s", [Reason])
  #end

  # I can't think of a reason all the test suites would need to be skipped
  #defp test_plan_line_skip(NumTests, Reason) do
  #    :io_lib.format("1..~B ~s", [NumTests, Reason])
  #end

  defp test_success(io_device, number, description) do
    write_line(io_device, "ok #{number} #{description}")
  end

  defp test_fail(io_device, number, description) do
    write_line(io_device, "not ok #{number} #{description}")
  end

  defp test_skip(io_device, number, description, reason) do
    write_line(io_device, "ok #{number} #{description} # SKIP #{reason}")
  end

  defp test_todo(io_device, number, description, reason) do
    line = case reason do
      :undefined ->
        "not ok #{number} #{description} # TODO"
      _ ->
        "not ok #{number} #{description} # TODO #{reason}"
    end
    write_line(io_device, line)
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

  defp write_line(io, line) do
    IO.binwrite(io, line)
    IO.binwrite(io, "\n")
  end

  defp get_io_device(config) do
    case get_filename(config) do
      :nil ->
        # STDOUT
        :stdio
      filename ->
        # Save the report to file
        File.open!(Mix.Project.build_path <> "/" <> filename, [:write])
    end
  end

  defp get_filename(_config) do
    Application.get_env :spout, :file
  end
end
