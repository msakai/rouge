# coding: utf-8
class Lisp

  # Rubyだと束縛対のリストよりもHashの方が楽なんで…
  class Binding
    class NotBoundedError < VMError
    end

    attr_reader :vm
    attr_reader :parent

    def initialize(x)
      if x.is_a? Binding
        @parent = x
        @vm     = x.vm
      else
        @vm     = x
        @parent = nil
      end
      @hash = nil
    end

    def bind(sym, val)
      raise "not a Symbol" unless sym.is_a? Symbol
      hash[sym] = val
    end

    def [](sym)
      (@hash and @hash[sym]) or (@parent and @parent[sym]) or (self != @vm.global_binding and @vm.global_binding[sym]) or nil
    end

    def []=(sym, val)
      if @hash and @hash.key? sym
        bind(sym, val)
      elsif @parent and @parent.key? sym
        @parent[sym] = val
      else
        raise "Unbounded: #{sym}"
      end
      val
    end

    def hash
      @hash = ({}) unless @hash
      @hash
    end

    def key?(sym)
      (@hash and @hash.key? sym) or (@parent and @parent.key? sym)
    end
  end

end
