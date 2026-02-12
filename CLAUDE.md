# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rouge (る〜じゅ) is a Scheme-like Lisp interpreter written in Ruby, created in 2001.

## Commands

```bash
./rouge.rb                  # Start the REPL (exit with (bye) or (exit))
bundle install              # Install dev dependencies
bundle exec rake test       # Run the test suite (minitest)
bundle exec ruby test/test_parser.rb     # Run a single test file
```

## Architecture

The interpreter follows a classic Lisp architecture: parse → eval → print.

**Entry point**: `rouge.rb` — creates the VM, auto-loads all `lib/*.scm` files, then starts the REPL.

**Core modules** (all under `rouge/`):

| Module | Role |
|--------|------|
| `rouge.rb` | `Lisp` class — the evaluation engine (eval, apply, special form dispatch) |
| `parser.rb` | `SexpReader` — tokenizer and S-expression parser |
| `binding.rb` | `Binding` — hierarchical lexical scope / environment |
| `special-forms.rb` | `define`, `lambda`, `if`, `let`, `cond`, `catch/throw`, etc. |
| `functions.rb` | All built-in procedures (~730 lines): arithmetic, list ops, I/O, type predicates, Ruby interop (`ruby:eval`, `ruby:send`) |
| `lambda-closure.rb` | `LambdaClosure` — function objects with `&optional`, `&rest`, `&aux` parameter binding |
| `list.rb` | `Cons` cell, `Null`, list utilities |
| `quote.rb` | `Quote`, `BackQuote`, `Unquote` handling |
| `character.rb` | Character type with named characters (#\space, #\newline, etc.) |
| `port.rb` | File I/O ports |
| `console.rb` | REPL with optional readline support |
| `promise.rb` | `delay`/`force` (lazy evaluation) |

**Standard library** (`lib/*.scm`): Scheme files auto-loaded at startup providing list primitives (caar/cadr/etc.), character predicates, math functions (via Ruby interop), and I/O helpers.

## Key Design Points

- The `Lisp` class holds global bindings and dispatches evaluation. Special forms are registered in `@sp_forms` hash and built-in functions via `@global_binding.bind`.
- Environments use a parent-chain model (`Binding` with `@parent`). `let`/`lambda` create child bindings.
- Ruby interop is exposed through `ruby:eval` and `ruby:send` built-ins, used extensively in `lib/*.scm` for math and string operations.
- `define` only supports `(define sym expr)` form, not `(define (name args) body)` shorthand.
- The parser uses class-level `$` regex globals, which creates thread-safety issues (noted in TODO).
