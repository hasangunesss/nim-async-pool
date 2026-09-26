# 👑 nim-async-pool

High-performance asynchronous worker pool and concurrency primitives for Nim with task priority queues, backpressure handling, and graceful shutdown.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Nim](https://img.shields.io/badge/Nim-2.0%2B-FFE953.svg)](https://nim-lang.org)
[![Nimble](https://img.shields.io/badge/Nimble-0.2.0-yellow.svg)](https://github.com/hasangunesss/nim-async-pool)

## Features

- ⚡ **Zero-Overhead Asynchronous Execution** — Native integration with Nim's `asyncdispatch` event loop.
- 🎯 **Priority Queues** — Schedule tasks with granular priorities (`Low`, `Normal`, `High`, `Critical`).
- 🛡️ **Backpressure & Bounded Buffers** — Prevent memory exhaustion under sudden traffic spikes.
- 🔄 **Dynamic Scaling** — Automatically scale worker routines between configurable min/max bounds.
- 🛑 **Graceful Teardown** — Drain pending work with timeout guarantees during service termination.

## Installation

Install via Nimble:

```bash
nimble install nim_async_pool
```

Or clone manually:

```bash
git clone https://github.com/hasangunesss/nim-async-pool.git
cd nim-async-pool
nimble build
```

## Quick Start

```nim
import asyncdispatch, nim_async_pool

proc main() {.async.} =
  # Initialize worker pool with 4 concurrent workers
  let pool = newAsyncPool[string, int](
    workers = 4,
    queueCapacity = 1000
  )

  # Define async workload
  proc computeSquare(num: int): Future[string] {.async.} =
    await sleepAsync(10)
    return "Result: " & $(num * num)

  # Submit tasks with priorities
  let f1 = pool.spawn(computeSquare, 5, priority = PriorityHigh)
  let f2 = pool.spawn(computeSquare, 12, priority = PriorityNormal)

  echo await f1 # "Result: 25"
  echo await f2 # "Result: 144"

  # Clean teardown
  await pool.drain()
  pool.shutdown()

waitFor main()
```

## Running Tests

```bash
nim c -r tests/test_pool.nim
```

## License

MIT License - Copyright (c) 2024 Hasan Güneş
