//
//  NKFloatingViewHandler.swift
//  NKFloatingViewHandler
//
//  Created by Nam Kennic on 5/2/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
//import TweenKit

public enum NKFloatingPosition: Int {
	case topLeft
	case topRight
	case bottomLeft
	case bottomRight
}

public protocol NKFloatingViewHandlerProtocol: class {
	var containerView: UIView! { get }
	var gestureView: UIView! { get }
//	var panGesture: UIPanGestureRecognizer! { get }
	var fullRect: CGRect { get }
//	var floatingRect: CGRect { get }
	
	func floatingRect(for position: NKFloatingPosition) -> CGRect
	func floatingHandlerDidDragging(with progress: CGFloat)
	func floatingHandlerDidDismiss()
}

public enum DragDirection {
	case none, up, down, left, right
}

open class NKFloatingViewHandler: NSObject {
	open weak var delegate: NKFloatingViewHandlerProtocol?
	open var swipeLeftToDismiss = true
	open var swipeRightToDismiss = true
	open var allowsCornerDocking = true
	open var isEnabled: Bool = true {
		didSet {
			tapGesture.isEnabled = isEnabled
			panGesture.isEnabled = isEnabled
		}
	}
	
	public fileprivate(set) var floatingProgress: CGFloat = 0
	public fileprivate(set) var isHorizontalDragging = false
	public fileprivate(set) var isVerticalDragging = false
	public fileprivate(set) var currentFloatingPosition: NKFloatingPosition?
	public var initPosition: NKFloatingPosition = .bottomRight
	
	fileprivate var floatingMode = false
	fileprivate var dragDirection: DragDirection = .none
	fileprivate var tweenAction: ActionScrubber!
	fileprivate var scaleAction = ActionScheduler()
	fileprivate var panGesture: UIPanGestureRecognizer!
	fileprivate var tapGesture: UITapGestureRecognizer!
	
	open var isFloatingMode: Bool {
		get {
			return floatingMode
		}
		set {
			if newValue {
				becomeFloating()
			} else {
				backToNormalState()
			}
		}
	}
	
