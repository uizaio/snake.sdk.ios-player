//
//  UZTheme5.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/16/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AVKit
import FrameLayoutKit

open class UZTheme5: UZPlayerTheme {
	public var id = "UZTheme5"
	public weak var controlView: UZPlayerControlView?
	
	public let topGradientLayer = CAGradientLayer()
	public let bottomGradientLayer = CAGradientLayer()
	
	public let frameLayout = StackFrameLayout(axis: .vertical)
	
	open var iconColor = UIColor.white
	open var iconSize = CGSize(width: 24, height: 24)
	open var skipIconSize = CGSize(width: 32, height: 32)
	open var centerIconSize = CGSize(width: 92, height: 92)
	open var seekThumbSize = CGSize(width: 24, height: 24)
	open var buttonMinSize = CGSize(width: 32, height: 32)
	
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
        controlView.setDefaultThemeIcon()
        // modify icon
		let playlistIcon = UIImage(icon: .icofont(.listineDots), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let helpIcon = UIImage(icon: .icofont(.questionCircle), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let ccIcon = UIImage(icon: .icofont(.cc), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let playBigIcon = UIImage(icon: .googleMaterialDesign(.playCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseBigIcon = UIImage(icon: .googleMaterialDesign(.pauseCircleOutline), size: centerIconSize, textColor: iconColor, backgroundColor: .clear)
		let playIcon = UIImage(icon: .googleMaterialDesign(.playArrow), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let pauseIcon = UIImage(icon: .googleMaterialDesign(.pause), size: iconSize, textColor: iconColor, backgroundColor: .clear)
		let nextIcon = UIImage(icon: .googleMaterialDesign(.skipNext), size: skipIconSize, textColor: iconColor, backgroundColor: .clear)
		let previousIcon = UIImage(icon: .googleMaterialDesign(.skipPrevious), size: skipIconSize, textColor: iconColor, backgroundColor: .clear)
		
		
		controlView.playlistButton.setImage(playlistIcon, for: .normal)
		controlView.helpButton.setImage(helpIcon, for: .normal)
		controlView.ccButton.setImage(ccIcon, for: .normal)
		
		controlView.playpauseCenterButton.setImage(playBigIcon, for: .normal)
		controlView.playpauseCenterButton.setImage(pauseBigIcon, for: .selected)
		controlView.playpauseButton.setImage(playIcon, for: .normal)
		controlView.playpauseButton.setImage(pauseIcon, for: .selected)

		controlView.nextButton.setImage(nextIcon, for: .normal)
		controlView.previousButton.setImage(previousIcon, for: .normal)
		
		if #available(iOS 9.0, *) {
			let pipStartIcon = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil).colorize(with: iconColor)
			let pipStopIcon = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil).colorize(with: iconColor)
			controlView.pipButton.setImage(pipStartIcon, for: .normal)
			controlView.pipButton.setImage(pipStopIcon, for: .selected)
			controlView.pipButton.imageView?.contentMode = .scaleAspectFit
			controlView.pipButton.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()
		}
        
		controlView.castingButton.setupDefaultIcon(iconSize: iconSize, offColor: iconColor)
		controlView.titleLabel.textColor = .white
		controlView.titleLabel.font = UIFont.systemFont(ofSize: 14)
		
		let timeLabelFont = UIFont(name: "Arial", size: 12)
		let timeLabelColor = UIColor.white
		let timeLabelShadowColor = UIColor.black
		let timeLabelShadowOffset = CGSize(width: 0, height: 1)
		
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
		
		controlView.allControlViews.forEach { frameLayout.addSubview($0) }
		controlView.forwardButton.removeFromSuperview()
		controlView.backwardButton.removeFromSuperview()
		
		frameLayout.isUserInteractionEnabled = true
		topGradientLayer.colors = [UIColor(white: 0.0, alpha: 0.8).cgColor, UIColor(white: 0.0, alpha: 0.0).cgColor]
		bottomGradientLayer.colors = [UIColor(white: 0.0, alpha: 0.0).cgColor, UIColor(white: 0.0, alpha: 0.8).cgColor]
		controlView.containerView.layer.addSublayer(topGradientLayer)
		controlView.containerView.layer.addSublayer(bottomGradientLayer)
		
		frameLayout + HStackLayout {
			$0 + [controlView.backButton, controlView.titleLabel]
			($0 + 0).flexible()
            $0 + [controlView.pipButton, controlView.castingButton, controlView.playlistButton, controlView.volumeButton]
			$0.spacing = 10
		}
		frameLayout + HStackLayout {
			($0 + [controlView.previousButton, controlView.playpauseCenterButton, controlView.nextButton]).forEach { $0.alignment = (.center, .center) }
			$0.spacing = 10
			$0.alignment = (.center, .center)
			$0.distribution = .center
			$0.flexible()
		}
		frameLayout + HStackLayout {
			$0 + controlView.playpauseButton
			$0 + HStackLayout {
				($0 + controlView.timeSlider).flexible()
				$0 + [controlView.currentTimeLabel, controlView.remainTimeLabel]
				$0.ignoreHiddenView = false
				$0.spacing = 10
				$0.flexible()
			}
			$0 + [controlView.settingsButton, controlView.fullscreenButton]
			$0.spacing = 10
		}
		frameLayout.padding(top: 10, left: 10, bottom: 0, right: 10)
		controlView.containerView.addSubview(frameLayout)
	}
	
	open func layoutControls(rect: CGRect) {
		frameLayout.frame = rect
		frameLayout.layoutIfNeeded()
		
		controlView?.loadingIndicatorView?.center = controlView?.center ?? .zero
		
		CATransaction.begin()
		CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
		topGradientLayer.frame = frameLayout.firstFrameLayout?.frame.inset(by: UIEdgeInsets(top: -frameLayout.edgeInsets.top, left: -frameLayout.edgeInsets.left, bottom: -frameLayout.edgeInsets.bottom, right: -frameLayout.edgeInsets.right)) ?? .zero
		bottomGradientLayer.frame = frameLayout.lastFrameLayout?.frame.inset(by: UIEdgeInsets(top: -frameLayout.edgeInsets.top, left: -frameLayout.edgeInsets.left, bottom: -frameLayout.edgeInsets.bottom, right: -frameLayout.edgeInsets.right)) ?? .zero
		CATransaction.commit()
		
		guard let controlView = controlView else { return }
		
		let viewSize = controlView.bounds.size
		
		if !controlView.liveBadgeView.isHidden {
			let badgeSize = controlView.liveBadgeView.sizeThatFits(viewSize)
			controlView.liveBadgeView.frame = CGRect(x: (viewSize.width - badgeSize.width)/2, y: 10, width: badgeSize.width, height: badgeSize.height)
		}
		
		if !controlView.enlapseTimeLabel.isHidden {
			let labelSize = controlView.enlapseTimeLabel.sizeThatFits(viewSize)
			controlView.enlapseTimeLabel.frame = CGRect(x: 10, y: viewSize.height - labelSize.height - 10, width: labelSize.width, height: labelSize.height)
		}
	}
	
	open func cleanUI() {
		topGradientLayer.removeFromSuperlayer()
		bottomGradientLayer.removeFromSuperlayer()
	}
	
	open func allButtons() -> [UIButton] {
		return []
	}
	
	open func showLoader() {
		guard let controlView = controlView else { return }
		
		if controlView.loadingIndicatorView == nil {
			if #available(iOS 13.0, *) {
				controlView.loadingIndicatorView = UIActivityIndicatorView(style: .medium)
			}
			else {
				controlView.loadingIndicatorView = UIActivityIndicatorView(style: .white)
			}
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
//		controlView?.forwardButton.isHidden = !isEmptyPlaylist
//		controlView?.backwardButton.isHidden = !isEmptyPlaylist
	}
	
	open func alignLogo() {
		// align logo manually here if needed
	}
	
	public func updateLiveViewCount(_ viewCount: Int) {
		controlView?.liveBadgeView.views = viewCount
	}
	
}
