import asyncdispatch

type
  TaskPriority* = enum
    PriorityLow = 0
    PriorityNormal = 1
    PriorityHigh = 2
    PriorityCritical = 3

  TaskStatus* = enum
    StatusPending
    StatusRunning
    StatusCompleted
    StatusFailed
    StatusCancelled

  Task*[R, A] = ref object
    id*: uint64
    priority*: TaskPriority
    status*: TaskStatus
    action*: proc(arg: A): Future[R] {.closure, gcsafe.}
    argument*: A
    promise*: Future[R]
    queuedAt*: float

  PoolConfig* = object
    minWorkers*: int
    maxWorkers*: int
    queueCapacity*: int
    idleTimeoutMs*: int

  PoolState* = enum
    PoolRunning
    PoolDraining
    PoolStopped
