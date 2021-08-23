//
//  UZTheme3.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/16/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AVKit
import FrameLayoutKit

open class UZTheme3: UZPlayerTheme {
	public var id = "UZTheme3"
	public weak var controlView: UZPlayerControlView?
	
	let topGradientLayer = CAGradientLayer()
	
	let topFrameLayout = DoubleFrameLayout(axis: .horizontal)
	let bottomFrameLayout = StackFrameLayout(axis: .horizontal, distribution: .left)
	let mainFrameLayout = StackFrameLayout(axis: .vertical, distribution: .top)
	
	var iconColor = UIColor.white
	var iconSize = CGSize(width: 24, height: 24)
	var skipIconSize = CGSize(width: 32, height: 32)
	var centerIconSize = CGSize(width: 92, height: 92)
	var seekThumbSize = CGSize(width: 24, height: 24)
	var buttonMinSize = CGSize(width: 32, height: 32)
	
	public convenience init(iconSize: CGSize = CGSize(width: 24, height: 24), centerIconSize: CGSize = CGSize(width: 92, height: 92), seekThumbSize: CGSize = CGSize(width: 24, height: 24), iconColor: UIColor = .white) {
		self.init()
		
		self.iconSize = iconSize
		self.centerIconSize = centerIconSize
		self.iconColor = iconColor
		self.seekThumbSize = seekThumbSize
	}
	
	public init() {
		
	}
	
	open func updateUI() {
		setupSkin()
		setupLayout()
	}
	
