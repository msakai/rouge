require_relative 'promise'
require_relative 'port'

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
    x.class == y.class and x == y
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
      x.imaginary == 0
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
    args.each do |val|
      return false unless last_val == val

      last_val = val
    end
    true
  end

  def op_num_greater(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val < val

      last_val = val
    end
    true
  end

  def op_num_lesser(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val > val

      last_val = val
    end
    true
  end

  def op_num_lesser_equal(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val >= val

      last_val = val
    end
    true
  end

  def op_num_greater_equal(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val <= val

      last_val = val
    end
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
    x == (Integer(x / 2) * 2) + 1
  end

  def _even?(x)
    x == Integer(x / 2) * 2
  end

  def _min(*args)
    val = args.shift
    args.each do |item|
      val = item if item < val
    end
    val
  end

  def _max(*args)
    val = args.shift
    args.each do |item|
      val = item if item > val
    end
    val
  end

  def op_num_plus(*args)
    args.inject(0) { |result, item| result + item }
  end

  def op_num_minus(x, *args)
    if args.empty?
      -x
    else
      result = x
      args.each do |item|
        result -= item
      end
      result
    end
  end

  def op_num_multiply(*args)
    args.inject(1) { |result, item| result * item }
  end

  # XXX
  def _rationalize_complex(x)
    real  = x.real
    image = x.imaginary
    real  = Rational(real) if real.is_a? Integer
    image = Rational(image) if image.is_a? Integer
    Complex(real, image)
  end

  def op_num_divide(x, *args)
    x = Rational(x, 1) if x.is_a? Integer

    if args.empty?
      1 / x
    else
      result = x
      args.each do |item|
        result /= item
      end
      result
    end
  end

  def quotient(x, y)
    Rational(x, y)
  end

  def gcd(x, args)
    val = x
    args.each do |item|
      val = val.gcd(item)
    end
    val
  end

  def lcm(x, *args)
    val = x
    args.each do |item|
      val = val.lcm(item)
    end
    val
  end

  # def rationalize(x, y)
  # end

  def expt(base, x)
    base**x
  end

  def real_part(x)
    if x.respond_to? :real
      x.real
    else
      x
    end
  end

  def imag_part(x)
    if x.respond_to? :imaginary
      x.imaginary
    else
      0
    end
  end

  def number_to_string(x, radix = 10)
    case radix
    when 10
      String(x)
    else
      raise 'number->string: radix != 10 is not supported'
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
    end
  end

  def _not(x)
    !x
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
    x.to_s.freeze
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

  def make_string(length, initial_char = ' ')
    String(initial_char) * length
  end

  def string(*chars)
    result = '' * chars.size
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

  def string_append(*args)
    args.inject('') { |result, item| result + item }
  end

  def string_to_list(str)
    ary = []
    str.each_byte do |byte|
      ary.push(Character.new(byte))
    end
    Cons.from_a(ary)
  end

  def list_to_string(list)
    result = ''
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
    args.each do |val|
      return false unless last_val == val

      last_val = val
    end
    true
  end

  def op_string_greater(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val < val

      last_val = val
    end
    true
  end

  def op_string_lesser(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val > val

      last_val = val
    end
    true
  end

  def op_string_greater_equal(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val <= val

      last_val = val
    end
    true
  end

  def op_string_lesser_equal(*args)
    last_val = args.shift
    args.each do |val|
      return false unless last_val >= val

      last_val = val
    end
    true
  end

  def op_string_ci_eql(*args)
    last_val = args.shift.downcase
    args.each do |val|
      return false unless last_val == val.downcase

      last_val = val
    end
    true
  end

  def op_string_ci_greater(*args)
    last_val = args.shift.downcase
    args.each do |val|
      return false unless last_val < val.downcase

      last_val = val
    end
    true
  end

  def op_string_ci_lesser(*args)
    last_val = args.shift.downcase
    args.each do |val|
      return false unless last_val > val.downcase

      last_val = val
    end
    true
  end

  def op_string_ci_greater_equal(*args)
    last_val = args.shift.downcase
    args.each do |val|
      return false unless last_val <= val.downcase

      last_val = val
    end
    true
  end

  def op_string_ci_lesser_equal(*args)
    last_val = args.shift.downcase
    args.each do |val|
      return false unless last_val >= val.downcase

      last_val = val
    end
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
    callcc do |cont|
      proc.call(cont)
    end
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
      funcall(func, *(args_list == Null ? [] : Array(args_list)))
    end
  end

  def funcall(func, *args)
    raise String(func) + ' is invalid as a function.' unless func.respond_to?(:call)

    func.call(*args)
  end

  # FIXME
  # incf, decf, signum

  # 無理関数、指数関数、対数関数、三角関数

  # 数の上の論理計算
  # FIXME: logeqv
  # lognand, lognor, logandc1, logandc2, logiorc, logiorc2, lognot, logtest
  # logcount. integer-length

  def logior(*args)
    args.inject(0) { |result, item| result | item }
  end

  def logxor(*args)
    args.inject(0) { |result, item| result ^ item }
  end

  def logand(*args)
    if args.empty?
      -1
    else
      args.inject(1) { |result, item| result & item }
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
      :eq? => :_eq?,
      :eqv? => :_eqv?,
      :equal? => :_equal?,

      # 数値演算
      # FIXME: 仕様に厳密でないので、後で修正する
      :number? => :_number?,
      :complex? => :_complex?,
      :float? => :_float?,
      :real? => :_real?,
      :rational? => :_rational?,
      :integer? => :_integer?,
      :'=' => :op_num_eql,
      :< => :op_num_greater,
      :> => :op_num_lesser,
      :<= => :op_num_greater_equal,
      :>= => :op_num_lesser_equal,
      :zero? => :_zero?,
      :positive? => :_positive?,
      :negative? => :_negative?,
      :odd? => :_odd?,
      :even? => :_even?,
      :min => :_min,
      :max => :_max,
      :+ => :op_num_plus,
      :- => :op_num_minus,
      :* => :op_num_multiply,
      :/ => :op_num_divide,
      :quotient => :quotient,
      :gcd => :gcd,
      :lcm => :lcm,
      # FIXME: rationalize
      :'real-part' => :real_part,
      :'imag-part' => :imag_part,

      # 数値の入出力
      :'number->string' => :number_to_string,
      # 'string->number'.intern => :string_to_number,

      # 論理式
      :not => :_not,
      :boolean? => :_boolean?,

      # ペアとリスト
      :pair? => :_pair?,
      :car => :car,
      :cdr => :cdr,
      :'set-car!' => :set_car,
      :'set-cdr!' => :set_cdr,
      :null? => :_null?,

      # シンボル
      :symbol? => :_symbol?,
      :'symbol->string' => :symbol_to_string,
      :'string->symbol' => :string_to_symbol,

      # 文字型
      :char? => :_char?,
      :'integer->char' => :int_to_char,

      # 文字列
      :string? => :_string?,
      :'make-string' => :make_string,
      :string => :string,
      :'string-length' => :string_length,
      :'string-ref' => :string_ref,
      :'string-set!' => :string_set,
      :'string=?' => :op_string_eql,
      :'string<?' => :op_string_greater,
      :'string>?' => :op_string_lesser,
      :'string<=?' => :op_string_greater_equal,
      :'string>=?' => :op_string_lesser_equal,
      :'string-ci=?' => :op_string_ci_eql,
      :'string-ci<?' => :op_string_ci_greater,
      :'string-ci>?' => :op_string_ci_lesser,
      :'string-ci<=?' => :op_string_ci_greater_equal,
      :'string-ci>=?' => :op_string_ci_lesser_equal,
      :'string-append' => :string_append,
      :'string->list' => :string_to_list,
      :'list->string' => :list_to_string,
      :'string-copy' => :string_copy,
      :'string-fill!' => :string_fill,

      # ベクタ
      :vector? => :_vector?,
      :'make-vector' => :make_vector,
      :vector => :vector,
      :'vector-length' => :vector_length,
      :'vector-ref' => :vector_ref,
      :'vector-set!' => :vector_set,
      :'vector->list' => :vector_to_list,
      :'list->vector' => :list_to_vector,

      # 制御機能
      :procedure? => :_procedure?,
      # FIXME: apply, map
      # 'for-each'.intern => :_for_each.
      :force => :force,
      :'call-with-current-continuation' => :call_with_current_continuation,
      :'call/cc' => :call_with_current_continuation,

      # Eval
      :eval => :_eval,

      # FIXME: port関係
      :'input-port?' => :_input_port?,
      :'output-port?' => :_output_port?,
      :'close-input-file' => :close_input_file,
      :'close-output-file' => :close_output_file,
      :'eof-object?' => :_eof_object?,

      # システムインターフェース
      :load => :load,
      :bye => :bye,
      :exit => :bye,
      :'ruby:eval' => :ruby_eval,
      :'ruby:send' => :ruby_send,
    }.each do |key, val|
      @global_binding.bind(key, method(val))
    end

    %i[exp log sin cos tan sqrt].each do |sym|
      @global_binding.bind(sym, Math.method(sym))
    end
    @global_binding.bind(:pi, Math::PI)
    @global_binding.bind(:'*e*', Math::E)

    @global_binding.bind(:'make-rectangular', Kernel.singleton_method(:Complex))
    @global_binding.bind(:'make-polar', Complex.method(:polar))
    @global_binding.bind(:'*i*', Complex::I)

    @global_binding.bind(:cons, Cons.method(:new))

    @global_binding.bind(:'make-promise', Promiss.method(:new))

    @global_binding.bind(:'open-input-file', InputPort.method(:new))
    @global_binding.bind(:'open-output-file', OutputPort.method(:new))

    %i[funcall
       logior logxor logand lognot logbitp ash expt].each do |sym|
      @global_binding.bind(sym, method(sym))
    end

    @global_binding.bind(:float, Kernel.method(:Float))
  end
end # class Lisp
