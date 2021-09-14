//
//  NKFullscreenPresenter.swift
//  NKFullscreenPresenter
//
//  Created by Nam Kennic on 4/4/20.
//  Copyright © 2020 Nam Kennic. All rights reserved.
//

import UIKit

extension Array where Element: Equatable {
	
	mutating func remove(element: Element) {
		if let index = self.firstIndex(of: element) {
			self.remove(at: index)
		}
	}
	
}

public class NKFullscreenPresenter {
	public static let shared = NKFullscreenPresenter()
	public private(set) var activeModalControllers: [NKFullscreenController] = []
	
	public var topModalController: NKFullscreenController? {
		return activeModalControllers.last
	}
	
	private var listenOnDismissEvent = true

	private init() {}
	
	@discardableResult
	public func present(viewController: UIViewController) -> NKFullscreenController {
		let fullscreenController = NKFullscreenController(viewController: viewController)
		fullscreenController.present()
		
		NotificationCenter.default.addObserver(self, selector: #selector(onModalControllerDismissed), name: NKFullscreenController.didDismiss, object: fullscreenController)
		activeModalControllers.append(fullscreenController)
		return fullscreenController
	}
	
	public func dismiss(viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
		guard let fullscreenController = fullscreenController(containing: viewController) else { return }
		activeModalControllers.remove(element: fullscreenController)
		fullscreenController.dismiss(animated: animated, completion: completion)
	}
	
	public func dismissTopModalController(animated: Bool, completion: (() -> Void)? = nil) {
		guard let topModalController = activeModalControllers.last else { return }
		topModalController.dismiss(animated: animated, completion: completion)
		activeModalControllers.remove(element: topModalController)
	}
	
	public func dismissAll(animated: Bool, completion: (() -> Void)? = nil) {
		listenOnDismissEvent = false
		let lastModalController = activeModalControllers.last
		activeModalControllers.forEach { $0.dismiss(animated: animated, completion: $0 == lastModalController ? completion : nil) }
		activeModalControllers.removeAll()
		listenOnDismissEvent = true
	}
	
	public func fullscreenController(containing viewController: UIViewController) -> NKFullscreenController? {
		return activeModalControllers.first(where: { $0.contentViewController == viewController || $0.contentViewController == viewController.navigationController })
	}
	
	public func fullscreenController(containing view: UIView) -> NKFullscreenController? {
		return activeModalControllers.first(where: { $0.contentViewController.view == view})
	}
	
	@objc func onModalControllerDismissed(_ notification: Notification) {
		guard listenOnDismissEvent, let fullscreenController = notification.object as? NKFullscreenController else { return }
		NotificationCenter.default.removeObserver(fullscreenController)
		activeModalControllers.remove(element: fullscreenController)
	}
	
	deinit {
		activeModalControllers.removeAll()
	}
	
}

extension UIViewController {
	
	@discardableResult
	public func presentFullscreen() -> NKFullscreenController {
		return NKFullscreenPresenter.shared.present(viewController: self)
	}
	
	public var fullscreenController: NKFullscreenController? {
		return NKFullscreenPresenter.shared.fullscreenController(containing: self) ?? (navigationController != nil ? NKFullscreenPresenter.shared.fullscreenController(containing: navigationController!) : nil)
	}
	
	@objc public func dismissFullscreen(animated: Bool, completion: (() -> Void)? = nil) {
		if let modal = fullscreenController {
			modal.dismiss(animated: animated, completion: completion)
		}
		else {
			dismiss(animated: animated, completion: completion)
		}
	}
	
}
