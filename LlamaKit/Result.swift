/// Result
///
/// Container for a successful value (T) or a failure with an NSError
///

import Foundation

/// A success `Result` returning `value`
/// This form is preferred to `Result.Success(Box(value))` because it
// does not require dealing with `Box()`
public func success<T>(value: T) -> Result<T> {
  return .Success(Box(value))
}

/// A failure `Result` returning `error`
/// The default error is an empty one so that `failure()` is legal
/// To assign this to a variable, you must explicitly give a type.
/// Otherwise the compiler has no idea what `T` is. This form is preferred
/// to Result.Failure(error) because it provides a useful default.
/// For example:
///    let fail: Result<Int> = failure()
///
public func failure<T>(_ error: NSError = NSError(domain: "", code: 0, userInfo: nil)) -> Result<T> {
  return .Failure(error)
}

/// Container for a successful value (T) or a failure with an NSError
public enum Result<T> {
  case Success(Box<T>)
  case Failure(NSError)

  /// The successful value as an Optional
  func value() -> T? {
    switch self {
    case .Success(let box): return box.unbox
    case .Failure(_): return nil
    }
  }

  /// The failing error as an Optional
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

  /// Return a new result after applying a transformation to a successful value.
  /// Mapping a failure returns a new failure without evaluating the transform
  func map<U>(transform: T -> U) -> Result<U> {
    switch self {
    case Success(let box):
      return success(transform(box.unbox))
    case Failure(let err):
      return failure(err)
    }
  }

  /// Return a new result after applying a transformation (that itself
  /// returns a result) to a successful value.
  /// Flat mapping a failure returns a new failure without evaluating the transform
  func flatMap<U>(transform:T -> Result<U>) -> Result<U> {
    switch self {
    case Success(let value): return transform(value.unbox)
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

//
// Conversions for Arrays
// FIXME: It would be nice to apply these to SequenceType.
// It's unclear how to generate an initial value to pass to reduce.
// It may be possible using filter+map instead
//

/// Given an array of results, returns an array of successful values
public func successes<T>(results: [Result<T>]) -> [T] {
  return results.reduce([T]()) { successes, result in
    switch result {
    case .Success(let value): return successes + [value.unbox]
    case .Failure(_): return successes
    }
  }
}

// The following may work, but crashes the compiler in Xcode.
// It does compile if built from the commandline as just "xcrun swift main.swift"
// with no other options. radar://18305099
//
//public func successes<Seq: SequenceType, T where Seq.Generator.Element == Result<T>>(results: Seq) -> [T] {
//  return filter(results, { (x: Result<T>) -> Bool in x.isSuccess() })
//    .map{ $0.value()! }
//}

/// Given an array of results, returns an array of failing errors
func failures<T>(results: [Result<T>]) -> [NSError] {
  return results.reduce([NSError]()) { failures, result in
    switch result {
    case .Success(_): return failures
    case .Failure(let error): return failures + [error]
    }
  }
}

/// Given an array of results returns a result of an array. If any of the
/// results are failures, the returned result is a failure.
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

//
// Functional forms of methods
//

func map<T,U>(x: Result<T>, f: T -> U) -> Result<U> {
  return x.map(f)
}

func flatMap<T,U>(x: Result<T>, f: T -> Result<U>) -> Result<U> {
  return x.flatMap(f)
}


/// Note that while it is possible to use `==` on results that contain
/// an Equatable type, Result is not itself Equatable. This is because
/// T may not be Equatable, and there is no way in Swift to define protocol
/// conformance based on your specialization.
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

//
// Operators
//

/// flatMap (bind)
infix operator >>== {associativity left}
func >>==<T,U>(x: Result<T>, f: T -> Result<U>) -> Result<U> {
  return x.flatMap(f)
}

/// map (function first)
infix operator <*> {}
func <*><T,U>(f: T -> U, x: Result<T>) -> Result<U> {
  return x.map(f)
}

/// flipped map (value first, like >>==)
infix operator <**> { associativity left }
func <**><T,U>(x: Result<T>, f: T -> U) -> Result<U> {
  return x.map(f)
}

/// Failure coalescing
///    success(42) ?? 0 ==> 42
///    failure() ?? 0 ==> 0
func ??<T>(result: Result<T>, defaultValue: @autoclosure () -> T) -> T {
  switch result {
  case .Success(let value):
    return value.unbox
  case .Failure(let error):
    return defaultValue()
  }
}

//
// Box
//

/// Due to current swift limitations, we have to include this Box in Result.
/// Swift cannot handle an enum with multiple associated data (A, NSError) where one is of unknown size (A)
final public class Box<T> {
  let unbox: T
  init(_ value: T) { self.unbox = value }
}
