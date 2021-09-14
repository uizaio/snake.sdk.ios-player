//
//  UZPlayerViewController.swift
//  UizaDemo
//
//  Created by Nam Kennic on 4/9/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import NKModalPresenter

open class UZPlayerViewController: UIViewController {
	internal let playerController = UZPlayerController()
	public var player: UZPlayer { playerController.player }
	
	public var autoFullscreenWhenRotateDevice = true
	public var autoFullscreenDelay: TimeInterval = 0.3
	open var isFullscreen: Bool {
		get { playerController.fullscreenController != nil }
		set { setFullscreen(fullscreen: newValue) }
	}
	
	open func setFullscreen(fullscreen: Bool, completion: (() -> Void)? = nil) {
		UZLogger.shared.log(event: "fullscreenchange")
		if fullscreen {
			if !isFullscreen {
				self.playerController.presentFullscreen()
//				playerController.player.controlView.updateUI(true)
//				completion?()
			} else {
				UIViewController.attemptRotationToDeviceOrientation()
				completion?()
			}
		} else if isFullscreen {
			self.playerController.dismissFullscreen(animated: true) { [weak self] in
				self?.viewDidLayoutSubviews()
//				completion?()
			}
		}
	}
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		playerController.player.fullscreenToggleBlock = { [weak self] (fullscreen) in
			guard let self = self else { return }
			self.isFullscreen = fullscreen ?? !self.isFullscreen
		}
		
		view.addSubview(player)
		
		#if swift(>=4.2)
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
		#else
		NotificationCenter.default.addObserver(self, selector: #selector(onDeviceRotated), name: .UIDeviceOrientationDidChange, object: nil)
		#endif
	}
	
	override open func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		guard playerController.player.superview == view else { return }
		playerController.player.frame = view.bounds
		playerController.player.setNeedsLayout()
		playerController.player.controlView.setNeedsLayout()
		playerController.player.controlView.layoutIfNeeded()
	}
	
	// MARK: -
	
	@objc func onDeviceRotated() {
		guard autoFullscreenWhenRotateDevice else { return }
		
		DispatchQueue.main.asyncAfter(deadline: .now() + autoFullscreenDelay) {
			self.setFullscreen(fullscreen: UIDevice.current.orientation.isLandscape)
		}
	}
	
	// MARK: -
	
	override open var prefersStatusBarHidden: Bool { true }
	override open var shouldAutorotate: Bool { false }
	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
	
	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return playerController.preferredInterfaceOrientationForPresentation
//		let currentOrientation = UIApplication.shared.statusBarOrientation
//		return currentOrientation.isLandscape ? currentOrientation : .landscapeRight
	}
	
}

// MARK: - UZPlayerController

internal class UZPlayerController: UIViewController {
	let player = UZPlayer()
	
	override func loadView() {
		self.view = player
		player.clipsToBounds = true
	}
	
	fileprivate func currentVideoSize() -> CGSize {
		guard let player = player.playerLayer, let videoRect = player.playerLayer?.videoRect else { return .zero}
		return videoRect.size
	}
	
	// MARK: -
	
	override var prefersStatusBarHidden: Bool { true }
	override var prefersHomeIndicatorAutoHidden: Bool { true }
	
	override var shouldAutorotate: Bool {
		let videoSize = currentVideoSize()
		return videoSize.width >= videoSize.height ? true : false
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		let videoSize = currentVideoSize()
		return videoSize.width >= videoSize.height ? .landscape : .portrait
	}
	
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		let videoSize = currentVideoSize()
		if videoSize.width < videoSize.height { return .portrait }
		
		let deviceOrientation = UIDevice.current.orientation
		if deviceOrientation.isLandscape {
			return deviceOrientation == .landscapeRight ? .landscapeLeft : .landscapeRight
		}
		else {
			let currentOrientation = UIApplication.shared.statusBarOrientation
			return currentOrientation.isLandscape ? currentOrientation : .landscapeRight
		}
	}
	
}

extension UZPlayerController: NKModalControllerDelegate {
	
//	func presentingViewController(modalController: NKModalController) -> UIViewController? { topPresented() }
	func backgroundColor(modalController: NKModalController) -> UIColor { .clear }
	func shouldDragToDismiss(modalController: NKModalController) -> Bool { false }
	func shouldTapOutsideToDismiss(modalController: NKModalController) -> Bool { false }
	func shouldAvoidKeyboard(modalController: NKModalController) -> Bool { false }
	
}
