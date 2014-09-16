//
//  Future.swift
//  Based originially on swiftz code by Maxwell Swadling
//  With GCD additions by Rob Napier
//

import Foundation

private let sharedFutureProcessingQueue = dispatch_queue_create("llama.future.shared-processing", DISPATCH_QUEUE_CONCURRENT)

public class Future<T> {

  let resultReadyGroup = dispatch_group_create()
  let mutateQueue = dispatch_queue_create("llama.future.value", DISPATCH_QUEUE_SERIAL)
  let processingQueue: dispatch_queue_t

  private var _value: T?

  internal init(queue: dispatch_queue_t) {
    self.processingQueue = queue
    dispatch_group_enter(self.resultReadyGroup)
  }

  public convenience init(queue: dispatch_queue_t, _ f: () -> T) {
    self.init(queue: queue)
    dispatch_async(self.processingQueue) { self.completeWith(f()) }
  }

  public func isCompleted() -> Bool {
    var isCompleted: Bool = false
    dispatch_sync(self.mutateQueue) {
      isCompleted = self._value != nil
    }
    return isCompleted
  }

  public func onComplete(f: T -> ()) {
    dispatch_group_notify(self.resultReadyGroup, processingQueue) { f(self._value!) }
  }

  internal func completeWith(x: T) {
    dispatch_async(mutateQueue) {
      precondition(self._value == nil, "Future cannot complete more than once")
      self._value = x
      dispatch_group_leave(self.resultReadyGroup)
    }
  }

  public func result() -> T {
    return self.waitResult()!
  }

  public func waitResult(timeout: dispatch_time_t = DISPATCH_TIME_FOREVER) -> T? {
    if dispatch_group_wait(self.resultReadyGroup, timeout) == 0 {
      return self._value!
    } else {
      return nil
    }
  }

  public func map<U>(f: T -> U) -> Future<U> {
    let newFuture = Future<U>(queue: self.processingQueue)
    self.onComplete { x in newFuture.completeWith(f(x)) }
    return newFuture
  }

  public func flatMap<U>(f: T -> Future<U>) -> Future<U> {
    let newFuture = Future<U>(queue: self.processingQueue)
    self.onComplete { x in newFuture.completeWith(f(x).result()) }
    return newFuture
  }
}

public func sequence<T>(futures: [Future<T>]) -> Future<[T]> {
  return future {
    return futures.reduce([T]()) { acc, x in acc + [x.result()] }
  }
}

// FIXME: This should be combinable with the Result version.
// But not sure how to define Functor without forcing Result and Future to be subclasses
// Result is an enum, so that's hard.
public func <**><T,U>(x: Future<T>, f: T -> U) -> Future<U> {
  return x.map(f)
}

public func future<T>(f: () -> T) -> Future<T> {
  return sharedFutureProcessingQueue.future(f)
}

extension dispatch_queue_t {
  final func future<T>(f: () -> T) -> Future<T> {
    return Future(queue: self, f)
  }
}
