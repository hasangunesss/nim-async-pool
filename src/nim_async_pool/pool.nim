import asyncdispatch, times
import types, queue, worker

type
  AsyncPool*[R, A] = ref object
    config*: PoolConfig
    state*: PoolState
    queue: PriorityTaskQueue[R, A]
    workers: seq[WorkerRoutine[R, A]]
    workerFutures: seq[Future[void]]
    nextTaskId: uint64

proc newAsyncPool*[R, A](
  workers: int = 4,
  queueCapacity: int = 1000,
  idleTimeoutMs: int = 5000
): AsyncPool[R, A] =
  let cfg = PoolConfig(
    minWorkers: workers,
    maxWorkers: workers,
    queueCapacity: queueCapacity,
    idleTimeoutMs: idleTimeoutMs
  )
  let q = newPriorityTaskQueue[R, A](queueCapacity)
  result = AsyncPool[R, A](
    config: cfg,
    state: PoolRunning,
    queue: q,
    workers: @[],
    workerFutures: @[],
    nextTaskId: 1
  )

  # Start initial worker set
  let poolRef = result
  for i in 0 ..< workers:
    let w = newWorkerRoutine[R, A](i)
    result.workers.add(w)
    result.workerFutures.add(
      runWorkerLoop[R, A](w, q, proc(): bool = poolRef.state != PoolStopped)
    )

proc spawn*[R, A](
  pool: AsyncPool[R, A],
  action: proc(arg: A): Future[R] {.closure, gcsafe.},
  argument: A,
  priority: TaskPriority = PriorityNormal
): Future[R] =
  if pool.state != PoolRunning:
    let failedFut = newFuture[R]("spawnFailed")
    failedFut.fail(newException(ValueError, "Pool is not accepting tasks"))
    return failedFut

  let promise = newFuture[R]("taskFuture")
  let task = Task[R, A](
    id: pool.nextTaskId,
    priority: priority,
    status: StatusPending,
    action: action,
    argument: argument,
    promise: promise,
    queuedAt: epochTime()
  )
  inc pool.nextTaskId

  if not pool.queue.push(task):
    promise.fail(newException(ResourceExhaustedError, "Task queue is full"))

  return promise

proc drain*[R, A](pool: AsyncPool[R, A]) {.async.} =
  pool.state = PoolDraining
  while pool.queue.len > 0:
    await sleepAsync(10)

proc shutdown*[R, A](pool: AsyncPool[R, A]) =
  pool.state = PoolStopped
  for w in pool.workers:
    w.active = false
