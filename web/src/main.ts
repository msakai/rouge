import { Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import "@xterm/xterm/css/xterm.css";
import { StdinWriter } from "./stdin-buffer";

const term = new Terminal({
  cursorBlink: true,
  convertEol: true,
  fontFamily: "monospace",
  fontSize: 14,
});

const fitAddon = new FitAddon();
term.loadAddon(fitAddon);
term.open(document.getElementById("terminal")!);
fitAddon.fit();
window.addEventListener("resize", () => fitAddon.fit());

// Hide loading indicator
document.getElementById("loading")!.style.display = "none";

// SharedArrayBuffer for stdin communication (4KB)
const stdinBuffer = new SharedArrayBuffer(4096);
const stdinWriter = new StdinWriter(stdinBuffer);

// Line buffer for accumulating keystrokes before sending to worker
let lineBuffer = "";

// Spawn worker
const worker = new Worker(new URL("./worker.ts", import.meta.url), {
  type: "module",
});

worker.postMessage({ type: "init", stdinBuffer });

// Display output from worker
worker.onmessage = (e: MessageEvent) => {
  const { type, text } = e.data;
  if (type === "stdout" || type === "stderr") {
    term.write(text);
  }
};

// Handle terminal input with line buffering
term.onData((data: string) => {
  for (const ch of data) {
    if (ch === "\r") {
      // Enter: send the buffered line to the worker
      term.write("\r\n");
      stdinWriter.write(lineBuffer + "\n");
      lineBuffer = "";
    } else if (ch === "\x7f" || ch === "\b") {
      // Backspace: remove last character
      if (lineBuffer.length > 0) {
        lineBuffer = lineBuffer.slice(0, -1);
        term.write("\b \b");
      }
    } else if (ch === "\x03") {
      // Ctrl+C: clear current line
      lineBuffer = "";
      term.write("^C\r\n");
    } else if (ch >= " " || ch === "\t") {
      // Printable character or tab
      lineBuffer += ch;
      term.write(ch);
    }
  }
});

term.focus();
