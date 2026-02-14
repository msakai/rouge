require_relative '/src/rouge/rouge'
require_relative '/src/rouge/console'

# Override tty? to return true so that prompts are displayed
$stdin.define_singleton_method(:tty?) { true }
$stdout.define_singleton_method(:tty?) { true }

STDERR.write <<~EOT
  ==============================================================
  Rouge - Lisp Interpreter written in Ruby (WASM)

  Copyright (C) 2001 Masahiro Sakai
  This is free software with ABSOLUTELY NO WARRANTY.
  ==============================================================

EOT

STDERR.puts('initializing...')

vm = Lisp.new

%w[list list-misc character control math misc port string].each do |name|
  path = "/src/lib/#{name}.scm"
  STDERR.puts("loading #{path}")
  vm.load(path)
end

Lisp::Console.run(vm)
