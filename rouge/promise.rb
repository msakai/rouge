# coding: utf-8

# 本当は、defineとdefine-syntaxで実装可能なんだけど、
# syntax周りについて良く理解していないので。

class Lisp
  
  class Promiss < SExpObject
    def initialize(proc)
      @proc  = proc
      @value = nil
    end

    def force
      if @value
	@value
      else
	@value = @proc.call
      end
    end

    def to_sexp
      "#<promiss #{__id__}>"
    end
  end

  def force(obj)
    if obj.is_a? Promiss
      obj.force
    else
      obj
    end
  end

end
