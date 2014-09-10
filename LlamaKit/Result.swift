//
//  result.swift
//  LlamaKit
//
//  Created by Rob Napier on 9/9/14.
//  Copyright (c) 2014 Rob Napier. All rights reserved.
//

import Foundation

public func success<T>(value: T) -> Result<T> {
  return .Success(Box(value))
}

public func failure<T>(error: NSError) -> Result<T> {
  return .Failure(error)
}

public enum Result<T> {
  case Success(Box<T>)
  case Failure(NSError)

  func isSuccess() -> Bool {
    switch self {
    case .Success(_): return true
    case .Failure(_): return false
    }
  }


  func map<U>(f: T -> U) -> Result<U> {
    switch self {
    case Success(let box):
      return success(f(box.unbox))
    case Failure(let err):
      return failure(err)
    }
  }

  func flatMap<U>(f:T -> Result<U>) -> Result<U> {
    switch self {
    case Success(let value): return f(value.unbox)
    case Failure(let error): return .Failure(error)
    }
  }
}

extension Result: Printable {
  public var description: String {
    switch self {
    case .Success(let box):
      return "Success: \(box.unbox)"
    case .Failure(let error):
      return "Failure: \(error.localizedDescription)"
      }
  }
}

// Due to current swift limitations, we have to include this Box in Result.
// Swift cannot handle an enum with multiple associated data (A, NSError) where one is of unknown size (A)
final public class Box<T> {
  let unbox: T
  init(_ value: T) { self.unbox = value }
}

infix operator >>== {associativity left}

func >>==<A,B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
  return a.flatMap(f)
}

infix operator <*> {associativity left}

func <*><A,B>(f: A -> B, a: Result<A>) -> Result<B> {
  return a.map(f)
}

infix operator <**> {associativity left}
func <**><A,B>(a: Result<A>, f: A -> B) -> Result<B> {
  return a.map(f)
}

infix operator <^> {associativity left}

func <^><A,B>(f: A -> B, a: A) -> Result<B> {
  return f <*> .Success(Box(a))
}

func flatMap<A,B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
  return a.flatMap(f)
}

func successes<A>(results: [Result<A>]) -> [A] {
  return results.reduce([A]()) { successes, result in
    switch result {
    case .Success(let value): return successes + [value.unbox]
    case .Failure(_): return successes
    }
  }
}

func failures<A>(results: [Result<A>]) -> [NSError] {
  return results.reduce([NSError]()) { failures, result in
    switch result {
    case .Success(_): return failures
    case .Failure(let error): return failures + [error]
    }
  }
}

func sequence<A>(results: [Result<A>]) -> Result<[A]> {
  return results.reduce(Result.Success(Box([A]()))) { acc, result in
    switch (acc, result) {
    case (.Success(let successes), .Success(let success)):
      return .Success(Box(successes.unbox + [success.unbox]))
    case (.Success(let successes), .Failure(let error)):
      return .Failure(error)
    default: return acc
    }
  }
}

func ??<T>(result: Result<T>, defaultValue: @autoclosure () -> T) -> T {
  switch result {
  case .Success(let value):
    return value.unbox
  case .Failure(let error):
    return defaultValue()
  }
}
