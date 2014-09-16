//
//  Promise.swift
//  randomfetch
//
//  Created by Rob Napier on 8/31/14.
//  Copyright (c) 2014 Rob Napier. All rights reserved.
//

// A Promise manages a Future<Result<T>> that you complete manually (rather than with a computation)
//   Not yet implemented
//

import Foundation

public class Promise<T> {

  var future: Future<Result<T>> = Future()

  public func complete(result: Result<T>) {
    future.completeWith(result)
  }

  public func completeWith(future: Future<Result<T>>) {
    future.onComplete(self.future.completeWith{$0})
  }

  func map<U>(f: T -> U) -> Promise<U> {
    return Promise<U>().completeWith(self.future?.map { $0.map(f) })
  }

  func flatMap<U>(f: T -> Promise<U>) -> Promise<U> {
    return Promise<U>(future: async {
      return self.result().map(f).flatMap { $0.result() }
      })
  }

  func result() -> Result<T> {
    return future.result()
  }

  class func success(value: A) -> Promise<T> {
    return Promise(future: async { Result.Success(Box(value)) })
  }

  class func failure(error: NSError) -> Promise<T> {
    return Promise(future: async { Result.Failure(error) })
  }
}

func sequence<A>(promises: [Promise<T>]) -> Promise<[T]> {
  return Promise(future: async {
    sequence(promises.map{ $0.result() })
    })
}

func >>==<A,B>(a: Promise<A>, f: A -> Promise<B>) -> Promise<B> {
  return a.flatMap(f)
}

func <**><A,B>(a: Promise<A>, f: A -> B) -> Promise<B> {
  return a.map(f)
}

func forEach<T,U>(f: T -> Promise<U>)(array: [T]) -> Promise<[U]> {
  return sequence(array.map(f))
}

