
//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

public extension Reactive where Base: UIView {

    public func isStateHighlighted() -> Observable<Bool> {
        return self.state()
            .contains(.highlighted)
            .distinctUntilChanged()
    }

    public func buttonStyle() -> Disposable {
        let view = self.base
        return self
            .isStateHighlighted()
            .subscribe(onNext: { [weak view] shouldHighlight in
                guard let view = view else { return }

                view.alpha = shouldHighlight ? 1.0 : 0.4
                let animBlock = {
                    view.alpha = shouldHighlight ? 0.4 : 1.0
                }

                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: animBlock,
                    completion: nil)
            })
    }
}

public extension Reactive where Base: UIView {

    public static func animate(
        withDuration duration: TimeInterval?,
        delay: TimeInterval = 0,
        options: UIViewAnimationOptions = [],
        animations: @escaping () -> Void)
        -> Single<Bool>
    {
        let viewType = Base.self

        return Single<Bool>.create { single in

            let cancel = Disposables.create { }

            let completion: (Bool) -> Void = { finished in
                guard !cancel.isDisposed else { return }
                single(.success(finished))
            }

            guard let duration = duration else {
                animations()
                completion(true)
                return cancel
            }

            viewType.animate(
                withDuration: duration,
                delay: delay,
                options: options,
                animations: animations,
                completion: completion)

            return cancel
        }
    }

    public static func animate(
        withDuration duration: TimeInterval?,
        delay: TimeInterval = 0,
        usingSpringWithDamping damping: CGFloat,
        initialSpringVelocity velocity: CGFloat,
        options: UIViewAnimationOptions = [],
        animations: @escaping () -> Void)
        -> Single<Bool>
    {
        let viewType = Base.self

        return Single<Bool>.create { single in
            let cancel = Disposables.create { }

            let completion: (Bool) -> Void = { finished in
                guard !cancel.isDisposed else { return }
                single(.success(finished))
            }

            guard let duration = duration else {
                animations()
                completion(true)
                return cancel
            }

            viewType.animate(
                withDuration: duration,
                delay: delay,
                usingSpringWithDamping: damping,
                initialSpringVelocity: velocity,
                options: options,
                animations: animations,
                completion: completion)

            return cancel
        }
    }
}

public extension Single where Element == Bool {

    @discardableResult
    public func complete(_ completion: ((Element) -> Void)? = nil) -> Disposable {
        return self.asObservable()
            .catchErrorJustReturn(false)
            .subscribe(onNext: completion)
    }
}


public extension Reactive where Base: UIView {

    public static func animatePretty(
        withDuration duration: TimeInterval?,
        delay: TimeInterval = 0,
        animations: @escaping () -> Void)
        -> Single<Bool>
    {
        return self.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: 0.71,
            initialSpringVelocity: 0,
            animations: animations)
    }
}

public extension Reactive where Base: UIView {

    public var transform: UIBindingObserver<Base, CGAffineTransform> {
        return UIBindingObserver(UIElement: self.base) { view, transform in
            view.transform = transform
        }
    }
}

public extension Reactive where Base: UIView {

    public func pillStyle() -> Disposable {
        let layer = self.base.layer
        return self.observe(CGRect.self, "bounds").unwrap()
            .map({ min($0.width, $0.height) / 2 })
            .bind(to: layer.rx.cornerRadius)
    }
}
