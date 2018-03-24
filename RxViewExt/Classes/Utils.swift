//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

public extension SharedSequenceConvertibleType {

    public func unwrap<T>() -> SharedSequence<SharingStrategy, T> where E == Optional<T> {
        return self.filter({ $0 != nil }).map({ $0! })
    }
}

public extension ObservableType {

    public func optionally() -> Observable<E?> {
        return self.map({ $0 })
    }
}

public extension PrimitiveSequenceType where TraitType == SingleTrait {

    public func optionally() -> PrimitiveSequence<TraitType, ElementType?> {
        return self.map({ $0 })
    }
}

extension ObservableType {

    func map<T>(to: T) -> Observable<T> {
        return self.map({ _ in to })
    }
}

public extension ObservableType {

    public func ping() -> Observable<Void> {
        return self.map(to: ())
    }
}

public extension ObserverType where E == Void {

    public func push() {
        self.onNext(())
    }
}

public extension ObservableType {

    public func delayOnMain(by interval: RxTimeInterval) -> Observable<E> {
        return self.delay(interval, scheduler: ConcurrentMainScheduler.instance)
    }
}

public extension PrimitiveSequence {

    public func delayOnMain(by interval: RxTimeInterval) -> PrimitiveSequence<Trait, Element> {
        return self.delay(interval, scheduler: ConcurrentMainScheduler.instance)
    }
}

public extension ObservableType {

    public func prevAndNext() -> Observable<(E?, E)> {
        return self
            .scan((.none, .none), accumulator: { ($0.1, $1) })
            .map({ ($0, $1!) })
    }

    public func prevAndNext(initialElement: E) -> Observable<(E, E)> {
        return self
            .prevAndNext()
            .map({ ($0 ?? initialElement, $1) })
    }
}

public extension ObservableType where E: OptionSet {

    public func contains(_ e: E.Element) -> Observable<Bool> {
        return self.map({ $0.contains(e) })
    }
}

public enum Result<Element> {

    case element(Element)
    case error(Error)

    public var element: Element? {
        switch self {
        case .element(let element):
            return element
        default:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }

    public var isElement: Bool {
        return self.element != nil
    }

    public var isError: Bool {
        return self.error != nil
    }
}

public protocol ResultConvertible {

    associatedtype ElementType

    var result: Result<ElementType> { get }
}

extension Result: ResultConvertible {

    public var result: Result<Element> {
        return self
    }
}

public extension ObservableType {

    public func resulting() -> Observable<Result<E>> {
        return self
            .map({ .element($0) })
            .catchError({ .just(.error($0)) })
    }
}

public extension PrimitiveSequenceType where Self.TraitType == RxSwift.SingleTrait {

    public func resulting() -> PrimitiveSequence<TraitType, Result<ElementType>> {
        return self
            .map({ .element($0) })
            .catchError({ .just(.error($0)) })
    }
}

public extension ObservableType where E: ResultConvertible {

    public func resultingElements() -> Observable<E.ElementType> {
        return self
            .filter({ $0.result.isElement })
            .map({ $0.result.element! })
    }

    public func resultingErrors() -> Observable<Error> {
        return self
            .filter({ $0.result.isError })
            .map({ $0.result.error! })
    }

    public func optionalElements() -> Observable<E.ElementType?> {
        return self.map({ $0.result.element })
    }
}

public extension ObservableType {

    func bind <O: ObservableType> (into observable: O) -> Disposable where O.E: ObserverType, O.E.E == E {
        let source = self
        let iterDisposable = SerialDisposable()
        return Disposables.create(observable.subscribe { event in
            let disposable = SingleAssignmentDisposable()
            iterDisposable.disposable = disposable
            switch event {
            case .next(let observer):
                disposable.setDisposable(source.bind(to: observer))
            default:
                disposable.setDisposable(Disposables.create())
            }
        }, iterDisposable)
    }

    func bind <O: ObservableType> (into observable: O) -> Disposable where O.E == BehaviorRelay<E> {
        let source = self
        let iterDisposable = SerialDisposable()
        return Disposables.create(observable.subscribe { event in
            let disposable = SingleAssignmentDisposable()
            iterDisposable.disposable = disposable
            switch event {
            case .next(let relay):
                disposable.setDisposable(source.bind(to: relay))
            default:
                disposable.setDisposable(Disposables.create())
            }
        }, iterDisposable)
    }

    func bind <O: ObservableType, T> (into observable: O) -> Disposable where O.E == Optional<T>, T: ObserverType, T.E == E {
        let source = self
        let iterDisposable = SerialDisposable()
        return Disposables.create(observable.subscribe { event in
            let disposable = SingleAssignmentDisposable()
            iterDisposable.disposable = disposable
            switch event {
            case .next(let observer):
                if let observer = observer {
                    disposable.setDisposable(source.bind(to: observer))
                } else {
                    disposable.setDisposable(Disposables.create())
                }
            default:
                disposable.setDisposable(Disposables.create())
            }
        }, iterDisposable)
    }

    func bind <O: ObservableType> (into observable: O) -> Disposable where O.E == BehaviorRelay<E>? {
        let source = self
        let iterDisposable = SerialDisposable()
        return Disposables.create(observable.subscribe { event in
            let disposable = SingleAssignmentDisposable()
            iterDisposable.disposable = disposable
            switch event {
            case .next(let relay):
                if let relay = relay {
                    disposable.setDisposable(source.bind(to: relay))
                } else {
                    disposable.setDisposable(Disposables.create())
                }
            default:
                disposable.setDisposable(Disposables.create())
            }
        }, iterDisposable)
    }
}
