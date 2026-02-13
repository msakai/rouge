/**
 * SharedArrayBuffer-based stdin protocol for main thread ↔ worker communication.
 *
 * Buffer layout:
 *   Int32[0] = ready flag (0 = waiting, 1 = data available)
 *   Int32[1] = byte length of data
 *   Uint8[offset 8..] = data bytes
 */

const HEADER_BYTES = 8;
const FLAG_INDEX = 0;
const LENGTH_INDEX = 1;

/**
 * Writer side (main thread): writes a line into the shared buffer and notifies the worker.
 */
export class StdinWriter {
  private flag: Int32Array;
  private data: Uint8Array;

  constructor(private buffer: SharedArrayBuffer) {
    this.flag = new Int32Array(buffer, 0, 2);
    this.data = new Uint8Array(buffer, HEADER_BYTES);
  }

  write(text: string): void {
    const bytes = new TextEncoder().encode(text);
    if (bytes.length > this.data.length) {
      console.warn("stdin input too long, truncating");
    }
    const len = Math.min(bytes.length, this.data.length);
    this.data.set(bytes.subarray(0, len));
    Atomics.store(this.flag, LENGTH_INDEX, len);
    Atomics.store(this.flag, FLAG_INDEX, 1);
    Atomics.notify(this.flag, FLAG_INDEX);
  }
}

/**
 * Reader side (worker thread): blocks until data is available, then returns the bytes.
 */
export class StdinReader {
  private flag: Int32Array;
  private data: Uint8Array;

  constructor(private buffer: SharedArrayBuffer) {
    this.flag = new Int32Array(buffer, 0, 2);
    this.data = new Uint8Array(buffer, HEADER_BYTES);
  }

  /** Blocks (via Atomics.wait) until a line is available, then returns the bytes. */
  read(): Uint8Array {
    // Wait until flag becomes non-zero
    Atomics.wait(this.flag, FLAG_INDEX, 0);

    const len = Atomics.load(this.flag, LENGTH_INDEX);
    const result = new Uint8Array(len);
    result.set(this.data.subarray(0, len));
    // Reset flag for next read
    Atomics.store(this.flag, FLAG_INDEX, 0);
    return result;
  }
}
