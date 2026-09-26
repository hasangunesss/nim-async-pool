import std/[deques, algorithm]
import types

type
  PriorityTaskQueue*[R, A] = ref object
    highPriority: Deque[Task[R, A]]
    normalPriority: Deque[Task[R, A]]
    lowPriority: Deque[Task[R, A]]
    capacity*: int

proc newPriorityTaskQueue*[R, A](capacity: int = 1000): PriorityTaskQueue[R, A] =
  result = PriorityTaskQueue[R, A](
    highPriority: initDeque[Task[R, A]](),
    normalPriority: initDeque[Task[R, A]](),
    lowPriority: initDeque[Task[R, A]](),
    capacity: capacity
  )

proc len*[R, A](q: PriorityTaskQueue[R, A]): int =
  q.highPriority.len + q.normalPriority.len + q.lowPriority.len

proc isFull*[R, A](q: PriorityTaskQueue[R, A]): bool =
  q.len >= q.capacity

proc push*[R, A](q: PriorityTaskQueue[R, A], task: Task[R, A]): bool =
  if q.isFull:
    return false
  case task.priority
  of PriorityCritical, PriorityHigh:
    q.highPriority.addLast(task)
  of PriorityNormal:
    q.normalPriority.addLast(task)
  of PriorityLow:
    q.lowPriority.addLast(task)
  return true

proc pop*[R, A](q: PriorityTaskQueue[R, A], task: var Task[R, A]): bool =
  if q.highPriority.len > 0:
    task = q.highPriority.popFirst()
    return true
  if q.normalPriority.len > 0:
    task = q.normalPriority.popFirst()
    return true
  if q.lowPriority.len > 0:
    task = q.lowPriority.popFirst()
    return true
  return false
