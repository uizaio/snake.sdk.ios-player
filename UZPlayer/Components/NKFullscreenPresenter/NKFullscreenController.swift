//
//  NKFullscreenController.swift
//  NKFullscreenPresenter
//
//  Created by Nam Kennic on 4/5/20.
//  Copyright © 2020 Nam Kennic. All rights reserved.
//

import UIKit

extension UIWindow {
	
	static var keyWindow: UIWindow? {
		if #available(iOS 13, *) {
			return UIApplication.shared.windows.first { $0.isKeyWindow }
		} else {
			return UIApplication.shared.keyWindow
		}
	}
	
}

enum NKRotationMode {
	case none
	case left
	case right
	case half
	
	var angleValue: CGFloat {
		switch self {
			case .none: return 0
			case .left: return CGFloat(Double.pi / 2)
			case .right: return -CGFloat(Double.pi / 2)
			case .half: return CGFloat(Double.pi)
		}
	}
}

// MARK: - NKFullscreenController

public class NKFullscreenController: NKFullscreenContainerViewController {
	public static let willPresent = Notification.Name(rawValue: "NKFullscreenControllerWillPresent")
	public static let didPresent = Notification.Name(rawValue: "NKFullscreenControllerDidPresent")
	public static let willDismiss = Notification.Name(rawValue: "NKFullscreenControllerWillDismiss")
	public static let didDismiss = Notification.Name(rawValue: "NKFullscreenControllerDidDismiss")
	
	public var willPresent: ((NKFullscreenController) -> Void)?
	public var didPresent: ((NKFullscreenController) -> Void)?
	public var willDismiss: ((NKFullscreenController) -> Void)?
	public var didDismiss: ((NKFullscreenController) -> Void)?
	
	public fileprivate(set) var isPresenting = false
	public fileprivate(set) var isDismissing = false
	public fileprivate(set) var isAnimating = false
	
	public var contentView: UIView { contentViewController.view }
	
	// Default values
	
	public static var animationDuration: TimeInterval = 0.35
	public var animationDuration: TimeInterval = NKFullscreenController.animationDuration
	
	var window: UIWindow?
	weak var lastWindow: UIWindow?
	var lastPosition: (container: UIView?, frame: CGRect)?
	var lastOrientation: UIInterfaceOrientation?
	

	public init(viewController: UIViewController) {
		super.init(nibName: nil, bundle: nil)
		
		modalTransitionStyle = .crossDissolve
		modalPresentationStyle = .overCurrentContext
		modalPresentationCapturesStatusBarAppearance = true
		
		contentViewController = viewController
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .clear
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		guard !isPresenting, !isAnimating else { return }
		contentView.frame = view.bounds
	}
	
	// MARK: -
	
