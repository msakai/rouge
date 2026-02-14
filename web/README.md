# Rouge Web REPL

Rouge Scheme インタプリタをブラウザ上で動作させる Web アプリケーション。

## 使い方

```bash
cd web
npm install
npm run dev      # 開発サーバー起動 (http://localhost:5173)
npm run build    # 本番ビルド (dist/ に出力)
npm run preview  # ビルド結果のプレビュー
```

## アーキテクチャ

### 全体構成

```
[メインスレッド]                    [Web Worker]
 xterm.js Terminal                  ruby.wasm (CRuby on WASI)
   │                                  │
   │ onData (キー入力)                │ $stdin.gets → WASI fd_read
   ├──→ 行バッファリング              │   → Atomics.wait (ブロック)
   ├──→ SharedArrayBuffer ──────────→ │   → データ読み取り
   │                                  │
   │ term.write (表示)                │ $stdout.write → WASI fd_write
   │ ←───── postMessage ←────────────┤   → postMessage で送信
   │                                  │
   │                                  │ consolePrinter (Ruby C レベル I/O)
   │ ←───── postMessage ←────────────┤   → puts/print 等のフック
```

### スレッド分離の理由

Ruby の `$stdin.gets` は同期的にブロックする。ブラウザのメインスレッドでは同期ブロックが不可能なため、
ruby.wasm を Web Worker 上で実行し、`SharedArrayBuffer` + `Atomics.wait` で stdin のブロッキング読み取りを実現している。

### ファイル構成

| ファイル | 役割 |
|---------|------|
| `src/main.ts` | メインスレッド: xterm.js ターミナル、行バッファリング、Worker 起動 |
| `src/worker.ts` | Worker: ruby.wasm/WASI セットアップ、仮想 FS マウント、Rouge 実行 |
| `src/stdin-buffer.ts` | SharedArrayBuffer ベースの stdin 読み書きプロトコル |
| `src/rouge-entry.rb` | WASM 用 Ruby エントリポイント (`rouge.rb` の代替) |
| `public/coi-serviceworker.js` | Cross-Origin Isolation ヘッダーの付与 (Service Worker) |

## Design Decisions

### 1. 既存 Ruby コードへの変更なし

`rouge/*.rb` と `lib/*.scm` は一切変更していない。
WASM 用のエントリポイント (`rouge-entry.rb`) を新規作成し、以下の差分のみ吸収:

- `Dir[]` glob の代わりに明示的なファイルリストで `lib/*.scm` をロード
- `$stdin.tty?` / `$stdout.tty?` を `true` に上書き (プロンプト表示のため)

### 2. stdin の行バッファリング (メインスレッド側)

Rouge の `Console.gets` は `$stdin.gets` を使い、改行 (`\n`) までを一行として読み取る。
メインスレッド側で xterm.js のキー入力を行バッファに蓄積し、Enter キーで完成した行を Worker に送信する。

これにより:
- ローカルエコー (入力文字の即時表示) をメインスレッドで処理
- Backspace による行内編集が可能
- Worker 側は行単位の `Atomics.wait` で済む

### 3. stdin の ready フラグ

Ruby VM の初期化中 (`vm.initialize`) に WASI `fd_read` (stdin) が呼ばれることがあり、
`Atomics.wait` でブロックすると初期化がハングする。

対策として `BlockingStdinFd` に `ready` フラグを設け:
- 初期化中 (`ready = false`): 空データを即座に返す (非ブロッキング)
- REPL 開始後 (`ready = true`): `Atomics.wait` でブロッキング読み取り

### 4. 出力の二重フック (WASI fd_write + consolePrinter)

Ruby の出力は2つの経路がある:

- **WASI `fd_write`**: `$stdout.write("rouge> ")` のような低レベル I/O → `PostMessageOutputFd` でキャプチャ
- **consolePrinter**: Ruby C レベルの `rb_io_write` 等のフック → `consolePrinter` コールバックでキャプチャ

`consolePrinter` は `vm.initialize` の完了に必須 (これなしでは初期化がハングする)。
両方が同じ `postMessage` で出力をメインスレッドに送信する。

### 5. WASI 仮想ファイルシステム

Ruby ソースと Scheme ライブラリを `@bjorn3/browser_wasi_shim` の `PreopenDirectory` で
WASI 仮想 FS にマウントしている:

```
/src/rouge/*.rb    ← rouge/*.rb (Vite の import.meta.glob + ?raw でバンドル)
/src/lib/*.scm     ← lib/*.scm
/src/rouge-entry.rb
```

`rouge-entry.rb` 内の `require_relative '/src/rouge/rouge'` や `vm.load("/src/lib/list.scm")` は
この仮想 FS 上のパスを参照する。

### 6. Cross-Origin Isolation

`SharedArrayBuffer` の使用には Cross-Origin Isolation が必要:

- **開発時**: Vite の `server.headers` で COOP/COEP ヘッダーを設定
- **本番デプロイ**: `coi-serviceworker.js` (gzuidhof/coi-serviceworker) が Service Worker として
  レスポンスに COOP/COEP ヘッダーを付与。GitHub Pages 等ヘッダー制御不可の環境で有効。

### 7. WASM バイナリの配信

`@ruby/3.4-wasm-wasi` パッケージの `ruby+stdlib.wasm` (~30MB) を使用し、Viteの `?url` を用いて配信する。

## 参考にしたプロジェクト

- **[irb.wasm](https://github.com/kateinoigakukun/irb.wasm)** — ブラウザ上で動作する IRB。
  ruby.wasm + xterm.js + `@bjorn3/browser_wasi_shim` の構成、`consolePrinter` の使い方、
  WASI 仮想 FS のマウント方法、VM 初期化シーケンスを参考にした。

- **[ruby.wasm](https://github.com/ruby/ruby.wasm)** — CRuby の WebAssembly ポート。
  `@ruby/wasm-wasi` (RubyVM, consolePrinter) と `@ruby/3.4-wasm-wasi` (WASM バイナリ) を使用。

- **[browser_wasi_shim](https://github.com/niccokunzmann/browser_wasi_shim)** — ブラウザ向け WASI 実装。
  `Fd` クラスのサブクラス化による stdin/stdout カスタマイズ、
  `PreopenDirectory` / `File` による仮想 FS 構築に使用。

- **[gzuidhof/coi-serviceworker](https://github.com/gzuidhof/coi-serviceworker)** —
  Service Worker による Cross-Origin Isolation ヘッダー付与。

## 既知の制限

- **ファイル I/O**: `(open-input-file)` / `(open-output-file)` は仮想 FS 上のファイルのみ
- **call/cc**: ruby.wasm で `callcc` が利用できない場合エラーとなる
- **初回ロード**: ruby.wasm バイナリ (~30MB) のダウンロードに時間がかかる
- **本番ビルド**: WASM バイナリの配置を別途設定する必要がある
