defmodule SpoutTest do
  use ExUnit.Case

  test "validate output" do
    defmodule SpoutUsageTest do
      use ExUnit.Case
    
      test "passing test" do
        # Passing test
        :passed
      end
    
      test "failing test" do
        # Failing test (badmatch)
        assert 1 = 2
      end
    
      test "description" do
        # Description should just be the test function name
        :ok
      end
    
      @tag :todo
      test "todo test" do
        # todo test
        {:skip, :todo}
      end
    
      @tag :skip
      test "skip test" do
        # Skip this test
        _ = "I'm lazy"
      end
    
      test "diagnostic test" do
        # TODO: Complete test
        # Remember to remove `ok` when complete
        :ok
      end
    end

    # Tests must run in the same order every time, so we use seed: 0
    ExUnit.configure formatters: [Spout], seed: 0
    ExUnit.run
    path = Mix.Project.build_path <> "/foobar"
    {:ok, tap_output} = :file.read_file(path)
    IO.binwrite(tap_output)

    lines = :binary.split(tap_output, "\n", [:global])
    [version|tests] = lines

    # First line should be the version
    "TAP version 13" = version

    # Next comes the passing suite
    [passing_1, passing_2, passing_3|skipped_suite] = tests

    # Passing tests
    passing_test(passing_1, 1, "passing test", :ok)
    failing_test(passing_2, 2, "failing test")
    passing_test(passing_3, 3, "description", :ok)

    # Then the usage suite
    [todo, failing, diagnostic|footer_lines] = skipped_suite
    todo_test(todo, 4, "todo test")
    skipped_test(failing, 5, "skip test")
    passing_test(diagnostic, 6, "diagnostic test", :ok)

    # Last line should be the test plan (skipped suite is excluded the report)
    [test_plan, _] = footer_lines
    "1..6" = test_plan
  end

  # Private functions
  defp passing_test(line, number, test_name, return) do
    number_bin = Integer.to_string(number)
    return_bin = IO.iodata_to_binary(:io_lib.format("~w", [return]))
    expected = <<"ok ", number_bin :: binary, " test ", test_name :: binary>>
    ^expected = line
  end

  defp failing_test(line, number, test) do
    failing_test(line, number, test, nil)
  end
  defp failing_test(line, number, test_name, reason) do
    number_bin = Integer.to_string(number)
    expected = <<"not ok ", number_bin :: binary, " test ", test_name :: binary>>
    ^expected = line
  end

  defp skipped_test(line, number, test_name) do
    skipped_test(line, number, test_name, nil)
  end
  defp skipped_test(line, number, test_name, reason) do
    number_bin = Integer.to_string(number)
    expected = <<"ok ", number_bin :: binary, " test ", test_name :: binary, " # SKIP">>
    case reason do
      nil ->
        ^expected = line
          _ ->
            real_expected = <<expected :: binary, " ", reason :: binary>>
            ^real_expected = line
        end
  end

  defp todo_test(line, number, test_name) do
    number_bin = Integer.to_string(number)
    expected = <<"not ok ", number_bin :: binary, " test ", test_name :: binary, " # TODO">>
    ^expected = line
  end
end
