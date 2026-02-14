
- `isqrt`, `sinh`, `consh`, `tanh`, `asinh`, `acosh`, `atanh`
- `endp` で `cons` と `nil` 以外をエラーに
- `Thread.current["__inspect_key__"]` を使って。サイクルのあるデータをきちんと表示できるようにする。
- `eval` を、global環境ではなく呼び出した環境で評価するようにする。

# メモ

```scheme
(define values (things)
  (call-with-current-continuation
    (lambda (cont) (apply cont things))))

(call-with-values producer consumer)
(dynamic-wind before thunk after)
```
