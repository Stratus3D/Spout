defmodule SpoutTest do
  use ExUnit.Case

  ExUnit.configure include: "example_tests/*"
  ExUnit.start

  @tag :skip
  test "badmatch example" do
    a = [{:foo, :bar, :baz}, {:foo, :bar, :bar}, {:foo, :bar, :baz}, {:foo, :bar, :baz}]
    b = [{:foo, :bar, :baz}, {:foo, :bar, :baz}, {:foo, :bar, :baz}, {:foo, :bar, :baz}]
    assert a == b
  end

  test "validate output" do
    # Copied from init_per_suite
    {:ok, tap_output} = :file.read_file("../example_cttap/test.tap")
    IO.inspect(tap_output)

    lines = :binary.split(tap_output, "\n", [:global])
    [version, test_plan|tests] = lines

    # First line should be the version
    "TAP version 13" = version

    # Second line should be the test plan (skipped suite is excluded the report)
    "1..16" = test_plan

    # Next comes the passing suite
    [suite_header, passing_1, passing_2, passing_3, suite_footer|skipped_suite] = tests

    # Header and footer should include the suite name
    "# Starting cttap_usage_passing_SUITE" = suite_header
    "# Completed cttap_usage_passing_SUITE" = suite_footer

    # Passing tests
    passing_test(passing_1, 1, :passing_test_1, :ok)
    passing_test(passing_2, 2, :passing_test_2, :ok)
    passing_test(passing_3, 3, :passing_test_3, :ok)

    # Next is the skipped test suite
    [skipped_suite_header, skipped_suite_footer|usage_suite] = skipped_suite
    "# Starting cttap_usage_bail_out_SUITE" = skipped_suite_header
    "# Skipped cttap_usage_bail_out_SUITE" = skipped_suite_footer

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
    [order_group_header, order_group_test_1, order_group_test_2, order_group_test_3, order_group_footer, usage_suite_footer, _] = order_group
    "# Starting order group" = order_group_header
    passing_test(order_group_test_1, 14, :group_order_1, :ok)
    failing_test(order_group_test_2, 15, :group_order_2, "{{badmatch,2},[{cttap_usage_SUITE,group_order_2,1,[{")
    passing_test(order_group_test_3, 16, :group_order_3, :ok)
    "# Completed order group. return value: ok" = order_group_footer

    # Header and footer include the suite name
    "# Starting cttap_usage_SUITE" = usage_suite_header
    "# Completed cttap_usage_SUITE" = usage_suite_footer
  end

  # Private functions
  defp passing_test(line, number, test, return) do
    test_name = Atom.to_binary(test, :utf8)
    number_bin = Integer.to_binary(number)
    return_bin = List.to_binary(:io_lib.format("~w", [return]))
    expected = <<"ok ", number_bin, " ", test_name, " return value: ", return_bin>>
    ^expected = line
  end

  defp failing_test(line, number, test) do
    failing_test(line, number, test, :undefined)
  end
  defp failing_test(line, number, test, reason) do
    test_name = Atom.to_binary(test, :latin1)
    number_bin = Integer.to_binary(number)
    expected = <<"not ok ", number_bin, " ", test_name, " reason:">>
    case reason do
      :undefined ->
        {0, _} = :binary.match(line, expected, [])
          _ when is_binary(reason) ->
            expected_with_reason = <<expected, " ", reason>>
            {0, _} = :binary.match(line, expected_with_reason, [])
            end
  end

  defp skipped_test(line, number, test) do
    skipped_test(line, number, test, :undefined)
  end
  defp skipped_test(line, number, test, reason) do
    test_name = Atom.to_binary(test, :latin1)
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
    test_name = Atom.to_binary(test, :latin1)
    number_bin = Integer.to_binary(number)
    expected = <<"not ok ", number_bin, " ", test_name, " # TODO">>
    ^expected = line
  end
end
