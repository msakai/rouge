
class Lisp

  class Port
    EOF = Object.new

    attr_reader :io

    def initialize(io)
      @io = io
    end

    def close_read
      @io.close_read
    end

    def close_write
      @io.close_write
    end
  end

  class InputPort < Port
    def initialize(filename)
      super(File::new(filename, "rb"))
      @peek_char = nil
      @reader    = nil
    end

    def read
      @reader = SexpReader.new(io) unless @reader
      if @reader.empty?
        EOF
      else
        @reader.read
      end
    end

    def read_char
      result = peek_char
      @peek_char = nil
      result
    end

    def peek_char
      if @peek_char
        result = @peek_char
        @peek_char = nil
        result
      else
        c = io.getc
        if c
          @peek_char = Character.new(c)
        else
          @peek_char = EOF
        end
      end
    end
  end

  class OutputPort < Port
    def initialize(filename)
      super(File::new(filename, "wb"))
    end

    def write(obj)
      io.write(Sexp(obj, true))
      Unspecified
    end

    def display(obj)
      io.write(String(obj))
      Unspecified
    end

    def write_char(c)
      io.putc(Integer(c))
    end
  end


  def _input_port?(obj)
    obj.is_a? InputPort
  end

  def _output_port?(obj)
    obj.is_a? OutputPort
  end

  def close_input_file(obj)
    obj.close_read
  end

  def close_output_file(obj)
    obj.close_write
  end

  def _eof_object?(obj)
    obj.is_a? EOF
  end

  def load(filename)
    port = InputPort.new(filename)
    while true
      obj = port.read
      break if obj == Port::EOF
      evaluate(obj)
    end
    Unspecified
  end
end
