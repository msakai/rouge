# frozen_string_literal: true

require_relative 'test_helper'

class TestBinding < Minitest::Test
  def setup
    @vm = Lisp.new
    @global = @vm.global_binding
  end

  def test_bind_and_lookup
    @global.bind(:x, 42)
    assert_equal 42, @global[:x]
  end

  def test_unbound_returns_nil
    assert_nil @global[:nonexistent]
  end

  def test_child_binding_sees_parent
    @global.bind(:x, 10)
    child = Lisp::Binding.new(@global)
    assert_equal 10, child[:x]
  end

  def test_child_binding_shadows_parent
    @global.bind(:x, 10)
    child = Lisp::Binding.new(@global)
    child.bind(:x, 20)
    assert_equal 20, child[:x]
    assert_equal 10, @global[:x]
  end

  def test_nested_binding
    @global.bind(:x, 1)
    child = Lisp::Binding.new(@global)
    child.bind(:y, 2)
    grandchild = Lisp::Binding.new(child)
    grandchild.bind(:z, 3)

    assert_equal 1, grandchild[:x]
    assert_equal 2, grandchild[:y]
    assert_equal 3, grandchild[:z]
  end

  def test_set_updates_existing_binding
    @global.bind(:x, 10)
    child = Lisp::Binding.new(@global)
    child.bind(:x, 20)
    child[:x] = 30
    assert_equal 30, child[:x]
  end

  def test_key?
    @global.bind(:x, 10)
    assert @global.key?(:x)
    refute @global.key?(:y)
  end

  def test_bind_requires_symbol
    assert_raises(RuntimeError) { @global.bind('not_a_symbol', 1) }
  end
end
