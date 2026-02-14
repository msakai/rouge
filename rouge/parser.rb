#############################################################################
# パーサー
#  modified from sexp.rb
#############################################################################

#############################################################################
#
# Handling symbolic expression (S expression) with Ruby.
#
# Copyright (C) 2001 Satoru Takabayashi <satoru@namazu.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# This is distributed freely in the sense of
# GPL(GNU General Public License) or Ruby's licence.
#
# The latest version: <http://cvs.namazu.org/ruby-sexp/>
#############################################################################

class Lisp
  class SexpReader
    class ParseError < RuntimeError; end

    class UnexpectedEndOfExpression < ParseError; end
    class UnexpectedDot < ParseError; end
    class UnexpectedRightParen < ParseError; end
    class UnexpectedToken < ParseError; end

    def initialize(io = nil)
      @tokens = []
      @io = io
    end

    attr_accessor :io

    private

    def peek_token
      while buffer_empty?
        break if (!@io) or @io.eof?

        str = @io.gets
        scan(str) if str
      end
      @tokens.first
    end

    def skip_token
      @tokens.shift
      nil
    end

    def read_paren2
      return Null if peek_token == ')'

      car = read
      if peek_token == '.'
        skip_token # skip '.'
        Cons.new(car, read)
      elsif peek_token == ')'
        Cons.new(car, Null)
      else
        Cons.new(car, read_paren2)
      end
    end

    def read_paren
      raise UnexpectedToken unless peek_token == '('

      skip_token # (
      retval = read_paren2
      raise UnexpectedToken unless peek_token == ')'

      skip_token # )
      retval
    end

    public

    def buffer_reset
      @tokens = []
    end

    def buffer_empty?
      @tokens.empty?
    end

    def empty?
      buffer_empty? and ((!@io) or @io.eof?)
    end

    def read
      case peek_token
      when nil
        raise UnexpectedEndOfExpression
      when '.'
        raise UnexpectedDot
      when ')'
        raise UnexpectedRightParen
      when '('
        read_paren
      when '#('
        @tokens[0] = '(' # XXX
        Array(read_paren)
      when "'"
        skip_token
        Quote.new(read)
      when '`'
        skip_token
        BackQuote.new(read)
      when ','
        skip_token
        Unquote.new(read, false)
      when ',@'
        skip_token
        Unquote.new(read, true)
      else
        @tokens.shift

      end
    end

    def scan(str)
      str.scan(/(;.*)|(#?\()|(\))|(\.)|(['`])|(,@?)|("[^"\\]*(?:\\.[^"\\]*)*")|(?:#\\( |[^()\s]+))|([^()\s]+)/) do
        next if ::Regexp.last_match(1) # comment

        token = ::Regexp.last_match(2) if ::Regexp.last_match(2) # (sharp?) left paren
        token = ::Regexp.last_match(3) if ::Regexp.last_match(3) # right paren
        token = ::Regexp.last_match(4) if ::Regexp.last_match(4) # dot
        token = ::Regexp.last_match(5) if ::Regexp.last_match(5) # quote / back-quote
        token = ::Regexp.last_match(6) if ::Regexp.last_match(6) # unquote / unquote-splicing
        token = Character.new(::Regexp.last_match(8)) if ::Regexp.last_match(8) # character

        # double-quoted string
        if ::Regexp.last_match(7)
          token = ::Regexp.last_match(7)
          token = token.undump
        end

        if ::Regexp.last_match(9)
          token = ::Regexp.last_match(9).downcase
          token = case token
                  when '#t'
                    true
                  when '#f'
                    false
                  when /^[+-]?(?:[0-9]*)\.[0-9]*$/
                    token.to_f # floating number
                  when /^[+-]?[0-9]+$/
                    token.to_i # integer number
                  when %r{^([+-]?[0-9]+)/([0-9]+)$}
                    Rational(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i) # rational number
                  else
                    token.intern # symbol
                  end
        end

        @tokens.push(token)
      end

      self
    end
  end # class SexpReader
end # class Lisp