	public func present() {
		guard !isPresenting else { return }
		isPresenting = true
		
		willPresent?(self)
		NotificationCenter.default.post(name: NKFullscreenController.willPresent, object: self, userInfo: nil)
		
		lastPosition = (contentView.superview, contentView.frame)
		
		modalPresentationStyle = .fullScreen
		lastWindow = UIWindow.keyWindow
		lastOrientation = UIApplication.shared.statusBarOrientation
		let rotation = Self.rotation(from: UIApplication.shared.statusBarOrientation, to: contentViewController.preferredInterfaceOrientationForPresentation).angleValue
		let containerViewController = NKFullscreenContainerViewController()
		containerViewController.contentViewController = contentViewController
		
		if #available(iOS 13.0, *) {
			if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive}) as? UIWindowScene {
				window = UIWindow(windowScene: scene)
			}
		}
		
		if window == nil {
			window = UIWindow(frame: UIScreen.main.bounds)
		}
		
		window?.windowLevel = .normal + 1
		window?.rootViewController = containerViewController
		window?.makeKeyAndVisible()
		
		if rotation != 0 {
			contentView.window?.addSubview(contentView)
			lastPosition!.frame = lastPosition?.container?.convert(lastPosition!.frame, to: contentView.superview) ?? lastPosition!.frame
		}
		else {
			view.addSubview(contentView)
		}
		
		contentView.frame = lastPosition!.frame //containerView.convert(lastPosition!.frame, from: lastPosition!.container)
		
		containerViewController.present(self, animated: false, completion: {
			UIView.animate(withDuration: self.animationDuration, delay: 0.0, options: .curveEaseOut) {
				if rotation != 0 {
					self.contentView.transform = CGAffineTransform(rotationAngle: rotation)
				}
				self.contentView.frame = self.contentView.superview!.bounds
				self.contentView.setNeedsLayout()
				self.contentView.layoutIfNeeded()
			} completion: { finished in
				self.isPresenting = false
				self.contentView.transform = .identity
				self.view.addSubview(self.contentView)
			}
		})
	}
	
	public override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
		guard !isPresenting else {
			print("[NKFullscreenController] Can not dismiss a modal controller while it's presenting")
			return
		}
		
		guard !isDismissing else { return }
		isDismissing = true
		isAnimating = true
		
		willDismiss?(self)
		NotificationCenter.default.post(name: NKFullscreenController.willDismiss, object: self, userInfo: nil)
		
		if window != lastWindow {
			window?.isUserInteractionEnabled = false
		}
		
		let rotation = Self.rotation(from: lastOrientation!, to: UIApplication.shared.statusBarOrientation).angleValue
		if rotation != 0 {
			lastWindow!.addSubview(contentView)
			self.contentView.transform = CGAffineTransform(rotationAngle: rotation)
			contentView.frame = lastWindow!.bounds
		}
		else {
			view.addSubview(contentView)
		}
		
		UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseOut) {
			self.contentView.transform = .identity
			self.contentView.frame = self.lastPosition!.frame
			self.contentView.setNeedsLayout()
			self.contentView.layoutIfNeeded()
		} completion: { finished in
			super.dismiss(animated: false) {
				self.setNeedsStatusBarAppearanceUpdate()
				self.isAnimating = false
				self.isDismissing = false
				
				self.window?.rootViewController?.resignFirstResponder()
				self.window?.rootViewController = nil
				self.window?.removeFromSuperview()
				self.window = nil
				
				self.lastPosition!.container?.addSubview(self.contentView)
				
				if NKFullscreenPresenter.shared.activeModalControllers.isEmpty || NKFullscreenPresenter.shared.topModalController == self {
					self.lastWindow?.makeKeyAndVisible()
				}
				
				self.lastWindow = nil
				
				self.didDismiss?(self)
				NotificationCenter.default.post(name: NKFullscreenController.didDismiss, object: self, userInfo: nil)
				
				self.contentViewController = nil
				
				if UIWindow.keyWindow == nil {
					UIApplication.shared.windows.last?.makeKeyAndVisible()
				}
				
				completion?()
			}
		}
	}
	
	static func rotation(from: UIInterfaceOrientation, to: UIInterfaceOrientation) -> NKRotationMode {
		switch from {
			case .portrait:
				if to == .portrait { return .none } else
				if to == .landscapeLeft { return .right } else
				if to == .landscapeRight { return .left } else
				if to == .portraitUpsideDown { return .half }
				break
				
			case .portraitUpsideDown:
				if to == .portrait { return .half } else
				if to == .landscapeLeft { return .left } else
				if to == .landscapeRight { return .right } else
				if to == .portraitUpsideDown { return .none }
				break
				
			case .landscapeLeft:
				if to == .portrait { return .left } else
				if to == .landscapeLeft { return .none } else
				if to == .landscapeRight { return .half } else
				if to == .portraitUpsideDown { return .right }
				break
				
			case .landscapeRight:
				if to == .portrait { return .right } else
				if to == .landscapeLeft { return .half } else
				if to == .landscapeRight { return .none } else
				if to == .portraitUpsideDown { return .left }
				break
				
			case .unknown: return .none
			@unknown default: return .none
		}
		
		return .none
	}
	
}

public class NKFullscreenContainerViewController: UIViewController {
	public fileprivate(set) var contentViewController: UIViewController!
	
	var visibleViewController: UIViewController? {
		return (contentViewController as? UINavigationController)?.visibleViewController ?? contentViewController
	}
	
	// Orientation
	
	public override var shouldAutorotate: Bool {
		return visibleViewController?.shouldAutorotate ?? true
	}
	
	public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return visibleViewController?.supportedInterfaceOrientations ?? .all
	}
	
	public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		#if targetEnvironment(macCatalyst)
		return visibleViewController?.preferredInterfaceOrientationForPresentation ?? UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
		#else
		return visibleViewController?.preferredInterfaceOrientationForPresentation ?? UIApplication.shared.statusBarOrientation
		#endif
	}
	
	// Statusbar
	
	public override var prefersStatusBarHidden: Bool {
		return visibleViewController?.prefersStatusBarHidden ?? false
	}
	
	public override var preferredStatusBarStyle: UIStatusBarStyle {
		return visibleViewController?.preferredStatusBarStyle ?? .default
	}
	
	public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
		return visibleViewController?.preferredStatusBarUpdateAnimation ?? .fade
	}
	
}
