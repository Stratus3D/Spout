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
    
      test "passing test in group" do
        # Passing test in group
        :passed
      end
    
      test "failing test in group" do
        # Failing test in group (badmatch)
        assert 1 = 2
      end
    
      test "description in group" do
        # Description should just be the test function name and group name
        :ok
      end
    
      @tag :todo
      test "todo test in group" do
        # todo test in todo group
        {:skip, :todo}
      end
    
      @tag :skip
      test "skip test in group" do
        # This test should be skipped since it's in the skip group
        :this_test_should_be_skipped
      end
    
      test "group order 1" do
        # Passing test
        :passed
      end
    
      test "group order 2" do
        # Failing test (badmatch)
        assert 1 = 2
      end
    
      test "group order 3" do
        # Passing test
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
    failing_test(passing_2, 2, "failing test", "failed")
    passing_test(passing_3, 3, :passing_test_3, :ok)

    # Next is the skipped test suite
    usage_suite = skipped_suite

    # Then the usage suite
    [usage_suite_header, passing_ok, failing, passing_description, todo, skip, diagnostic|groups] = usage_suite
    passing_test(passing_ok, 4, :passing_test, :ok)
    failing_test(failing, 5, :failing_test)
    passing_test(passing_description, 6, :test_description, :ok)
    todo_test(todo, 7, :todo_test)
    skipped_test(skip, 8, :skip_test, "I'm lazy")
    passing_test(diagnostic, 9, :diagnostic_test, :ok)

    # First group
    [passing_group_header, passing_group_test, passing_group_footer|failing_group] = groups
    "# Starting passing group" = passing_group_header
    passing_test(passing_group_test, 10, :passing_test_in_group, :ok)
    "# Completed passing group. return value: ok" = passing_group_footer

    # Failing group
    [failing_group_header, failing_group_test, failing_group_footer|description_group] = failing_group
    "# Starting failing group" = failing_group_header
    failing_test(failing_group_test, 11, :failing_test_in_group, "{{badmatch,2},[{cttap_usage_SUITE,failing_test_in_group,1")
    "# Completed failing group. return value: ok" = failing_group_footer

    # Description group
    [description_group_header, description_group_test, description_group_footer|todo_group] = description_group
    <<"# Starting description group">> = description_group_header
    passing_test(description_group_test, 12, :test_description_in_group, :ok)
    <<"# Completed description group. return value: ok">> = description_group_footer

    # Todo group
    [todo_group_header, todo_group_test, todo_group_footer|order_group] = todo_group
    "# Starting todo group" = todo_group_header
    todo_test(todo_group_test, 13, :todo_test_in_group)
    "# Completed todo group. return value: ok" = todo_group_footer

    # Order group
    [order_group_header, order_group_test_1, order_group_test_2, order_group_test_3, order_group_footer, usage_suite_footer, footer_lines] = order_group
    "# Starting order group" = order_group_header
    passing_test(order_group_test_1, 14, :group_order_1, :ok)
    failing_test(order_group_test_2, 15, :group_order_2, "{{badmatch,2},[{cttap_usage_SUITE,group_order_2,1,[{")
    passing_test(order_group_test_3, 16, :group_order_3, :ok)
    "# Completed order group. return value: ok" = order_group_footer

    # Last line should be the test plan (skipped suite is excluded the report)
    [test_plan] = footer_lines
    "1..16" = test_plan

    # Header and footer include the suite name
    "# Starting cttap_usage_SUITE" = usage_suite_header
    "# Completed cttap_usage_SUITE" = usage_suite_footer
  end

  # Private functions
  defp passing_test(line, number, test_name, return) do
    number_bin = Integer.to_string(number)
    return_bin = IO.iodata_to_binary(:io_lib.format("~w", [return]))
    expected = <<"ok ", number_bin :: binary, " test ", test_name :: binary, " return value: ", return_bin :: binary>>
    IO.inspect expected
    ^expected = line
  end

  defp failing_test(line, number, test) do
    failing_test(line, number, test, :undefined)
  end
  defp failing_test(line, number, test_name, reason) do
    number_bin = Integer.to_string(number)
    expected = <<"not ok ", number_bin :: binary, " ", test_name :: binary, " reason:">>
    case reason do
      _ when is_binary(reason) ->
        expected_with_reason = <<expected :: binary, " ", reason :: binary>>
        {0, _} = :binary.match(line, expected_with_reason, [])
          :undefined ->
            {0, _} = :binary.match(line, expected, [])
            end
  end

  defp skipped_test(line, number, test, reason) do
    test_name = Atom.to_string(test)
    number_bin = Integer.to_binary(number)
    expected = <<"ok ", number_bin, " ", test_name, " # SKIP">>
    case reason do
      :undefined ->
        {0, _} = :binary.match(line, expected, [])
          _ ->
            real_expected = <<expected, " ", reason>>
            ^real_expected = line
        end
  end

  defp todo_test(line, number, test) do
    test_name = Atom.to_string(test, :latin1)
    number_bin = Integer.to_binary(number)
    expected = <<"not ok ", number_bin, " ", test_name, " # TODO">>
    ^expected = line
  end
end
