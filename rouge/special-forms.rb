
class Lisp
  #############################################################################
  # Substance of special-forms
  #############################################################################

  def block(vm_binding, name, *forms)
    # FIXME
    vm_binding.push_block{
    }
  end

  def _catch(vm_binding, tag, *forms)
    catch(tag) {
      _begin(vm_binding, *forms)
    }
  end

  def _throw(vm_binding, tag, result)
    throw(tag, result)
  end

  def _set!(vm_binding, var, form)
    val = evaluate(form, vm_binding)
    val = Null if val.nil?
    sym = evaluate(var, vm_binding)
    vm_binding[sym] = val
    Unspecified
  end

  def _if(vm_binding, test, _then, _else = Unspecified)
    if evaluate(test, vm_binding)
      evaluate(_then, vm_binding)
    else
      evaluate(_else, vm_binding)
    end
  end

  def let(vm_binding, vars, *forms)
    new_binding = Binding.new(vm_binding)
    vars.each{ |item|
      new_binding.bind(item.car, evaluate(item.cdr.car, vm_binding))
    }
    _begin(new_binding, *forms)
  end

  def let_star(vm_binding, vars, *forms)
    new_binding = Binding.new(vm_binding)
    vars.each{ |item|
      new_binding.bind(item.car, evaluate(item.cdr.car, new_binding))
    }
    _begin(new_binding, *forms)
  end

  def _begin(vm_binding, *forms)    
    val = Unspecified
    forms.each{|form|
      val = evaluate(form, vm_binding)
    }
    val
  end

  def quote(vm_binding, x)
    x
  end

  # FIXME: 意味が違う?
  def unwind_protect(vm_binding, protected_form, *cleanup_forms)
    val = Null
    begin
      val = evaluate(protected_form)
    rescue
    ensure
      _begin(vm_binding, cleanup_forms)
      val
    end
  end

  def define(vm_binding, sym, form)
    vm_binding.bind(sym, vm_binding.vm.evaluate(form, vm_binding))
    Unspecified
  end


  def _and(vm_binding, *forms)
    val = true
    forms.each{ |form|
      val = evaluate(form, vm_binding)
      return val unless val
    }
    val
  end

  def _or(vm_binding, *forms)
    val = false
    forms.each{ |form|
      val = evaluate(form, vm_binding)
      return val if val
    }
    val
  end

  def delay(vm_binding, form)
    make_promise(LambdaClosure.new(vm_binding, Null, form))
  end

  def cond(vm_binding, *forms)
    result = Unspecified
    forms.each do |form|
      if (form.car == :else) or (result = evaluate(form.car))
	result = _begin(vm_binding, *Array(form.cdr)) if form.cdr != Null
	break
      end
    end
    result
  end

  def _case(vm_binding, key, *forms)
    result = Unspecified
    memv = evaluate(:memv)
    key = evaluate(key, vm_binding)
    forms.each do |form|
      if (form.car == :else) or funcall0(memv, key, form.car)
	result = _begin(vm_binding, *Array(form.cdr))
	break
      end
    end
    result
  end

  def _do(vm_binding, *forms)
    var_decls  = Array(forms.shift).collect do
      |item|
      Array(item)
    end

    end_clause = forms.shift
    commands   = forms

    new_binding = Binding.new(vm_binding)

    var_decls.each do |var_decl|
      sym, init = var_decl
      new_binding.bind(sym, evaluate(init, vm_binding))
    end

    while true
      if evaluate(end_clause.car, new_binding)	
	return _begin(new_binding, *Array(end_clause.cdr))
      end

      _begin(new_binding, *commands)

      var_decls.each do |var_decl|
	sym, init, step = var_decl
	new_binding.bind(sym, evaluate(step, new_binding)) if step
      end
    end
  end

  def quasiquote(vm_binding, form)
    BackQuote.new(form).evaluate(vm_binding)
  end

  def __symbol_list__(vm_binding)
    sym_list = Array.new
    while vm_binding do
      sym_list += vm_binding.hash.keys
      vm_binding = vm_binding.parent
    end
    Cons.from_a(sym_list)
  end

  ############################################################################

  private
  
  def define_sp_forms
    [:let, :quote, :define, :eval, :delay, :cond].each{ |sym|
      @sp_forms[sym] = method(sym)
    }

    { 'unwind-protect'.intern => :unwind_protect,
      :catch   => :_catch,
      :throw   => :_throw,
      :if      => :_if,
      :set!    => :_set!,
      :let     => :let,
      'let*'.intern   => :let_star,
      'letrec'.intern => :let_star, # XXX?
      # special form で無くても良いはずだけど
      :and     => :_and,
      :or      => :_or,
      :case    => :_case,
      :do      => :_do,
      :__symbol_list__ => :__symbol_list__,
    }.each{ |key, val|
      @sp_forms[key] = method(val)
    }

    @sp_forms[:lambda] = LambdaClosure.method(:new)

    # @sp_forms[:declare]
    # @sp_forms[:defmacro]
    # @sp_forms['multiple-value-bind'.intern]
    # @sp_forms['multiple-value-call'.intern]
    # @sp_forms['multiple-value-setq'.intern]
    # @sp_forms['multiple-value-prog1'.intern]
    # @sp_forms['return-from'.intern]    
  end

end # class Lisp
