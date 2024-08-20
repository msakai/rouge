# coding: utf-8
# Copyright (C) 2001 Masahiro Sakai <s01397ms@sfc.keio.ac.jp>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# This is distributed freely in the sence of
# GPL(GNU General Public License) or Ruby's licence.

require 'complex'
require 'rational'
require 'mathn'

class Lisp

  class VMError < RuntimeError
  end

  #############################################################################
  # データ構造
  #############################################################################

  class SExpObject
    def evaluate(vm_binding)
      self
    end

    def to_sexp
      self.inspect
    end
  end


  class <<(Unspecified = Object.new)
    def inspect
      "<unspecified>"
    end
  end

  #############################################################################
  # インタプリタ本体
  #############################################################################

  attr_reader :global_binding
  attr_reader :sp_forms

  def initialize
    @sp_forms = ({})
    @global_binding = Binding.new(self)

    define_sp_forms()
    define_builtin_symbols()
  end

  ########

  def evaluate(obj, vm_binding = @global_binding)
    case obj
    when SExpObject
      obj.evaluate(vm_binding)
    when Symbol
      val = vm_binding[obj]
      raise Binding::NotBoundedError, format("%s is not bounded", obj.id2name) unless val
      val
    else
      obj
    end
  end

  # FIXME
  def load_from_string(sexp)
    reader = SexpReader.new.scan(sexp)
    while true
      begin
        evaluate(reader.read)
      rescue SexpReader::UnexpectedEndOfExpression
        break
      end
    end
  end

  def self.Sexp(obj, dump = false)
    case obj
    when SExpObject
      obj.to_sexp
    when Symbol
      # FIXME
      obj.id2name
    when TrueClass
      '#t'
    when FalseClass
      '#f'
    when Array
      '#(' + obj.collect{|item| Sexp(item)}.join(" ") + ')'
    when Numeric
      str = String(obj)
    when String
      if dump
        obj.dump
      else
        obj
      end
    else
      obj.inspect
    end
  end

  def Sexp(obj, dump = false)
    type.Sexp(obj, dump)
  end

  #############################################################################
  # ユーティリティー等
  #############################################################################
=begin
  def binding_cutter(callable)
    lambda{ |binding, *args|
      callable.call(*args)
    }
  end
=end

end

require 'rouge/compat'
require 'rouge/binding'
require 'rouge/lambda-closure'
require 'rouge/list'
require 'rouge/quote'
require 'rouge/character'
require 'rouge/special-forms'
require 'rouge/functions'
require 'rouge/parser'
