# coding: utf-8
class Lisp

  class <<(Null = SExpObject.new)
    def to_s
      "()"
    end
    alias to_s2 to_s
    alias to_sexp to_s

    def to_a
      []
    end

    def evaluate(vm_binding)
      self
    end
  end

  
  class Cons < SExpObject
    include Enumerable

    attr_accessor :car
    attr_accessor :cdr

    def initialize(car, cdr)
      @car = car
      @cdr = cdr
    end

    def ==(x)
      (x.is_a? Cons) and self.car == x.car and self.cdr == x.cdr
    end

    private

    def eval_func_args(vm_binding)
      vm  = vm_binding.vm

      Cons.collect_from_list(@cdr){|item|
	if item.is_a? Cons
	  vm.evaluate(item.car, vm_binding)
	else
	  vm.evaluate(item, vm_binding)
	end
      }
    end

    public

    def evaluate(vm_binding)
      vm  = vm_binding.vm

      if vm.sp_forms.has_key?(@car)
	vm.sp_forms[@car].call(vm_binding, *Array(@cdr))
      else
	func = vm.evaluate(@car, vm_binding)
	args = eval_func_args(vm_binding)
	vm.funcall0(func, args)
      end
    end

    def _to_s2
      if cdr.instance_of?(Cons) then
  	"#{Lisp.Sexp(car)} #{cdr._to_s2}"
      elsif cdr == Null
  	"#{Lisp.Sexp(car)}"
      else
  	"#{Lisp.Sexp(car)} . #{Lisp.Sexp(cdr)}"
      end
    end
  
    def to_s2
      "(#{_to_s2})"
    end

    def to_s
      to_s2
    end
    alias :inspect :to_s

    def to_a
      case cdr
      when Cons, Null
	Array(@cdr).unshift(@car)
      else
	raise "Not a pure list"
      end
    end

    def self.from_a(ary)
      val = Null
      (ary.size - 1).downto(0){|i|
	val = self.new(ary[i], val)
      }
      val
    end

    # FIXME: 循環をチェック
    def list?
      case @cdr
      when Cons
	@cdr.list?
      when Null
	true
      else
	false
      end
    end

    def each
      tmp = self
      while tmp.is_a? Cons
	yield tmp.car
	tmp = tmp.cdr
      end
    end

    def each_list
      tmp = self
      while true
	yield tmp
	break unless tmp.is_a? Cons
	tmp = tmp.cdr
      end
    end


    def self.collect_from_list(x, &block)
      case x
      when Cons
	Cons.new(yield(x), collect_from_list(x.cdr, &block))
      when Null
	Null
      else
	yield(x)
      end
    end

  end


end
