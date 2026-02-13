# frozen_string_literal: true

require_relative 'test_helper'

class TestParser < Minitest::Test
  def setup
    @reader = Lisp::SexpReader.new
  end

  def parse(str)
    @reader.scan(str).read
  end

  def test_integer
    assert_equal 42, parse('42')
    assert_equal(-7, parse('-7'))
    assert_equal 0, parse('0')
  end

  def test_float
    assert_equal 3.14, parse('3.14')
    assert_equal(-1.5, parse('-1.5'))
  end

  def test_rational
    assert_equal Rational(1, 3), parse('1/3')
    assert_equal Rational(2, 5), parse('2/5')
  end

  def test_symbol
    assert_equal :foo, parse('foo')
    assert_equal :bar, parse('BAR') # case-insensitive
  end

  def test_boolean
    assert_equal true, parse('#t')
    assert_equal false, parse('#f')
  end

  def test_string
    assert_equal 'hello', parse('"hello"')
    assert_equal 'hello world', parse('"hello world"')
  end

  def test_character
    char = parse('#\\a')
    assert_instance_of Lisp::Character, char
    assert_equal 'a', char.to_s
  end

  def test_named_character
    space = parse('#\\space')
    assert_instance_of Lisp::Character, space
    assert_equal ' ', space.to_s
  end

  def test_empty_list
    result = parse('()')
    assert_equal Lisp::Null, result
  end

  def test_simple_list
    result = parse('(1 2 3)')
    assert_instance_of Lisp::Cons, result
    assert_equal 1, result.car
    assert_equal 2, result.cdr.car
    assert_equal 3, result.cdr.cdr.car
    assert_equal Lisp::Null, result.cdr.cdr.cdr
  end

  def test_nested_list
    result = parse('(1 (2 3))')
    assert_instance_of Lisp::Cons, result
    assert_equal 1, result.car
    inner = result.cdr.car
    assert_instance_of Lisp::Cons, inner
    assert_equal 2, inner.car
    assert_equal 3, inner.cdr.car
  end

  def test_dotted_pair
    result = parse('(1 . 2)')
    assert_instance_of Lisp::Cons, result
    assert_equal 1, result.car
    assert_equal 2, result.cdr
  end

  def test_quote
    result = parse("'foo")
    assert_instance_of Lisp::Quote, result
    assert_equal :foo, result.quoted
  end

  def test_vector
    result = parse('#(1 2 3)')
    assert_instance_of Array, result
    assert_equal [1, 2, 3], result
  end

  def test_comment_ignored
    @reader.scan("; this is a comment\n42")
    result = @reader.read
    assert_equal 42, result
  end

  def test_multiple_expressions
    @reader.scan('1 2 3')
    assert_equal 1, @reader.read
    assert_equal 2, @reader.read
    assert_equal 3, @reader.read
  end

  def test_unexpected_end
    assert_raises(Lisp::SexpReader::UnexpectedEndOfExpression) do
      parse('')
    end
  end

  def test_unexpected_right_paren
    assert_raises(Lisp::SexpReader::UnexpectedRightParen) do
      parse(')')
    end
  end
end
