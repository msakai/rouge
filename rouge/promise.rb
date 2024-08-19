
# $BK\Ev$O!"(Bdefine$B$H(Bdefine-syntax$B$G<BAu2DG=$J$s$@$1$I!"(B
# syntax$B<~$j$K$D$$$FNI$/M}2r$7$F$$$J$$$N$G!#(B

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
