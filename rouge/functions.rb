# coding: utf-8

require 'rouge/promise'
require 'rouge/port'

class Lisp

  #############################################################################
  # Substance of built-in functions
  #############################################################################

  def _eq?(x, y)
    x.equal? y
  end

  def _eqv?(x, y)
    _eq?(x, y) or _equal?(x, y)
  end

  def _equal?(x, y)
    x.type == y.type and x == y
  end

  def _number?(x)
    x.is_a? Numeric
  end

  def _complex?(x)
    (x.is_a? Complex) or _real?(x)
  end

  def _float?(x)
    x.is_a? Float
  end

  def _real?(x)
    if _float?(x) or _rational?(x)
      true
    elsif x.is_a? Complex
      x.image == 0
    else
      false
    end
  end

  def _rational?(x)
    (x.is_a? Rational) or (x.is_a? Integer)
  end

  def _integer?(x)
    if x.integer?
      true
    elsif x.is_a? Rational
      Rational.reduce(x.numerator, x.denominator).denominator == 1
    elsif x.is_a? Float
      x == round(x)
    else
      false
    end
  end

  def op_num_eql(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val == val
      last_val = val
    }
    true
  end

  def op_num_greater(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val < val
      last_val = val
    }
    true
  end

  def op_num_lesser(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val > val
      last_val = val
    }
    true
  end

  def op_num_lesser_equal(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val >= val
      last_val = val
    }
    true
  end

  def op_num_greater_equal(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val <= val
      last_val = val
    }
    true
  end

  def _zero?(x)
    (x.respond_to? :zero?) and x.zero?
  end

  def _positive?(x)
    x > 0
  end

  def _negative?(x)
    x < 0
  end

  def _odd?(x)
    x == Integer(x / 2) * 2 + 1
  end

  def _even?(x)
    x == Integer(x / 2) * 2
  end

  def _min(*args)
    val = args.shift
    args.each{|item|
      val = item if item < val
    }
    val
  end

  def _max(*args)
    val = args.shift
    args.each{|item|
      val = item if item > val
    }
    val
  end

  def op_num_plus(*args)
    args.inject(0){|result, item| result + item}
  end

  def op_num_minus(x, *args)
    if args.empty?
      -x
    else
      result = x
      args.each{|item|
	result -= item
      }
      result
    end
  end

  def op_num_multiply(*args)
    args.inject(1){|result, item| result * item}
  end

  # XXX
  def _rationalize_complex(x)
    real  = x.real
    image = x.image
    real  = Rational(real) if real.is_a? Integer
    image = Rational(image) if image.is_a? Integer
    Complex(real, image)
  end

  def op_num_divide(x, *args)
    if args.empty?
      if x.is_a? Integer
	Rational(1, x)
      else
	1 / x
      end
    else
      result = x
      args.each{ |item|
	result = result / item
      }
      result
    end
  end

  def quotient(x, y)
    Rational(x, y)
  end

  def gcd(x, args)
    val = x
    args.each{|item|
      val = val.gcd(item)
    }
    val
  end

  def lcm(x, *args)
    val = x
    args.each{|item|
      val = val.lcm(item)
    }
    val
  end

  # def rationalize(x, y)
  # end

  def expt(base, x)
    base ** x
  end

  def real_part(x)
    if x.respond_to? real
      x.real
    else
      x
    end
  end

  def imag_part(x)
    if x.respond_to? image
      x.image
    else
      0
    end
  end

  def number_to_string(x, radix = 10)
    case radix
    when 10
      String(x)
    else
      raise "number->string: radix != 10 is not supported"
    end
  end

  # FIXME
  def string_to_number(str, radix)
    case radix
    when 10
      Integer(str) # FIXME
    when 16
      str.hex
    when 8
      str.oct
    else
    end
  end

  def _not(x)
    not x
  end

  def _boolean?(x)
    (x == true) or (x == false)
  end

  def _pair?(x)
    x.is_a? Cons
  end

  def car(x)
    x.car
  end

  def cdr(x)
    x.cdr
  end

  def set_car(x, y)
    x.car = y
    Unspecified
  end

  def set_cdr(x, y)
    x.cdr = y
    Unspecified
  end

  def _null?(x)
    x == Null
  end

  def _symbol?(x)
    x.is_a? Symbol
  end

  def symbol_to_string(x)
    x.id2name.freeze
  end

  def string_to_symbol(x)
    x.downcase.intern
  end

  def _char?(x)
    x.is_a? Character
  end

  def int_to_char(x)
    Character.new(x)
  end

  def _string?(x)
    x.is_a? String
  end

  def make_string(length, initial_char = " ")
    String(initial_char) * length
  end

  def string(*chars)
    result = "" * chars.size
    chars.each_with_index do |item, index|
      result[index] = item
    end
    result
  end

  def string_length(x)
    x.length
  end

  def string_ref(str, index)
    Character.new(str[index])
  end

  def string_set(str, index, char)
    str[index] = Integer(char)
    Unspecified
  end

  def string_append(x, *args)
    args.inject(""){|result, item| result + item}
  end

  def string_to_list(str)
    ary = Array.new
    str.each_byte do |byte|
      ary.push(Character.new(byte))
    end
    Cons.from_a(ary)
  end

  def list_to_string(list)
    result = ""
    list.each do |char|
      result << Integer(char)
    end
    result
  end

  def string_copy(x)
    x.dup
  end

  def string_fill(str, char)
    i = Integer(char)
    str.each_index do |index|
      str[index] = i
    end
    Unspecified
  end

  def op_string_eql(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val == val
      last_val = val
    }
    true
  end

  def op_string_greater(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val < val
      last_val = val
    }
    true
  end

  def op_string_lesser(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val > val
      last_val = val
    }
    true
  end

  def op_string_greater_equal(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val <= val
      last_val = val
    }
    true
  end

  def op_string_lesser_equal(*args)
    last_val = args.shift
    args.each{|val|
      return false unless last_val >= val
      last_val = val
    }
    true
  end

  def op_string_ci_eql(*args)
    last_val = args.shift.downcase
    args.each{|val|
      return false unless last_val == val.downcase
      last_val = val
    }
    true
  end

  def op_string_ci_greater(*args)
    last_val = args.shift.downcase
    args.each{|val|
      return false unless last_val < val.downcase
      last_val = val
    }
    true
  end

  def op_string_ci_lesser(*args)
    last_val = args.shift.downcase
    args.each{|val|
      return false unless last_val > val.downcase
      last_val = val
    }
    true
  end

  def op_string_ci_greater_equal(*args)
    last_val = args.shift.downcase
    args.each{|val|
      return false unless last_val <= val.downcase
      last_val = val
    }
    true
  end

  def op_string_ci_lesser_equal(*args)
    last_val = args.shift.downcase
    args.each{|val|
      return false unless last_val >= val.downcase
      last_val = val
    }
    true
  end

  def _vector?(obj)
    obj.is_a? Array
  end

  def make_vector(length, fill = nil)
    Array.new(length, fill)
  end

  def vector(*args)
    args
  end

  def vector_length(v)
    v.length
  end

  def vector_ref(v, index)
    v[index]
  end

  def vector_set(v, index, obj)
    v[index] = obj
    Unspecified
  end

  def vector_to_list(v)
    Cons.from_array(v)
  end

  def list_to_vector(l)
    Array(l)
  end

  def _procedure?(x)
    # FIXME?
    respond_to?(:call) or respond_to?(:call_with_list)
  end

  def call_with_current_continuation(proc)
    callcc{|cont|
      proc.call(cont)
    }
  end

  # FIXME: グローバルな環境で評価されてしまう。その時点での環境にする。
  def _eval(expression, environment_specifier = nil)
    evaluate(expression, vm_binding)
  end

  def bye
    raise SystemExit
  end

  def ruby_eval(str)
    Kernel.eval(str)
  end
  
  def ruby_send(obj, name, *args)
    obj.__send__(name, *args)
  end

  def funcall0(func, args_list)
    if func.is_a? LambdaClosure
      func.call_with_list(args_list)
    else
      funcall(func, *((args_list == Null) ? [] : Array(args_list)))
    end
  end

  def funcall(func, *args)
    if func.respond_to?(:call)
      func.call(*args)
    else
      raise String(func) + " is invalid as a function."
    end
  end

  # FIXME
  # incf, decf, signum

  # 無理関数、指数関数、対数関数、三角関数

  # 数の上の論理計算
  # FIXME: logeqv
  # lognand, lognor, logandc1, logandc2, logiorc, logiorc2, lognot, logtest
  # logcount. integer-length

  def logior(*args)
    args.inject(0){|result, item| result | item}
  end

  def logxor(*args)
    args.inject(0){|result, item| result ^ item}
  end

  def logand(*args)
    if args.empty?
      -1
    else
      args.inject(1){|result, item| result & item}
    end
  end

  def lognot(x)
    ~x
  end

  def logbitp(index, x)
    x[index] != 0
  end

  def ash(x, count)
    x << count
  end

  # 乱数

  # def random(x)
  # end  

  #############################################################################

  private
  
  def define_builtin_symbols
    # 標準手続き

    {
      # 同値を調べる述語手続き
      :eq?    => :_eq?,
      :eqv?   => :_eqv?,
      :equal? => :_equal?,

      # 数値演算
      # FIXME: 仕様に厳密でないので、後で修正する
      :number?    => :_number?,
      :complex?   => :_complex?,
      :float?     => :_float?,
      :real?      => :_real?,
      :rational?  => :_rational?,
      :integer?   => :_integer?,
      '='.intern  => :op_num_eql,
      '<'.intern  => :op_num_greater,
      '>'.intern  => :op_num_lesser,
      '<='.intern => :op_num_greater_equal,
      '>='.intern => :op_num_lesser_equal,
      :zero?      => :_zero?,
      :positive?  => :_positive?,
      :negative?  => :_negative?,
      :odd?       => :_odd?,
      :even?      => :_even?,
      :min        => :_min,
      :max        => :_max,
      '+'.intern  => :op_num_plus,
      '-'.intern  => :op_num_minus,
      '*'.intern  => :op_num_multiply,
      '/'.intern  => :op_num_divide,
      :quotient   => :quotient,
      :gcd        => :gcd,
      :lcm        => :lcm,
      # FIXME: rationalize
      'real-part'.intern  => :real_part,
      'imag-part'.intern  => :imag_part,

      # 数値の入出力
      'number->string'.intern => :number_to_string,
      #'string->number'.intern => :string_to_number,
      
      # 論理式
      :not      => :_not,
      :boolean? => :_boolean?,
      
      # ペアとリスト
      :pair? => :_pair?,
      :car   => :car,
      :cdr   => :cdr,
      'set-car!'.intern => :set_car,
      'set-cdr!'.intern => :set_cdr,
      :null? => :_null?,

      # シンボル
      :symbol? => :_symbol?,
      'symbol->string'.intern => :symbol_to_string,
      'string->symbol'.intern => :string_to_symbol,

      # 文字型
      :char? => :_char?,
      'integer->char'.intern => :int_to_char,
      
      # 文字列
      :string? => :_string?,
      'make-string'.intern => :make_string,
      :string               => :string,
      'string-length'.intern => :string_length,
      'string-ref'.intern   => :string_ref,
      'string-set!'.intern  => :string_set,
      'string=?'.intern     => :op_string_eql,
      'string<?'.intern     => :op_string_greater,
      'string>?'.intern     => :op_string_lesser,
      'string<=?'.intern    => :op_string_greater_equal,
      'string>=?'.intern    => :op_string_lesser_equal,
      'string-ci=?'.intern  => :op_string_ci_eql,
      'string-ci<?'.intern  => :op_string_ci_greater,
      'string-ci>?'.intern  => :op_string_ci_lesser,
      'string-ci<=?'.intern => :op_string_ci_greater_equal,
      'string-ci>=?'.intern => :op_string_ci_lesser_equal,
      'string-append'.intern => :string_append,
      'string->list'.intern => :string_to_list,
      'list->string'.intern => :list_to_string,
      'string-copy'.intern  => :string_copy,
      'string-fill!'.intern => :string_fill,

      # ベクタ
      'vector?'.intern       => :_vector?,
      'make-vector'.intern   => :make_vector,
      :vector => :vector,
      'vector-length'.intern => :vector_length,
      'vector-ref'.intern    => :vector_ref,
      'vector-set!'.intern   => :vector_set,
      'vector->list'.intern  => :vector_to_list,
      'list->vector'.intern  => :list_to_vector,

      # 制御機能
      :procedure? => :_procedure?,
      # FIXME: apply, map
      # 'for-each'.intern => :_for_each.
      :force => :force,
      'call-with-current-continuation'.intern => :call_with_current_continuation,
      'call/cc'.intern => :call_with_current_continuation,

      # Eval
      :eval => :_eval,

      # FIXME: port関係
      'input-port?'.intern  => :_input_port?,
      'output-port?'.intern => :_output_port?,
      'close-input-file'.intern  => :close_input_file,
      'close-output-file'.intern => :close_output_file,
      'eof-object?'.intern => :_eof_object?,

      # システムインターフェース
      :load => :load,
      :bye  => :bye,
      :exit => :bye,
      'ruby:eval'.intern => :ruby_eval,
      'ruby:send'.intern => :ruby_send,
    }.each{
      |key, val|
      @global_binding.bind(key, method(val))
    }
    
    [:exp, :log, :sin, :cos, :tan, :sqrt].each{|sym|
      @global_binding.bind(sym, Math.method(sym))
    }
    @global_binding.bind(:pi, Math::PI)
    @global_binding.bind('*e*'.intern, Math::E)

    @global_binding.bind('make-rectangular'.intern, Complex.method(:new))
    @global_binding.bind('make-polar'.intern, Complex.method(:polar))
    @global_binding.bind('*i*'.intern, Complex::I)

    @global_binding.bind(:cons, Cons.method(:new))

    @global_binding.bind('make-promise'.intern, Promiss.method(:new))

    @global_binding.bind('open-input-file'.intern, InputPort.method(:new))
    @global_binding.bind('open-output-file'.intern, OutputPort.method(:new))

    [:funcall,
     :logior, :logxor, :logand, :lognot, :logbitp, :ash, :expt
    ].each{ |sym|
      @global_binding.bind(sym, method(sym))
    }

    @global_binding.bind(:float, Kernel.method(:Float))
  end

end # class Lisp
