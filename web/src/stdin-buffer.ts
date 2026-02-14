/**
 * SharedArrayBuffer-based stdin protocol for main thread ↔ worker communication.
 *
 * Buffer layout:
 *   Int32[0] = ready flag (0 = waiting, 1 = data available)
 *   Int32[1] = byte length of data
 *   Int32[2] = finished flag (0 = more data coming, 1 = this is the last chunk)
 *   Uint8[offset 12..] = data bytes
 */

const HEADER_WORDS = 3; // Number of Int32 words reserved for header (flags, length, etc.)
const HEADER_BYTES = HEADER_WORDS * Int32Array.BYTES_PER_ELEMENT;
const FLAG_INDEX = 0;
const LENGTH_INDEX = 1;
const FINISHED_INDEX = 2;

/**
 * Writer side (main thread): writes a line into the shared buffer and notifies the worker.
 * Queues lines internally so that a second write() before the worker finishes reading
 * does not overwrite the buffer.
 */
export class StdinWriter {
  private flag: Int32Array;
  private data: Uint8Array;
  private queue: Uint8Array[] = [];
  private flushing = false;

  constructor(private buffer: SharedArrayBuffer) {
    this.flag = new Int32Array(buffer, 0, HEADER_WORDS);
    this.data = new Uint8Array(buffer, HEADER_BYTES);
  }

  write(text: string): void {
    const bytes = new TextEncoder().encode(text);
    this.queue.push(bytes);
    this.flushQueue();
  }

  private async flushQueue(): Promise<void> {
    if (this.flushing) return;
    this.flushing = true;
    while (this.queue.length > 0) {
      let bytes = this.queue.shift()!;
      await this.writeBytes(bytes);
    }
    this.flushing = false;
  }

  private async writeBytes(bytes: Uint8Array): Promise<void> {
    while (bytes.length > 0) {
      // Wait until the reader has consumed the previous data (flag == 0)
      await Atomics.waitAsync(this.flag, FLAG_INDEX, 1).value;

      const len = Math.min(bytes.length, this.data.length);
      this.data.set(bytes.subarray(0, len));
      bytes = bytes.subarray(len);
      Atomics.store(this.flag, LENGTH_INDEX, len);
      Atomics.store(this.flag, FINISHED_INDEX, bytes.length === 0 ? 1 : 0);
      Atomics.store(this.flag, FLAG_INDEX, 1);
      Atomics.notify(this.flag, FLAG_INDEX);
    }
  }
}

/**
 * Reader side (worker thread): blocks until data is available, then returns the bytes.
 */
export class StdinReader {
  private flag: Int32Array;
  private data: Uint8Array;

  constructor(private buffer: SharedArrayBuffer) {
    this.flag = new Int32Array(buffer, 0, HEADER_WORDS);
    this.data = new Uint8Array(buffer, HEADER_BYTES);
  }

  /** Blocks (via Atomics.wait) until a line is available, then returns the bytes. */
  read(): Uint8Array {
    const buffers: Uint8Array[] = [];

    while (true) {
      // Wait until flag becomes non-zero
      Atomics.wait(this.flag, FLAG_INDEX, 0);

      const len = Atomics.load(this.flag, LENGTH_INDEX);
      const finished = Atomics.load(this.flag, FINISHED_INDEX) === 1;
      const bytes = new Uint8Array(len);
      bytes.set(this.data.subarray(0, len));
      buffers.push(bytes);

      // Reset flag for next read
      Atomics.store(this.flag, FLAG_INDEX, 0);
      Atomics.notify(this.flag, FLAG_INDEX);

      if (finished) break;
    }

    return this.concatBuffers(buffers);
  }

  private concatBuffers(buffers: Uint8Array[]): Uint8Array {
    const totalLength = buffers.reduce((sum, b) => sum + b.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    for (const b of buffers) {
      result.set(b, offset);
      offset += b.length;
    }
    return result;
  }
}
