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

public func failure<T>(_ error: NSError = NSError(domain: "", code: 0, userInfo: nil)) -> Result<T> {
  return .Failure(error)
}

public enum Result<T> {
  case Success(Box<T>)
  case Failure(NSError)

  func value() -> T? {
    switch self {
    case .Success(let box): return box.unbox
    case .Failure(_): return nil
    }
  }

  func error() -> NSError? {
    switch self {
    case .Success(_): return nil
    case .Failure(let err): return err
    }
  }

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

public func == <T: Equatable>(lhs: Result<T>, rhs: Result<T>) -> Bool {
  switch (lhs, rhs) {
  case (.Success(_), .Success(_)): return lhs.value() == rhs.value()
  case (.Success(_), .Failure(_)): return false
  case (.Failure(let lhsErr), .Failure(let rhsErr)): return lhsErr == rhsErr
  case (.Failure(_), .Success(_)): return false
  }
}

public func != <T: Equatable>(lhs: Result<T>, rhs: Result<T>) -> Bool {
  return !(lhs == rhs)
}

// Due to current swift limitations, we have to include this Box in Result.
// Swift cannot handle an enum with multiple associated data (A, NSError) where one is of unknown size (A)
final public class Box<T> {
  let unbox: T
  init(_ value: T) { self.unbox = value }
}

infix operator >>== {associativity left}

func >>==<T,U>(x: Result<T>, f: T -> Result<U>) -> Result<U> {
  return x.flatMap(f)
}

infix operator <*> {}

func <*><T,U>(f: T -> U, x: Result<T>) -> Result<U> {
  return x.map(f)
}

infix operator <**> {}
func <**><T,U>(x: Result<T>, f: T -> U) -> Result<U> {
  return x.map(f)
}

func flatMap<T,U>(x: Result<T>, f: T -> Result<U>) -> Result<U> {
  return x.flatMap(f)
}

public func successes<T>(results: [Result<T>]) -> [T] {
  return results.reduce([T]()) { successes, result in
    switch result {
    case .Success(let value): return successes + [value.unbox]
    case .Failure(_): return successes
    }
  }
}

func failures<T>(results: [Result<T>]) -> [NSError] {
  return results.reduce([NSError]()) { failures, result in
    switch result {
    case .Success(_): return failures
    case .Failure(let error): return failures + [error]
    }
  }
}

func sequence<T>(results: [Result<T>]) -> Result<[T]> {
  return results.reduce(success([T]())) { acc, result in
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
