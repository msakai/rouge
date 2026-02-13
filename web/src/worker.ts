import { RubyVM, consolePrinter } from "@ruby/wasm-wasi";
import {
  WASI,
  File,
  PreopenDirectory,
  Fd,
  wasi as wasiDefs,
} from "@bjorn3/browser_wasi_shim";
import { StdinReader } from "./stdin-buffer";

// Import all Ruby source files as raw strings
const rougeRbFiles = import.meta.glob("../../rouge/*.rb", {
  query: "?raw",
  eager: true,
}) as Record<string, { default: string }>;

// Import all Scheme library files as raw strings
const libScmFiles = import.meta.glob("../../lib/*.scm", {
  query: "?raw",
  eager: true,
}) as Record<string, { default: string }>;

// Import the WASM entry point
import rougeEntryRaw from "./rouge-entry.rb?raw";

// Import Ruby WASM binary — Vite copies it to dist/assets/ and returns the URL
import rubyWasmUrl from "@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm?url";

/**
 * Custom stdin Fd that blocks on SharedArrayBuffer via Atomics.wait.
 */
class BlockingStdinFd extends Fd {
  private reader: StdinReader;
  private buffer: Uint8Array = new Uint8Array(0);
  private pos: number = 0;
  public ready: boolean = false;

  constructor(sharedBuffer: SharedArrayBuffer) {
    super();
    this.reader = new StdinReader(sharedBuffer);
  }

  fd_fdstat_get() {
    const fdstat = new wasiDefs.Fdstat(2, 0); // FILETYPE_CHARACTER_DEVICE, no flags
    fdstat.fs_rights_base = BigInt(1 << 1); // RIGHTS_FD_READ
    return { ret: 0, fdstat };
  }

  fd_read(size: number): { ret: number; data: Uint8Array } {
    if (!this.ready) {
      // During initialization, return empty (EOF-like) to avoid blocking
      return { ret: 0, data: new Uint8Array(0) };
    }
    if (this.pos >= this.buffer.length) {
      this.buffer = this.reader.read();
      this.pos = 0;
    }
    const available = this.buffer.length - this.pos;
    const readLen = Math.min(size, available);
    const data = this.buffer.slice(this.pos, this.pos + readLen);
    this.pos += readLen;
    return { ret: 0, data };
  }
}

/**
 * Custom stdout/stderr Fd that sends output to main thread via postMessage.
 */
class PostMessageOutputFd extends Fd {
  private msgType: string;
  private decoder = new TextDecoder();

  constructor(msgType: "stdout" | "stderr") {
    super();
    this.msgType = msgType;
  }

  fd_fdstat_get() {
    const fdstat = new wasiDefs.Fdstat(2, 1); // FILETYPE_CHARACTER_DEVICE, FDFLAGS_APPEND
    fdstat.fs_rights_base = BigInt(1 << 6); // RIGHTS_FD_WRITE
    return { ret: 0, fdstat };
  }

  fd_write(data: Uint8Array): { ret: number; nwritten: number } {
    const text = this.decoder.decode(data, { stream: true });
    self.postMessage({ type: this.msgType, text });
    return { ret: 0, nwritten: data.byteLength };
  }
}

/**
 * Build the WASI virtual filesystem with Rouge source files.
 */
function buildVirtualFS(): PreopenDirectory[] {
  const rougeDir = new Map<string, File>();
  for (const [path, mod] of Object.entries(rougeRbFiles)) {
    const filename = path.split("/").pop()!;
    rougeDir.set(filename, new File(new TextEncoder().encode(mod.default)));
  }

  const libDir = new Map<string, File>();
  for (const [path, mod] of Object.entries(libScmFiles)) {
    const filename = path.split("/").pop()!;
    libDir.set(filename, new File(new TextEncoder().encode(mod.default)));
  }

  const srcDir = new Map<string, any>();
  srcDir.set(
    "rouge-entry.rb",
    new File(new TextEncoder().encode(rougeEntryRaw))
  );

  return [
    new PreopenDirectory("/src/rouge", rougeDir),
    new PreopenDirectory("/src/lib", libDir),
    new PreopenDirectory("/src", srcDir),
  ];
}

let stdinBuffer: SharedArrayBuffer;

self.onmessage = async (e: MessageEvent) => {
  if (e.data.type === "init") {
    stdinBuffer = e.data.stdinBuffer;
    try {
      await startRuby();
    } catch (err) {
      self.postMessage({
        type: "stderr",
        text: `\r\nError: ${err}\r\n`,
      });
    }
  }
};

async function startRuby() {
  const stdinFd = new BlockingStdinFd(stdinBuffer);
  const stdoutFd = new PostMessageOutputFd("stdout");
  const stderrFd = new PostMessageOutputFd("stderr");

  const virtualFS = buildVirtualFS();
  const fds: Fd[] = [stdinFd, stdoutFd, stderrFd, ...virtualFS];

  const args = ["rouge.wasm"];
  const env = ["TERM=xterm-256color"];
  const wasi = new WASI(args, env, fds, { debug: false });

  const vm = new RubyVM();

  // consolePrinter provides Ruby C-level I/O hooks required for vm.initialize
  const printer = consolePrinter({
    stdout: (text: string) => {
      self.postMessage({ type: "stdout", text });
    },
    stderr: (text: string) => {
      self.postMessage({ type: "stderr", text });
    },
  });

  const imports: WebAssembly.Imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  printer.addToImports(imports);
  vm.addToImports(imports);

  // Fetch and instantiate the Ruby WASM binary
  const msg = (text: string) =>
    self.postMessage({ type: "stderr", text: text + "\r\n" });

  msg("Downloading Ruby WASM runtime...");

  const response = await fetch(rubyWasmUrl);
  if (!response.ok) {
    throw new Error(`Failed to fetch Ruby WASM: ${response.statusText}`);
  }
  const wasmBytes = await response.arrayBuffer();
  const wasmModule = await WebAssembly.compile(wasmBytes);

  msg("Initializing Ruby VM...");
  const instance = await WebAssembly.instantiate(wasmModule, imports);

  printer.setMemory(instance.exports.memory as WebAssembly.Memory);
  await vm.setInstance(instance);
  wasi.initialize(instance as any);
  (instance.exports._initialize as Function)();
  vm.initialize(args);

  // Enable blocking stdin now that initialization is complete
  stdinFd.ready = true;

  // Run the Rouge entry point
  vm.eval(rougeEntryRaw);
}
