//
//  Future.swift
//  Based originially on swiftz code by Maxwell Swadling
//  With GCD additions by Rob Napier
//

import Foundation

private let sharedProcessingQueue = dispatch_queue_create("llama.future.shared-processing", DISPATCH_QUEUE_CONCURRENT)

public class Future<T> {
  private var _value: T?
  var onCompleteHandlers: [(Result<T> -> ())] = []

  // The resultQueue is used to read the result. It begins suspended
  // and is resumed once a result exists.
  // FIXME: Would like to add a uniqueid to the label
  let resultReadyGroup = dispatch_group_create()

  let mutateQueue = dispatch_queue_create("llama.future.value", DISPATCH_QUEUE_SERIAL)

  let processingQueue: dispatch_queue_t

  public init(queue: dispatch_queue_t = sharedProcessingQueue) {
    self.processingQueue = queue
    dispatch_group_enter(self.resultReadyGroup)
  }

  public convenience init(_ f: () -> T, queue: dispatch_queue_t = sharedProcessingQueue) {
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

  public func onComplete(f: Result<T> -> ()) {
    dispatch_async(mutateQueue) {
      self.onCompleteHandlers += [f]
    }
  }

  internal func completeWith(x: T) {
    dispatch_async(mutateQueue) {
      precondition(self._value == nil, "Future cannot complete more than once")
      self._value = x
      for handler in self.onCompleteHandlers { handler(success(x)) }
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
    return future { f(self.result()) }
  }

  public func flatMap<U>(f: T -> Future<U>) -> Future<U> {
    return future { f(self.result()).result() }
  }
}

func sequence<T>(futures: [Future<T>]) -> Future<[T]> {
  return future {
    futures.reduce([]) { acc, f in
      return acc + [f.result()]
    }
  }
}

// FIXME: This should be combinable with the Result version.
// But not sure how to define Functor without forcing Result and Future to be subclasses
// Result is an enum, so that's hard.
func <**><T,U>(x: Future<T>, f: T -> U) -> Future<U> {
  return x.map(f)
}

func future<T>(f: () -> T) -> Future<T> {
  return Future(f)
}
