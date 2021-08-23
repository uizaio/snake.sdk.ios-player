//
//  UZFloatingPlayerViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 10/27/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

public protocol UZFloatingPlayerViewProtocol: class {
	
	func floatingPlayer(_ player: UZFloatingPlayerViewController, didBecomeFloating: Bool)
	func floatingPlayer(_ player: UZFloatingPlayerViewController, onFloatingProgress: CGFloat)
	func floatingPlayerDidDismiss(_ player: UZFloatingPlayerViewController)
	
}

open class UZFloatingPlayerViewController: UIViewController, NKFloatingViewHandlerProtocol {
	public private(set) var playerWindow: UIWindow?
	private var lastKeyWindow: UIWindow?
	
	public var playerViewController: UZPlayerViewController! {
		didSet {
			if player != nil {
				player!.videoChangedBlock = nil
				player!.backBlock = nil
				player!.removeFromSuperview()
				player = nil
			}
			
			playerViewController.fullscreenPresentationMode = .modal
			playerViewController.autoFullscreenWhenRotateDevice = true
			
			player = playerViewController.player
			player?.backBlock = { [weak self] (_) in
				guard let `self` = self else { return }
				print("backButton: \(self.playerViewController.isFullscreen)")
				if self.playerViewController.isFullscreen {
					self.playerViewController.setFullscreen(fullscreen: false)
				} else {
					self.dismiss(animated: true, completion: self.onDismiss)
				}
			}
			
			player?.videoChangedBlock = { [weak self] (videoItem) in
				self?.videoItem = videoItem
			}
		}
	}
	public private(set) var player: UZPlayer?
	public let detailsContainerView = UIView()
	public var playerRatio: CGFloat = 9/16
	public var autoDetectPortraitVideo = false
	
	public weak var delegate: UZFloatingPlayerViewProtocol?
	
