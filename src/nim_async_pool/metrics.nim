## Runtime telemetry and metrics collector for nim_async_pool

import times, types

type
  PoolMetrics* = object
    totalTasksSubmitted*: uint64
    totalTasksCompleted*: uint64
    activeWorkersCount*: int
    pendingQueueDepth*: int
    avgExecutionTimeMs*: float
    uptimeSeconds*: float

  MetricsCollector* = ref object
    startTime: float
    completedCount: uint64
    totalExecutionTimeMs: float

proc newMetricsCollector*(): MetricsCollector =
  MetricsCollector(
    startTime: epochTime(),
    completedCount: 0,
    totalExecutionTimeMs: 0.0
  )

proc recordCompletion*(c: MetricsCollector, durationMs: float) =
  inc c.completedCount
  c.totalExecutionTimeMs += durationMs

proc snapshot*[R, A](c: MetricsCollector, pool: AsyncPool[R, A]): PoolMetrics =
  let now = epochTime()
  let avg = if c.completedCount > 0: c.totalExecutionTimeMs / float(c.completedCount) else: 0.0
  PoolMetrics(
    totalTasksSubmitted: pool.nextTaskId - 1,
    totalTasksCompleted: c.completedCount,
    activeWorkersCount: pool.workers.len,
    pendingQueueDepth: pool.queue.len,
    avgExecutionTimeMs: avg,
    uptimeSeconds: now - c.startTime
  )