	func setupSkin() {
		guard let controlView = controlView else { return }
		
		let backIcon = UIImage(icon: .icofont(.arrowLeft), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playlistIcon = UIImage(icon: .icofont(.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .icofont(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .icofont(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let settingsIcon = UIImage(icon: .icofont(.gear), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let volumeIcon = UIImage(icon: .icofont(.volumeUp), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let muteIcon = UIImage(icon: .icofont(.volumeMute), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playBigIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseBigIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .googleMaterialDesign(.playArrow), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .googleMaterialDesign(.pause), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let fullscreenIcon = UIImage(icon: .googleMaterialDesign(.fullscreen), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let collapseIcon = UIImage(icon: .googleMaterialDesign(.fullscreenExit), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let forwardIcon = UIImage(icon: .googleMaterialDesign(.forward5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let backwardIcon = UIImage(icon: .googleMaterialDesign(.replay5), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let nextIcon = UIImage(icon: .googleMaterialDesign(.skipNext), size: skipIconSize, textColor: iconColor, backgroundColor: .clear)
		let previousIcon = UIImage(icon: .googleMaterialDesign(.skipPrevious), size: skipIconSize, textColor: iconColor, backgroundColor: .clear)
		let thumbIcon = UIImage(icon: .fontAwesomeSolid(.circle), size: seekThumbSize, textColor: iconColor, backgroundColor: .clear)
		
		controlView.backButton.setImage(backIcon, for: .normal)
		controlView.playlistButton.setImage(playlistIcon, for: .normal)
		controlView.helpButton.setImage(helpIcon, for: .normal)
		controlView.ccButton.setImage(ccIcon, for: .normal)
		controlView.settingsButton.setImage(settingsIcon, for: .normal)
		controlView.volumeButton.setImage(volumeIcon, for: .normal)
		controlView.volumeButton.setImage(muteIcon, for: .selected)
		controlView.playpauseCenterButton.setImage(playBigIcon, for: .normal)
		controlView.playpauseCenterButton.setImage(pauseBigIcon, for: .selected)
		controlView.playpauseButton.setImage(playIcon, for: .normal)
		controlView.playpauseButton.setImage(pauseIcon, for: .selected)
		controlView.forwardButton.setImage(forwardIcon, for: .normal)
		controlView.backwardButton.setImage(backwardIcon, for: .normal)
		controlView.nextButton.setImage(nextIcon, for: .normal)
		controlView.previousButton.setImage(previousIcon, for: .normal)
		controlView.fullscreenButton.setImage(fullscreenIcon, for: .normal)
		controlView.fullscreenButton.setImage(collapseIcon, for: .selected)
		controlView.timeSlider.setThumbImage(thumbIcon, for: .normal)
		
		if #available(iOS 9.0, *) {
			let pipStartIcon = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil).colorize(with: iconColor)
			let pipStopIcon = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil).colorize(with: iconColor)
			controlView.pipButton.setImage(pipStartIcon, for: .normal)
			controlView.pipButton.setImage(pipStopIcon, for: .selected)
			controlView.pipButton.imageView?.contentMode = .scaleAspectFit
			controlView.pipButton.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()
		} else {
			// Fallback on earlier versions
		}
		
		controlView.nextButton.isHidden = true
		controlView.previousButton.isHidden = true
		
//		controlView.airplayButton.setupDefaultIcon(iconSize: iconSize, offColor: iconColor)
		controlView.castingButton.setupDefaultIcon(iconSize: iconSize, offColor: iconColor)
		
		controlView.titleLabel.textColor = .white
		controlView.titleLabel.font = UIFont.systemFont(ofSize: 14)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
		topGradientLayer.colors = [UIColor(white: 0.0, alpha: 0.8).cgColor, UIColor(white: 0.0, alpha: 0.0).cgColor]
		controlView.containerView.layer.addSublayer(topGradientLayer)
		
		controlView.currentTimeLabel.textColor = timeLabelColor
		controlView.currentTimeLabel.font = timeLabelFont
		controlView.currentTimeLabel.shadowColor = timeLabelShadowColor
		controlView.currentTimeLabel.shadowOffset = timeLabelShadowOffset
		
		controlView.totalTimeLabel.textColor = timeLabelColor
		controlView.totalTimeLabel.font = timeLabelFont
		controlView.totalTimeLabel.shadowColor = timeLabelShadowColor
		controlView.totalTimeLabel.shadowOffset = timeLabelShadowOffset
		
		controlView.remainTimeLabel.textColor = timeLabelColor
		controlView.remainTimeLabel.font = timeLabelFont
		controlView.remainTimeLabel.shadowColor = timeLabelShadowColor
		controlView.remainTimeLabel.shadowOffset = timeLabelShadowOffset
	}
	
	func setupLayout() {
		guard let controlView = controlView else { return }
		
		let controlFrameLayout = StackFrameLayout(axis: .horizontal, views: [controlView.pipButton, controlView.castingButton,
                                                                             controlView.playlistButton, controlView.ccButton,
                                                                             controlView.settingsButton, controlView.volumeButton])
        controlFrameLayout.addSubview(controlView.castingButton)
		controlFrameLayout.addSubview(controlView.pipButton)
		controlFrameLayout.addSubview(controlView.playlistButton)
		controlFrameLayout.addSubview(controlView.ccButton)
		controlFrameLayout.addSubview(controlView.settingsButton)
		controlFrameLayout.addSubview(controlView.volumeButton)
		controlFrameLayout.isUserInteractionEnabled = true
		controlFrameLayout.isIntrinsicSizeEnabled = true
		controlFrameLayout.spacing = 10
//		controlFrameLayout.showFrameDebug = true
		for frameLayout in controlFrameLayout.frameLayouts {
			frameLayout.minSize = buttonMinSize
		}
		
		let topLeftFrameLayout = DoubleFrameLayout(axis: .horizontal, views: [controlView.backButton, controlView.titleLabel])
		topLeftFrameLayout.spacing = 10
		topLeftFrameLayout.isUserInteractionEnabled = true
		topLeftFrameLayout.addSubview(controlView.backButton)
		topLeftFrameLayout.addSubview(controlView.titleLabel)
		topLeftFrameLayout.leftFrameLayout.minSize = buttonMinSize
		
		topFrameLayout.leftFrameLayout.targetView = topLeftFrameLayout
		topFrameLayout.rightFrameLayout.targetView = controlFrameLayout
		topFrameLayout.leftFrameLayout.contentAlignment = (.center, .left)
		topFrameLayout.rightFrameLayout.contentAlignment = (.center, .right)
		topFrameLayout.spacing = 5
		topFrameLayout.addSubview(topLeftFrameLayout)
		topFrameLayout.addSubview(controlFrameLayout)
		topFrameLayout.isUserInteractionEnabled = true
		topFrameLayout.distribution = .right
		topFrameLayout.edgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
//		topFrameLayout.showFrameDebug = true
		
		let bottomLeftFrameLayout = StackFrameLayout(axis: .horizontal, views: [controlView.playpauseButton, controlView.currentTimeLabel])
		let bottomRightFrameLayout = StackFrameLayout(axis: .horizontal, views: [controlView.remainTimeLabel, controlView.fullscreenButton])
		bottomRightFrameLayout.spacing = 10
		bottomLeftFrameLayout.spacing = 10
		
		for frameLayout in bottomLeftFrameLayout.frameLayouts {
			frameLayout.minSize = buttonMinSize
		}
		
		for frameLayout in bottomRightFrameLayout.frameLayouts {
			frameLayout.minSize = buttonMinSize
		}
		
		bottomFrameLayout.append(views: [bottomLeftFrameLayout, controlView.timeSlider, bottomRightFrameLayout])
		bottomFrameLayout.frameLayout(at: 1)?.isFlexible = true
		bottomFrameLayout.addSubview(controlView.currentTimeLabel)
		bottomFrameLayout.addSubview(controlView.remainTimeLabel)
		bottomFrameLayout.addSubview(controlView.timeSlider)
		bottomFrameLayout.addSubview(controlView.fullscreenButton)
		bottomFrameLayout.addSubview(controlView.playpauseButton)
		bottomFrameLayout.spacing = 10
		bottomFrameLayout.isUserInteractionEnabled = true
		bottomFrameLayout.edgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
		bottomFrameLayout.backgroundColor = UIColor(white: 0.0, alpha: 0.8)
		bottomFrameLayout.layer.cornerRadius = 10
		bottomFrameLayout.layer.masksToBounds = true
		
		let centerFrameLayout = StackFrameLayout(axis: .horizontal, distribution: .center,
                                                 views: [controlView.previousButton, controlView.playpauseCenterButton, controlView.nextButton])
		centerFrameLayout.spacing = 30
		centerFrameLayout.isUserInteractionEnabled = true
		centerFrameLayout.addSubview(controlView.previousButton)
		centerFrameLayout.addSubview(controlView.nextButton)
		centerFrameLayout.addSubview(controlView.playpauseCenterButton)
		
		mainFrameLayout.append(view: topFrameLayout)
		mainFrameLayout.append(view: centerFrameLayout).configurationBlock = { layout in
			layout.isFlexible = true
		}
		mainFrameLayout.append(view: bottomFrameLayout).edgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 10, right: 20)
		
		bottomLeftFrameLayout.ignoreHiddenView = true
		
		controlView.containerView.addSubview(mainFrameLayout)
		controlView.containerView.addSubview(topFrameLayout)
		controlView.containerView.addSubview(bottomFrameLayout)
		controlView.containerView.addSubview(centerFrameLayout)
		
		controlView.addSubview(controlView.enlapseTimeLabel)
		controlView.addSubview(controlView.liveBadgeView)
	}
	
	open func layoutControls(rect: CGRect) {
		mainFrameLayout.frame = rect
		mainFrameLayout.layoutIfNeeded()
		
		CATransaction.begin()
		CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
		topGradientLayer.frame = topFrameLayout.frame
		CATransaction.commit()
		
		if let controlView = controlView {
			let viewSize = controlView.bounds.size
			
			if controlView.liveBadgeView.isHidden == false {
				let badgeSize = controlView.liveBadgeView.sizeThatFits(viewSize)
				controlView.liveBadgeView.frame = CGRect(x: (viewSize.width - badgeSize.width)/2, y: 10, width: badgeSize.width, height: badgeSize.height)
			}
			
			if controlView.enlapseTimeLabel.isHidden == false {
				let labelSize = controlView.enlapseTimeLabel.sizeThatFits(viewSize)
				let edgeInsets = mainFrameLayout.lastFrameLayout?.edgeInsets ?? .zero
				controlView.enlapseTimeLabel.frame = CGRect(x: edgeInsets.left + 5,
                                                            y: viewSize.height - labelSize.height - edgeInsets.bottom - 8,
                                                            width: labelSize.width, height: labelSize.height)
			}
		}
		
		controlView?.loadingIndicatorView?.center = controlView?.center ?? .zero
	}
	
	open func cleanUI() {
		topGradientLayer.removeFromSuperlayer()
	}
	
	open func allButtons() -> [UIButton] {
		return []
	}
	
	open func showLoader() {
		guard let controlView = controlView else { return }
		if controlView.loadingIndicatorView == nil {
			controlView.loadingIndicatorView = UIActivityIndicatorView(style: .white)
			controlView.addSubview(controlView.loadingIndicatorView!)
		}
		
		controlView.loadingIndicatorView?.isHidden = false
		controlView.loadingIndicatorView?.startAnimating()
	}
	
	open func hideLoader() {
		controlView?.loadingIndicatorView?.isHidden = true
		controlView?.loadingIndicatorView?.stopAnimating()
	}
	
	open func update(withResource: UZPlayerResource?, video: UZVideoItem?, playlist: [UZVideoItem]?) {
		let isEmptyPlaylist = (playlist?.count ?? 0) < 2
		controlView?.nextButton.isHidden = isEmptyPlaylist
		controlView?.previousButton.isHidden = isEmptyPlaylist
		controlView?.forwardButton.isHidden = !isEmptyPlaylist
		controlView?.backwardButton.isHidden = !isEmptyPlaylist
	}
	
	open func alignLogo() {
		// align logo manually here if needed
	}
	
}
