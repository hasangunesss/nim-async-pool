import asyncdispatch, unittest
import ../src/nim_async_pool

suite "nim-async-pool test suite":

  test "basic task execution":
    proc runTest() {.async.} =
      let pool = newAsyncPool[int, int](workers = 2)
      proc doubleIt(x: int): Future[int] {.async.} =
        await sleepAsync(1)
        return x * 2

      let f1 = pool.spawn(doubleIt, 10)
      let f2 = pool.spawn(doubleIt, 25)

      check (await f1) == 20
      check (await f2) == 50

      await pool.drain()
      pool.shutdown()

    waitFor runTest()

  test "priority ordering under load":
    proc runTest() {.async.} =
      let pool = newAsyncPool[string, string](workers = 1, queueCapacity = 100)
      var order: seq[string] = @[]

      proc recordTask(name: string): Future[string] {.async.} =
        await sleepAsync(5)
        order.add(name)
        return name

      # Fill with high & normal
      let fNorm = pool.spawn(recordTask, "normal_task", PriorityNormal)
      let fHigh = pool.spawn(recordTask, "high_task", PriorityCritical)

      discard await fNorm
      discard await fHigh

      check order.len == 2
      await pool.drain()
      pool.shutdown()

    waitFor runTest()

echo "All tests passed successfully!"
