# frozen_string_literal: true

require_relative "test_helper"

class TestEvaluator < Minitest::Test
  def setup
    @vm = create_vm
  end

  def eval(str)
    lisp_eval(@vm, str)
  end

  # Arithmetic
  def test_addition
    assert_equal 3, eval("(+ 1 2)")
    assert_equal 10, eval("(+ 1 2 3 4)")
    assert_equal 0, eval("(+)")
  end

  def test_subtraction
    assert_equal(-1, eval("(- 1 2)"))
    assert_equal(-5, eval("(- 5)"))
  end

  def test_multiplication
    assert_equal 6, eval("(* 2 3)")
    assert_equal 1, eval("(*)")
  end

  def test_division
    assert_equal Rational(1, 2), eval("(/ 1 2)")
  end

  # Comparison
  def test_numeric_comparison
    assert_equal true, eval("(= 1 1)")
    assert_equal false, eval("(= 1 2)")
    assert_equal true, eval("(< 1 2)")
    assert_equal false, eval("(< 2 1)")
    assert_equal true, eval("(> 2 1)")
    assert_equal true, eval("(<= 1 1)")
    assert_equal true, eval("(>= 2 1)")
  end

  # Predicates
  def test_number_predicates
    assert_equal true, eval("(number? 42)")
    assert_equal false, eval("(number? 'foo)")
    assert_equal true, eval("(zero? 0)")
    assert_equal true, eval("(positive? 1)")
    assert_equal true, eval("(negative? -1)")
    assert_equal true, eval("(odd? 3)")
    assert_equal true, eval("(even? 4)")
  end

  def test_type_predicates
    assert_equal true, eval("(symbol? 'foo)")
    assert_equal true, eval("(string? \"hello\")")
    assert_equal true, eval("(boolean? #t)")
    assert_equal true, eval("(pair? '(1 2))")
    assert_equal true, eval("(null? '())")
  end

  # Define
  def test_define
    eval("(define x 42)")
    assert_equal 42, eval("x")
  end

  def test_define_lambda
    eval("(define square (lambda (x) (* x x)))")
    assert_equal 25, eval("(square 5)")
  end

  # Lambda
  def test_lambda
    eval("(define square (lambda (x) (* x x)))")
    assert_equal 9, eval("(square 3)")
  end

  def test_lambda_closure
    eval("(define make-adder (lambda (n) (lambda (x) (+ n x))))")
    eval("(define add5 (make-adder 5))")
    assert_equal 8, eval("(add5 3)")
  end

  # Special forms
  def test_if
    assert_equal 1, eval("(if #t 1 2)")
    assert_equal 2, eval("(if #f 1 2)")
  end

  def test_let
    assert_equal 3, eval("(let ((x 1) (y 2)) (+ x y))")
  end

  def test_let_star
    assert_equal 3, eval("(let* ((x 1) (y (+ x 1))) (+ x y))")
  end

  def test_begin
    assert_equal 3, eval("(begin 1 2 3)")
  end

  def test_and
    assert_equal true, eval("(and #t #t)")
    assert_equal false, eval("(and #t #f)")
    assert_equal true, eval("(and)")
  end

  def test_or
    assert_equal true, eval("(or #f #t)")
    assert_equal false, eval("(or #f #f)")
    assert_equal false, eval("(or)")
  end

  def test_cond
    assert_equal 1, eval("(cond (#t 1) (else 2))")
    assert_equal 2, eval("(cond (#f 1) (else 2))")
  end

  # List operations
  def test_cons_car_cdr
    assert_equal 1, eval("(car '(1 2 3))")
    assert_equal 2, eval("(car (cdr '(1 2 3)))")
    assert_equal 3, eval("(car (cdr (cdr '(1 2 3))))")
  end

  def test_list_operations
    assert_equal 3, eval("(length '(1 2 3))")
    result = eval("(append '(1 2) '(3 4))")
    assert_equal "(1 2 3 4)", result.to_s
    result = eval("(reverse '(1 2 3))")
    assert_equal "(3 2 1)", result.to_s
  end

  # String operations
  def test_string_length
    assert_equal 5, eval('(string-length "hello")')
  end

  def test_string_append
    assert_equal "world", eval('(string-append "hello" "world")')
  end

  # Recursion
  def test_recursive_factorial
    eval("(define fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1))))))")
    assert_equal 120, eval("(fact 5)")
  end

  # Quote
  def test_quote
    result = eval("'(1 2 3)")
    assert_instance_of Lisp::Cons, result
    assert_equal "(1 2 3)", result.to_s
  end

  # Math
  def test_math_functions
    assert_equal Math::PI, eval("pi")
    assert_equal Math::E, eval("*e*")
    assert_in_delta 1.0, eval("(sin (/ pi 2))"), 0.0001
  end

  # Boolean
  def test_not
    assert_equal false, eval("(not #t)")
    assert_equal true, eval("(not #f)")
  end

  # Vector
  def test_vector
    result = eval("(vector 1 2 3)")
    assert_equal [1, 2, 3], result
  end

  def test_vector_ref
    eval("(define v (vector 10 20 30))")
    assert_equal 20, eval("(vector-ref v 1)")
  end
end