	public var videoItem: UZVideoItem? = nil {
		didSet {
			guard videoItem != oldValue else { return }
			guard let videoItem = videoItem else {
				stop()
				return
			}
			guard player?.currentVideo != videoItem else { return }
			if let floatingHandler = floatingHandler {
				if floatingHandler.isFloatingMode {
					floatingHandler.backToNormalState()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						self.view.setNeedsLayout()
					}
				}
			}
			player?.loadVideo(videoItem)
		}
	}
	
	public var videoItems: [UZVideoItem]? = nil {
		didSet {
			guard videoItems != oldValue else { return }
			guard let videoItems = videoItems else {
				stop()
				return
			}
			
			if player?.playlist != videoItems {
				if let floatingHandler = floatingHandler {
					if floatingHandler.isFloatingMode {
						floatingHandler.backToNormalState()
						
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							self.view.setNeedsLayout()
						}
					}
				}
				
				player?.playlist = videoItems
				if let videoItem = videoItems.first {
					player?.loadVideo(videoItem)
				}
			}
		}
	}
	
	public var onDismiss: (() -> Void)?
	public var onFloatingProgress: ((UZFloatingPlayerViewController, CGFloat) -> Void)?
	public var onFloating: ((UZFloatingPlayerViewController) -> Void)?
	public var onUnfloating: ((UZFloatingPlayerViewController) -> Void)?
	
	public private(set) var floatingHandler: NKFloatingViewHandler?
	
	// MARK: -
	
	public init() {
		super.init(nibName: nil, bundle: nil)
	}
	
	public convenience init(customPlayerViewController: UZPlayerViewController!) {
		self.init()
		
		defer {
			playerViewController = customPlayerViewController
		}
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	@discardableResult
	open func present(with videoItem: UZVideoItem? = nil, playlist: [UZVideoItem]? = nil) -> UZPlayerViewController {
		if playerViewController == nil {
			playerViewController = UZPlayerViewController()
		}
		playerViewController.onOrientationUpdateRequestBlock = { fullscreen in
		}
		if playerWindow == nil {
			modalPresentationStyle = .overCurrentContext
			
			lastKeyWindow = UIApplication.shared.keyWindow
			
			let containerViewController = UZPlayerContainerViewController()
			
			playerWindow = UIWindow(frame: UIScreen.main.bounds)
			#if swift(>=4.2)
			playerWindow!.windowLevel = UIWindow.Level.normal + 1
			#else
			playerWindow!.windowLevel = UIWindowLevelNormal + 1
			#endif
			
			playerWindow!.rootViewController = containerViewController
			playerWindow!.makeKeyAndVisible()
			
			containerViewController.present(self, animated: true, completion: nil)
		} else {
			playerWindow?.makeKeyAndVisible()
		}
		
		self.videoItem = videoItem
		player?.playlist = playlist
		return playerViewController
	}
	
	override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		player?.stop()
		player = nil
		
		floatingHandler?.delegate = nil
		floatingHandler = nil
		
		delegate?.floatingPlayerDidDismiss(self)
		super.dismiss(animated: flag) { [weak self] in
			self?.playerWindow?.rootViewController = nil
			self?.playerWindow = nil
			self?.lastKeyWindow?.makeKeyAndVisible()
			completion?()
		}
	}
	
	// MARK: -
	
	open func playResource(_ resource: UZPlayerResource) {
		if let floatingHandler = floatingHandler {
			if floatingHandler.isFloatingMode {
				floatingHandler.backToNormalState()
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					self.view.setNeedsLayout()
					
				}
			}
		}
		
		player?.setResource(resource: resource)
		view.setNeedsLayout()
	}
	
	open func stop() {
		player?.stop()
	}
	
	// MARK: -
	
	override open func viewDidLoad() {
		super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
		view.clipsToBounds = true
		view.backgroundColor = UIColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1.00)
		view.addSubview(detailsContainerView)
		view.addSubview(playerViewController.view)
		
		floatingHandler = NKFloatingViewHandler(target: self)
	}
	
	override open func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		let viewSize = view.bounds.size
		
		var isPortrait = false
		if let currentVideoSize = player?.playerLayer?.playerLayer?.videoRect, autoDetectPortraitVideo {
			isPortrait = currentVideoSize.width < currentVideoSize.height
		}
		
		let playerSize = isPortrait ? viewSize : CGSize(width: viewSize.width, height: viewSize.width * playerRatio) // 4:3
		playerViewController.view.frame = CGRect(x: 0, y: 0, width: playerSize.width, height: playerSize.height)
		detailsContainerView.frame = CGRect(x: 0, y: playerSize.height, width: viewSize.width, height: viewSize.height - playerSize.height)
	}
	
	override open var prefersStatusBarHidden: Bool {
		return true
	}
	
	override open var shouldAutorotate: Bool {
		return false //floatingHandler.isFloatingMode == false
	}
	
	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
	}
	
	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return UIDevice.current.userInterfaceIdiom == .phone || (floatingHandler?.isFloatingMode ?? false) ? .portrait : .all
	}
	
	// MARK: - NKFloatingViewHandlerProtocol
	
	open var containerView: UIView! {
        return view.window!
	}
	
	open var gestureView: UIView! {
        return view!
	}
	
	open var fullRect: CGRect {
        return UIScreen.main.bounds
	}
	
	open func floatingRect(for position: NKFloatingPosition) -> CGRect {
		let screenSize = UIScreen.main.bounds.size
		var isPortrait = false
		if let currentVideoSize = player?.playerLayer?.playerLayer?.videoRect, autoDetectPortraitVideo {
			isPortrait = currentVideoSize.width < currentVideoSize.height
		}
		
		let floatingWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 180 : 220
		let floatingSize = isPortrait ? CGSize(width: floatingWidth * playerRatio, height: floatingWidth) :
            CGSize(width: floatingWidth, height: floatingWidth * playerRatio)
		var point: CGPoint = .zero
		
		if position == .bottomRight {
			point = CGPoint(x: screenSize.width - floatingSize.width - 10, y: screenSize.height - floatingSize.height - 10)
		} else if position == .bottomLeft {
			point = CGPoint(x: 10, y: screenSize.height - floatingSize.height - 10)
		} else if position == .topLeft {
			point = CGPoint(x: 10, y: 10)
		} else if position == .topRight {
			point = CGPoint(x: screenSize.width - floatingSize.width - 10, y: 10)
		}
		
		return CGRect(origin: point, size: floatingSize)
	}
		
	open func floatingHandlerDidDragging(with progress: CGFloat) {
		delegate?.floatingPlayer(self, onFloatingProgress: progress)
		
		let alpha = 1.0 - progress
        player?.subtitleLabel?.isHidden = progress > 0
		
		detailsContainerView.alpha = alpha
		player?.controlView.containerView.alpha = alpha
		
		if progress == 0.0 {
			player?.controlView.containerView.isHidden = false
			player?.controlView.tapGesture?.isEnabled = true
			playerViewController.autoFullscreenWhenRotateDevice = true
			
			playerWindow?.makeKeyAndVisible()
			delegate?.floatingPlayer(self, didBecomeFloating: false)
            player?.updateVisualizeInformation(visible: true)
			
			onUnfloating?(self)
			view.setNeedsLayout()
		} else if progress == 1.0 {
			player?.controlView.containerView.isHidden = true
			player?.controlView.tapGesture?.isEnabled = false
			player?.shouldShowsControlViewAfterStoppingPiP = false
			playerViewController.autoFullscreenWhenRotateDevice = false
			
			lastKeyWindow?.makeKeyAndVisible()
			delegate?.floatingPlayer(self, didBecomeFloating: true)
            player?.updateVisualizeInformation(visible: false)
			
			view.setNeedsLayout()
			onFloating?(self)
		}
	}
	
	open func floatingHandlerDidDismiss() {
		dismiss(animated: true, completion: onDismiss)
	}

	deinit {
		DLog("DEINIT")
	}
	
}

// MARK: -

open class UZPlayerContainerViewController: UIViewController {
	
	override open var prefersStatusBarHidden: Bool {
		return true
	}
	
	override open var shouldAutorotate: Bool {
		return false
	}
	
	override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : UIApplication.shared.statusBarOrientation
	}
	
	override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
	}
	
}
