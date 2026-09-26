import asyncdispatch, times
import types, queue

type
  WorkerRoutine*[R, A] = ref object
    id*: int
    active*: bool
    tasksProcessed*: int

proc newWorkerRoutine*[R, A](id: int): WorkerRoutine[R, A] =
  WorkerRoutine[R, A](id: id, active: true, tasksProcessed: 0)

proc runWorkerLoop*[R, A](
  worker: WorkerRoutine[R, A],
  queue: PriorityTaskQueue[R, A],
  isRunning: proc(): bool {.gcsafe.}
) {.async.} =
  while isRunning() and worker.active:
    var currentTask: Task[R, A]
    if queue.pop(currentTask):
      currentTask.status = StatusRunning
      try:
        let res = await currentTask.action(currentTask.argument)
        currentTask.status = StatusCompleted
        currentTask.promise.complete(res)
        inc worker.tasksProcessed
      except CatchableError as e:
        currentTask.status = StatusFailed
        currentTask.promise.fail(e)
    else:
      # Sleep lightly when idle to release the event loop
      await sleepAsync(5)
