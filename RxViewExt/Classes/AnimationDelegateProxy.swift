//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import Foundation
import QuartzCore
import RxSwift
import RxCocoa
import RxSwiftExt

public final class AnimationDelegateProxy: DelegateProxy, DelegateProxyType, CAAnimationDelegate {

    public enum Event {

        case didStart
        case didStop(Bool)
    }

    public static func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let animation = object as! CAAnimation
        return animation.delegate
    }

    public static func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let animation = object as! CAAnimation
        animation.delegate = delegate as? CAAnimationDelegate
    }

    private var forwardToDelegate: CAAnimationDelegate? {
        return self.forwardToDelegate() as? CAAnimationDelegate
    }

    private let _event = ReplaySubject<Event>.createUnbounded()
    public var event: Observable<Event> {
        return self._event
    }

    public var didStart: Observable<Void> {
        return self.event.filterMap { event in
            switch event {
            case .didStart:
                return .map(())
            default:
                return .ignore
            }
        }
    }

    public var didStop: Observable<Bool> {
        return self.event.filterMap { event in
            switch event {
            case .didStop(let finished):
                return .map(finished)
            default:
                return .ignore
            }
        }
    }

    public func animationDidStart(_ anim: CAAnimation) {
        self._event.onNext(.didStart)
        self.forwardToDelegate?.animationDidStart?(anim)
    }

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self._event.onNext(.didStop(flag))
        self.forwardToDelegate?.animationDidStop?(anim, finished: flag)
    }
}

public extension Reactive where Base: CAAnimation {

    public var delegate: AnimationDelegateProxy {
        return AnimationDelegateProxy.proxyForObject(self.base)
    }

    public func setDelegate(_ delegate: CAAnimationDelegate) -> Disposable {
        return AnimationDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: self.base)
    }
}
