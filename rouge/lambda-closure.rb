class Lisp

  class LambdaClosure < SExpObject

    def initialize(vm_binding, vars, *forms)
      @vm_binding = vm_binding
      @forms      = forms

      @vars     = Array.new
      @opt_vars = Array.new
      @aux_vars = Array.new
      @rest_var = nil

      state = :vars

      while vars != Null
	unless vars.is_a? Cons
	  raise "&rest value is already used" if @rest_var
	  @rest_var = vars
	  break
	else
	  item = vars.car
	  case item
	  when '&optional'.intern
	    state = :opt
	  when '&rest'.intern
	    state = :rest
	  when '&aux'.intern
	    state = :aux
	  else
	    case state
	    when :vars
	      @vars.push(item)
	    when :rest
	      raise "multiple &rest" if @rest_var
	      @rest_var = item
	    when :opt
	      @opt_vars.push(item)
	    when :aux
	      @aux_vars.push(item)
	    end
	  end
	end
	vars = vars.cdr if vars.is_a? Cons
      end
    end

    
    def call_with_list(list)
      vm = @vm_binding.vm
      new_binding = Binding.new(@vm_binding)

      @vars.each{ |item|
	raise ArgumentError, "too few arguments" unless list.is_a? Cons
	new_binding.bind(item, vm.car(list))
	list = vm.cdr(list)
      }

      @opt_vars.each{ |item|
	if list.is_a? Cons
	  var_val = list.car
	  list    = list.cdr
	else
	  var_val = nil
	end

	if item.is_a? Cons
	  var_name = vm.car(item)
	  var_val  = vm.evaluate(vm.car(vm.cdr(item)), new_binding) unless var_val
	else
	  var_name = item
	end

	var_val = Null unless var_val

	new_binding.bind(var_name, var_val)
      }

      if @rest_var
	new_binding.bind(@rest_var, list)
      elsif list != Null
	raise ArgumentError, "too many arguments"
      end

      @aux_vars.each{ |item|
	if item.is_a? Cons
	  var_name = item.car
	  var_val  = item.cdr.car
	else
	  var_name = item
	  var_val  = Null
	end
	new_binding.bind(var_name, var_val)
      }

      vm._begin(new_binding, *(@forms)) 
    end


    def call(*args)
      call_with_list(Cons.from_a(args))
    end

    # FIXME
    #def to_list
    #end

    def to_sexp
      "#<procedure #{__id__}>"
    end
  end

end