	convenience init(target: NKFloatingViewHandlerProtocol!) {
		self.init()
		
		self.delegate = target
		setup()
		
		#if swift(>=4.2)
		NotificationCenter.default.addObserver(self, selector: #selector(updatePosition),
                                               name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(updatePosition),
                                               name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
		#endif
	}
	
	// MARK: -
	
	open func becomeFloating(position: NKFloatingPosition = .bottomRight) {
		floatingMode = true
		currentFloatingPosition = position
		tapGesture.isEnabled = true
		
		if position == .bottomLeft || position == .bottomRight {
			initPosition = position
		}
		
		guard let delegate = self.delegate else { return }
		
		let action = InterpolationAction(from: delegate.containerView.frame, to: delegate.floatingRect(for: position),
                                         duration: 0.35, easing: .exponentialOut) { [weak self] in
			self?.delegate?.containerView.frame = $0
		}
		self.scaleAction.run(action: action)
		
		self.floatingProgress = 1.0
		delegate.floatingHandlerDidDragging(with: 1.0)
	}
	
	@objc open func backToNormalState() {
		tapGesture.isEnabled = false
		floatingMode = false
		currentFloatingPosition = nil
		
		isVerticalDragging = false
		isHorizontalDragging = false
		
		guard let delegate = self.delegate else { return }
		
		let action = InterpolationAction(from: delegate.containerView.frame, to: delegate.fullRect,
                                         duration: 0.35, easing: .exponentialOut) { [weak self] in
			self?.delegate?.containerView.frame = $0
		}
		
//		action.onBecomeActive = {
//			self.isVerticalDragging = true
//		}
//
//		action.onBecomeInactive = {
//			self.floatingProgress = 0.0
//			self.delegate.floatingHandlerDidDragging(with: self.floatingProgress)
//		}
		
		self.scaleAction.run(action: action)
		
		self.floatingProgress = 0.0
		delegate.floatingHandlerDidDragging(with: self.floatingProgress)
		
		setupTween()
	}
	
	@objc open func updatePosition() { // call this after device rotate
		self.setupTween()
		
		if floatingMode {
			becomeFloating()
		}
	}
	
	// MARK: -
	
	fileprivate func setup() {
		self.setupTween()
		
		self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backToNormalState))
		self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onPan))
		self.delegate?.gestureView.addGestureRecognizer(panGesture)
		self.delegate?.gestureView.addGestureRecognizer(tapGesture)
		self.tapGesture.isEnabled = false
	}
	
	fileprivate func setupTween() {
		guard let delegate = self.delegate else { return }
		
		let move = InterpolationAction(from: delegate.fullRect, to: delegate.floatingRect(for: initPosition),
                                       duration: 2.0, easing: .linear) { [weak self] in
			self?.delegate?.containerView.frame = $0
		}
		
		self.tweenAction = ActionScrubber(action: move)
	}
	
	var lastPoint: CGPoint = .zero
	var lastOffset: CGPoint = .zero
	@objc fileprivate func onPan(_ pan: UIPanGestureRecognizer) {
		guard let delegate = self.delegate else { return }
		let window = delegate.containerView.window
		
		if pan.state == .began || pan.state == .changed {
			let translatedPoint = pan.translation(in: window)
			updateDraggingState(with: translatedPoint)
			
			if floatingMode && allowsCornerDocking {
				guard let view = self.delegate?.containerView else { return }
				
				if pan.state == .began {
					lastPoint = view.center
				} else {
					view.center = CGPoint(x: lastPoint.x + translatedPoint.x, y: lastPoint.y + translatedPoint.y)
				}
			} else {
				updateFrame(with: translatedPoint)
				
				if allowsCornerDocking {
					guard let view = self.delegate?.containerView else { return }
					
					if pan.state == .began {
						lastPoint = view.center//pan.location(in: view)
						
						let viewSize = view.frame.size
						lastOffset = CGPoint(x: lastPoint.x/viewSize.width, y: lastPoint.y/viewSize.height)
					} else {
						view.center = CGPoint(x: lastPoint.x + translatedPoint.x, y: view.center.y)
					}
				}
			}
		} else if pan.state == .ended {
			let translatedPoint = pan.translation(in: window)
			updateDraggingState(with: translatedPoint)
			
			if floatingMode {
				if allowsCornerDocking {
					guard let view = self.delegate?.containerView else { return }
					
					if let currentPosition = currentFloatingPosition {
						if isVerticalDragging {
							if translatedPoint.y < -50 && (currentPosition == .topLeft || currentPosition == .topRight) {
								hideAndDismiss()
								return
							} else if translatedPoint.y > 50 && (currentPosition == .bottomLeft || currentPosition == .bottomRight) {
								hideAndDismiss()
								return
							}
						} else if isHorizontalDragging {
							if translatedPoint.x < -50 && (currentPosition == .topLeft || currentPosition == .bottomLeft) {
								hideAndDismiss()
								return
							} else if translatedPoint.x > 50 && (currentPosition == .topRight || currentPosition == .bottomRight) {
								hideAndDismiss()
								return
							}
						}
					}
					
					let center = view.center
					let viewSize = UIScreen.main.bounds.size
					let halfW = viewSize.width/2
					let halfH = viewSize.height/2
					var position: NKFloatingPosition = initPosition
					
					if center.x > halfW {
						if center.y > halfH {
							position = .bottomRight
						} else {
							position = .topRight
						}
					} else {
						if center.y > halfH {
							position = .bottomLeft
						} else {
							position = .topLeft
						}
					}
					
					becomeFloating(position: position)
				} else {
					if isVerticalDragging {
						if translatedPoint.y < -100 {
							backToNormalState()
						} else {
							becomeFloating()
						}
					} else if isHorizontalDragging {
						if (translatedPoint.x < -50 && swipeLeftToDismiss) || (translatedPoint.x > 20 && swipeRightToDismiss) {
							hideAndDismiss()
						} else {
							becomeFloating()
						}
					}
				}
			} else {
				if translatedPoint.y > 150 {
					var position: NKFloatingPosition = initPosition
					
					if let view = self.delegate?.containerView {
						let center = view.center
						let viewSize = UIScreen.main.bounds.size
						let halfW = viewSize.width/2
						
						if center.x < halfW {
							position = .bottomLeft
						} else {
							position = .bottomRight
						}
					}
					
					becomeFloating(position: position)
				} else {
					backToNormalState()
				}
			}
			
			isVerticalDragging = false
			isHorizontalDragging = false
		} else if pan.state == .cancelled {
			if floatingMode {
				becomeFloating()
			} else {
				backToNormalState()
			}
			
			isVerticalDragging = false
			isHorizontalDragging = false
		}
	}
	
	fileprivate func updateDraggingState(with translatedPoint: CGPoint) {
		if floatingMode {
			if translatedPoint.y < -5 && !isHorizontalDragging {
				isVerticalDragging = true
				dragDirection = .up
			} else if translatedPoint.x > 5 && !isVerticalDragging {
				isHorizontalDragging = true
				dragDirection = .right
			} else if translatedPoint.x < -5 && !isVerticalDragging {
				isHorizontalDragging = true
				dragDirection = .left
			} else {
				dragDirection = .none
			}
		} else if !isHorizontalDragging && translatedPoint.y > 0 {
			isVerticalDragging = true
			dragDirection = .down
		} else {
			dragDirection = .none
		}
	}
	
	fileprivate func updateFrame(with translatedPoint: CGPoint) {
		switch dragDirection {
		case .up, .down:
			movingVertical(with: translatedPoint)
			
		case .left, .right:
			movingHorizontal(with: translatedPoint)
			
		default:
			break
		}
	}
	
	fileprivate func hideAndDismiss() {
		guard let delegate = self.delegate else { return }
		
		let viewSize = UIScreen.main.bounds.size
		let fromRect = delegate.containerView.frame
		var toRect = fromRect
		toRect.origin.x = dragDirection == .left ? -toRect.size.width : viewSize.width
		
		let move = InterpolationAction(from: fromRect, to: toRect, duration: 0.35, easing: .exponentialOut) { [weak self] in
			self?.delegate?.containerView.frame = $0
		}
		self.scaleAction.run(action: move)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
			delegate.floatingHandlerDidDismiss()
		}
	}
	
	fileprivate func movingVertical(with translatedPoint: CGPoint) {
		guard let delegate = self.delegate else { return }
		
		let totalHeight	= UIScreen.main.bounds.size.height - delegate.floatingRect(for: initPosition).size.height
		let percent: CGFloat = CGFloat(translatedPoint.y / totalHeight + CGFloat((dragDirection == .down) ? 0.0 : 1.0))
		self.tweenAction.update(t: Double(percent))
		
		self.floatingProgress = percent
		delegate.floatingHandlerDidDragging(with: percent)
	}
	
	fileprivate func movingHorizontal(with translatedPoint: CGPoint) {
		guard let delegate = self.delegate else { return }
		
		let viewSize = UIScreen.main.bounds.size
		let currentFrame = delegate.containerView.frame
		let currentSize = currentFrame.size
		let toRect = CGRect(x: viewSize.width - currentSize.width + translatedPoint.x, y: currentFrame.origin.y,
                            width: currentSize.width, height: currentSize.height)
		delegate.containerView.frame = toRect
	}
	
	// MARK: -
	
	deinit {
		self.panGesture.removeTarget(self, action: #selector(onPan))
		self.tapGesture.removeTarget(self, action: #selector(backToNormalState))
	}
	
}
