defmodule SpoutTest do
  use ExUnit.Case

  ExUnit.configure include: "example_tests/*"
  ExUnit.start

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
    passing_test(passing1, 1, passing_test_1, ok)
    passing_test(passing2, 2, passing_test_2, ok)
    passing_test(passing3, 3, passing_test_3, ok)

    # Next is the skipped test suite
    [skipped_suite_header, skipped_suite_footer|usage_suite] = skipped_suite
    "# Starting cttap_usage_bail_out_SUITE" = skipped_suite_header
    "# Skipped cttap_usage_bail_out_SUITE" = skipped_suite_footer

    # Then the usage suite
    [UsageSuiteHeader, PassingOk, Failing, PassingDescription, Todo, Skip, Diagnostic|Groups] = UsageSuite
    passing_test(PassingOk, 4, :passing_test, :ok)
    failing_test(Failing, 5, :failing_test)
    passing_test(PassingDescription, 6, :test_description, :ok)
    todo_test(Todo, 7, :todo_test)
    skipped_test(Skip, 8, :skip_test, "I'm lazy")
    passing_test(Diagnostic, 9, :diagnostic_test, :ok)

    # First group
    [PassingGroupHeader, PassingGroupTest, PassingGroupFooter|FailingGroup] = Groups
    "# Starting passing group" = PassingGroupHeader
    passing_test(PassingGroupTest, 10, :passing_test_in_group, :ok)
    "# Completed passing group. return value: ok" = PassingGroupFooter

    # Failing group
    [FailingGroupHeader, FailingGroupTest, FailingGroupFooter|DescriptionGroup] = FailingGroup
    "# Starting failing group" = FailingGroupHeader
    failing_test(FailingGroupTest, 11, :failing_test_in_group, "{{badmatch,2},[{cttap_usage_SUITE,failing_test_in_group,1")
    "# Completed failing group. return value: ok" = FailingGroupFooter

    # Description group
    [DescriptionGroupHeader, DescriptionGroupTest, DescriptionGroupFooter|TodoGroup] = DescriptionGroup,
    <<"# Starting description group">> = DescriptionGroupHeader,
    passing_test(DescriptionGroupTest, 12, test_description_in_group, ok),
    <<"# Completed description group. return value: ok">> = DescriptionGroupFooter,

    # Todo group
    [TodoGroupHeader, TodoGroupTest, TodoGroupFooter|OrderGroup] = TodoGroup,
    <<"# Starting todo group">> = TodoGroupHeader,
    todo_test(TodoGroupTest, 13, todo_test_in_group),
    <<"# Completed todo group. return value: ok">> = TodoGroupFooter,

    # Order group
    [OrderGroupHeader, OrderGroupTest1, OrderGroupTest2, OrderGroupTest3, OrderGroupFooter, UsageSuiteFooter, _] = OrderGroup,
    <<"# Starting order group">> = OrderGroupHeader,
    passing_test(OrderGroupTest1, 14, group_order_1, ok),
    failing_test(OrderGroupTest2, 15, group_order_2, <<"{{badmatch,2},[{cttap_usage_SUITE,group_order_2,1,[{">>),
    passing_test(OrderGroupTest3, 16, group_order_3, ok),
    <<"# Completed order group. return value: ok">> = OrderGroupFooter,

    # Header and footer include the suite name
    <<"# Starting cttap_usage_SUITE">> = UsageSuiteHeader,
    <<"# Completed cttap_usage_SUITE">> = UsageSuiteFooter,
  end

  test "badmatch" do
    a = [{:foo, :bar, :baz}, {:foo, :bar, :bar}, {:foo, :bar, :baz}, {:foo, :bar, :baz}]
    b = [{:foo, :bar, :baz}, {:foo, :bar, :baz}, {:foo, :bar, :baz}, {:foo, :bar, :baz}]
    assert a == b
  end

  # Private functions
  defp passing_test(line, number, test, return) do
    test_name = atom_to_binary(test, :utf8)
    number_bin = integer_to_binary(number)
    return_bin = list_to_binary(:io_lib.format("~w", [return]))
    expected = <<"ok ", number_bin/binary, " ", test_name/binary, " return value: ", return_bin/binary>>
    ^expected = line
  end

  defp failing_test(line, number, test) do
    failing_test(line, number, test, undefined)
  end
  defp failing_test(line, number, test, reason) do
    test_name = atom_to_binary(test, :latin1)
    number_bin = integer_to_binary(number)
    expected = <<"not ok ", number_bin/binary, " ", test_name/binary, " reason:">>
    case reason do
      :undefined ->
        {0, _} = :binary.match(line, expected, [])
          _ when is_binary(reason) ->
            expected_with_reason = <<expected/binary, " ", reason/binary>>
            {0, _} = :binary.match(line, expected_with_reason, [])
            end
  end

  defp skipped_test(line, number, test) do
    skipped_test(line, number, test, :undefined)
  end
  defp skipped_test(line, number, test, reason) do
    test_name = atom_to_binary(test, :latin1)
    number_bin = integer_to_binary(number)
    expected = <<"ok ", number_bin/binary, " ", test_name/binary, " # SKIP">>
    case reason do
      :undefined ->
        {0, _} = :binary.match(line, expected, [])
          _ ->
            real_expected = <<expected/binary, " ", reason/binary>>
            ^real_expected = line
        end
  end

  defp todo_test(line, number, test) do
    test_name = atom_to_binary(test, :latin1)
    number_bin = integer_to_binary(number)
    expected = <<"not ok ", number_bin/binary, " ", test_name/binary, " # TODO">>
    ^expected = line
  end
