# Rouge (る〜じゅ)

Rubyで書いた、Lispの簡易的な処理系です。
Schemeっぽい感じを目指していますが、仕様はいい加減です。
2001年春学期の「記号処理プログラミング」のミニプロとして製作したものです。

（その後、Ruby 3.x で動作するように、若干のアップデートを加えています）

## 必要なもの

- Ruby >=2.5

## 使い方

```bash
./rouge.rb
```

`(bye)` で終了します。

## 開発

```bash
bundle install
bundle exec rake test
```

## Not a bug, but a feature(tm)

- 完全数/不完全数の概念をサポートしない

## サポートされていない(サポートしたい)機能

- 入出力周り
- 複素数リテラル
- マクロ
- マルチバイト文字
- (他にも沢山)

## ライセンス

Copyright (C) 2001 Masahiro Sakai.
All rights reserved.
This is free software with ABSOLUTELY NO WARRANTY.

This is distributed freely in the sence of 
GPL(GNU General Public License) or Ruby's licence.
