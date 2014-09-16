//
//  Task.swift
//  LlamaKit
//
//  Created by Rob Napier on 9/11/14.
//  Copyright (c) 2014 Rob Napier. All rights reserved.
//

import Foundation

//
// A Task manages a Future<Result<T>>
//  Not yet implemented

//public class Task<T> {
//  let future: Future<Result<T>>
//
//  internal init(future: Future<Result<T>>) {
//    self.future = future
//  }
//
//  convenience init(queue: dispatch_queue_t, _ f: () -> Result<T>) {
//    self.init(future: Future(queue: queue, f))
//  }
//
//  public func isCompleted() -> Bool { return self.future.isCompleted() }
//  public func onComplete(f: Result<T> -> ()) { self.future.onComplete(f) }
//  public func result() -> Result<T> { return self.future.result() }
//
//  public func waitResult(timeout: dispatch_time_t = DISPATCH_TIME_FOREVER) -> Result<T>? {
//    return self.future.waitResult(timeout: timeout)
//  }
//
//  public func map<U>(f: T -> U) -> Task<U> {
//    let newFuture = self.future.map { (result: Result<T>) -> Result<U> in
//      result.map(f)
//    }
//    return Task<U>(future:newFuture)
//  }
//
//  public func flatMap<U>(f: T -> Task<U>) -> Task<U> {
//    let newFuture = self.future.flatMap { (result: Result<T>) -> Future<U> in
//      result.map( )
//    }
//
//  }
//
//
//}