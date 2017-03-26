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
