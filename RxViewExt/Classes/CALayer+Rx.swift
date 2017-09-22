//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import RxSwift
import RxCocoa
import RxSwiftExt

public extension Reactive where Base: UIView {

    public func animateCornerRadius(
        withDuration duration: TimeInterval?,
        fromRadius: CGFloat? = nil,
        toRadius: CGFloat)
        -> Single<Bool>
    {
        let view = self.base
        let layer = view.layer
        let fromRadius = fromRadius ?? view.layer.cornerRadius

        return Single<Bool>.create { single in
            let animationKeyPath = "cornerRadius"

            let cancel = Disposables.create {
                layer.removeAnimation(forKey: animationKeyPath)
            }

            let completion: (Bool) -> Void = { finished in
                guard !cancel.isDisposed else { return }
                single(.success(finished))
            }

            guard let duration = duration.flatMap({ CFTimeInterval($0) }) else {
                layer.cornerRadius = toRadius
                completion(true)
                return cancel
            }

            let anim = CABasicAnimation(keyPath: animationKeyPath)
            anim.fromValue = fromRadius
            anim.toValue = toRadius
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            anim.duration = duration
            layer.add(anim, forKey: animationKeyPath)
            layer.cornerRadius = toRadius

            return Disposables.create(
                anim.rx.delegate
                    .didStop
                    .subscribe(onNext: completion),
                cancel)
        }
    }
}

public extension Reactive where Base: CALayer {

    public var cornerRadius: UIBindingObserver<Base, CGFloat> {
        return UIBindingObserver(UIElement: self.base) { layer, cornerRadius in
            layer.cornerRadius = cornerRadius
        }
    }
}

public extension Reactive where Base: CALayer {

    public func animate<Type>(
        keyPath: String,
        duration: TimeInterval?,
        fromValue: Type?,
        toValue: Type?,
        timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        -> Single<Type?>
    {
        let layer = self.base
        return Single.create { single in
            guard let duration = duration else {
                single(.success(toValue))
                return Disposables.create()
            }

            let anim = CABasicAnimation(keyPath: keyPath)
            if let fromValue = fromValue {
                anim.fromValue = fromValue
            }
            if let toValue = toValue {
                anim.toValue = toValue
            }
            anim.fillMode = kCAFillModeForwards
            anim.isRemovedOnCompletion = false
            anim.timingFunction = timingFunction
            anim.duration = duration

            let disposable = anim.rx.delegate
                .didStop
                .subscribe(onNext: { finished in
                    layer.removeAnimation(forKey: keyPath)
                    single(.success(toValue))
                })

            layer.add(anim, forKey: keyPath)

            return disposable
        }
    }
}

public extension Reactive where Base: CAShapeLayer {

    public var path: UIBindingObserver<Base, CGPath?> {
        return UIBindingObserver(UIElement: self.base) { layer, path in
            layer.path = path
        }
    }

    public var lineWidth: UIBindingObserver<Base, CGFloat> {
        return UIBindingObserver(UIElement: self.base) { layer, lineWidth in
            layer.lineWidth = lineWidth
        }
    }
}
