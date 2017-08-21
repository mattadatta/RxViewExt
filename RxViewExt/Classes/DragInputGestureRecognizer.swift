//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import RxSwift
import RxSwiftExt
import RxCocoa
import RxGesture

public struct DragAction {

    public enum Event {

        case began
        case changed
        case ended
        case cancelled

        public var isStopEvent: Bool {
            switch self {
            case .ended: fallthrough
            case .cancelled:
                return true
            default:
                return false
            }
        }
    }

    public struct Info {

        public var location: CGPoint
        public var translation: CGPoint
        public var velocity: CGVector

        public init(location: CGPoint, translation: CGPoint, velocity: CGVector) {
            self.location = location
            self.translation = translation
            self.velocity = velocity
        }

        public static let zeroes = Info(location: .zero, translation: .zero, velocity: .zero)
    }

    public var event: Event
    public var info: Info

    public init(event: Event, info: Info) {
        self.event = event
        self.info = info
    }
}

public final class DragInputGestureRecognizer: UIPanGestureRecognizer {

    fileprivate var targetView: TargetView = .view

    private let _discreteDragActions = PublishSubject<DragAction>()

    public var discreteDragActions: Observable<DragAction> {
        return self._discreteDragActions
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self._discreteDragActions.onNext(DragAction(event: .began, info: self.currentDragInfo(in: self.targetView)))
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self._discreteDragActions.onNext(DragAction(event: .ended, info: self.currentDragInfo(in: self.targetView)))
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self._discreteDragActions.onNext(DragAction(event: .cancelled, info: self.currentDragInfo(in: self.targetView)))
    }

    public func currentDragInfo(in targetView: TargetView? = nil) -> DragAction.Info {
        let view = (targetView ?? self.targetView).targetView(for: self)
        return DragAction.Info(
            location: self.location(in: view),
            translation: self.translation(in: view),
            velocity: CGVector(self.velocity(in: view)))
    }
}

private extension CGVector {

    init(_ point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }
}

public extension Reactive where Base: UIView {

    public func dragInputGesture(
        in targetView: TargetView = .view,
        minimumNumberOfTouches: Int = 1,
        maximumNumberOfTouches: Int = 1,
        configuration: ((DragInputGestureRecognizer) -> Void)? = nil)
        -> Observable<DragAction>
    {
        let gestureRecognizer = DragInputGestureRecognizer()
        gestureRecognizer.targetView = targetView
        gestureRecognizer.minimumNumberOfTouches = minimumNumberOfTouches
        gestureRecognizer.maximumNumberOfTouches = maximumNumberOfTouches
        configuration?(gestureRecognizer)

        let discreteDragActions = gestureRecognizer.discreteDragActions
        let changeDragActions = self.gesture(gestureRecognizer).asDragAction(in: targetView)

        return Observable.merge(discreteDragActions, changeDragActions)
    }
}

private extension ObservableType where E: DragInputGestureRecognizer {

    func asDragAction(in view: TargetView = .view) -> Observable<DragAction> {
        return self
            .when(.changed)
            .map({ DragAction(event: .changed, info: $0.currentDragInfo(in: view)) })
    }
}
