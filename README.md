# Rouge

慶應義塾大学SFCの2001年春学期の「記号処理プログラミング」（担当：安村 通晃）の課題（ミニプロ）として、Rubyで実装したScheme風の簡易的なLisp処理系です。
Scheme風を目指していますが、仕様はかなり簡略化したものです。
（その後、Ruby 3.x で対応と Web 版の実装などを行なっています）

🚀 Try on your browser: [WebAssembly Demo](https://msakai.github.io/rouge/) (no installation required!)

## 必要なもの

- Ruby >=2.5

## 使い方

```bash
bundle install
bundle exec rouge.rb
```

`(bye)` で終了します。

## 開発

```bash
bundle install
bundle exec rake test
```

### Lint (RuboCop)

[RuboCop](https://rubocop.org/) を使ってコードスタイルをチェックできます。

```bash
bundle exec rake rubocop              # lint を実行
bundle exec rake rubocop:autocorrect  # 自動修正可能な違反を修正
```

既存コードの違反は `.rubocop_todo.yml` に記録されています。
新しく書くコードは RuboCop のルールに従ってください。

## 制限

- 完全数/不完全数の概念をサポートしない

## 未サポート機能

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
