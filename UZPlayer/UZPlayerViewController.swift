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
	
	open var autoFullscreenWhenRotateDevice = true
	open var autoFullscreenDelay: TimeInterval = 0.3	
	open var isFullscreen: Bool {
		get { playerController.modalController != nil }
		set { setFullscreen(fullscreen: newValue) }
	}
	
	private var lastFrame: CGRect = .zero
	private var lastSuperview: UIView? = nil
	open func setFullscreen(fullscreen: Bool, completion: (() -> Void)? = nil) {
		UZLogger.shared.log(event: "fullscreenchange")
		if fullscreen {
			if !isFullscreen {
				lastFrame = playerController.player.superview?.frame ?? playerController.player.frame
				lastSuperview = playerController.player.superview
				
				playerController.presentAsModal()
				
				UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
					self.playerController.player.frame = CGRect(x: 0, y: 0, width: self.view.frame.height, height: self.view.frame.width)
					self.playerController.player.center = self.view.center
					self.playerController.player.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
					self.playerController.player.layoutSubviews()
					
				}, completion: { finished in
					completion?()
				})
				
				playerController.player.controlView.updateUI(true)
			} else {
				UIViewController.attemptRotationToDeviceOrientation()
				completion?()
			}
		} else if isFullscreen {
			view.setNeedsLayout()
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
				self.playerController.player.transform = CGAffineTransform.identity
				self.playerController.player.frame = self.lastFrame
				self.playerController.player.layoutSubviews()
				self.view.layoutIfNeeded()
			}, completion: { finished in
				self.playerController.player.controlView.updateUI(false)
				self.playerController.dismissModal(animated: false) { [weak self] in
					self?.viewDidLayoutSubviews()
					completion?()
				}
			})
		}
	}
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		playerController.player.fullscreenBlock = { [weak self] (fullscreen) in
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
	
	func presentingViewController(modalController: NKModalController) -> UIViewController? { topPresented() }
	func backgroundColor(modalController: NKModalController) -> UIColor { .clear }
	func shouldDragToDismiss(modalController: NKModalController) -> Bool { false }
	func shouldTapOutsideToDismiss(modalController: NKModalController) -> Bool { false }
	func shouldAvoidKeyboard(modalController: NKModalController) -> Bool { false }
	
}


/*
internal class UZPlayerContainerController: UIViewController {
	
	// MARK: -
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override var shouldAutorotate : Bool {
		return true
	}
	
	override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
		return .landscape
	}
	
	override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
		let deviceOrientation = UIDevice.current.orientation
		if UIDeviceOrientationIsLandscape(deviceOrientation) {
			return deviceOrientation == .landscapeRight ? .landscapeLeft : .landscapeRight
		}
		else {
			let currentOrientation = UIApplication.shared.statusBarOrientation
			return UIInterfaceOrientationIsLandscape(currentOrientation) ? currentOrientation : .landscapeRight
		}
	}
	
}
*/
