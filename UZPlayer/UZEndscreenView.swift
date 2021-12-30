//
//  UZShareView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/3/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import SwiftIcons

open class UZEndscreenView: UIView {
	open lazy var blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	open lazy var titleLabel: UILabel = UILabel()
	open lazy var replayButton: UZButton = UZButton()
	open lazy var shareButton: UZButton = UZButton()
	
	let frameLayout = StackFrameLayout(axis: .horizontal)
	
	open var allButtons: [UIButton] { [replayButton, shareButton] }
	
	open var title: String? {
		get { titleLabel.text }
		set {
			titleLabel.text = newValue
			setNeedsLayout()
		}
	}
	
	init() {
		super.init(frame: .zero)
		setupUI()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open func setupUI() {
		backgroundColor = UIColor(white: 0.0, alpha: 0.35)
		
		if #available(iOS 8.2, *) {
			titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
		} else {
			titleLabel.font = UIFont.systemFont(ofSize: 15)
		}
		
		titleLabel.textColor = .white
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 3
		titleLabel.isHidden = true
		
		let buttonColor = UIColor.white
		replayButton.setImage(UIImage(icon: .googleMaterialDesign(.replay), size: CGSize(width: 32, height: 32),
                                      textColor: buttonColor, backgroundColor: .clear), for: .normal)
		shareButton.setImage(UIImage(icon: .googleMaterialDesign(.share), size: CGSize(width: 32, height: 32),
                                     textColor: buttonColor, backgroundColor: .clear), for: .normal)
		replayButton.setBorderColor(buttonColor, for: .normal)
		shareButton.setBorderColor(buttonColor, for: .normal)
		replayButton.borderSize = 1.0
		shareButton.borderSize = 1.0
		replayButton.isRoundedButton = true
		shareButton.isRoundedButton = true
		replayButton.extendSize = CGSize(width: 24, height: 24)
		shareButton.extendSize = CGSize(width: 24, height: 24)
		
		replayButton.tag = UZButtonTag.replay.rawValue
		shareButton.tag = UZButtonTag.share.rawValue
		
//		addSubview(blurView)
//		addSubview(titleLabel)
		addSubview(replayButton)
		addSubview(shareButton)
		addSubview(frameLayout)
		
//		frameLayout + titleLabel
		(frameLayout + replayButton).alignment = (.center, .center)
		(frameLayout + shareButton).alignment = (.center, .center)
		
		frameLayout.spacing = 30
		frameLayout.distribution = .center
		frameLayout.padding(top: 20, left: 20, bottom: 20, right: 20)
	}
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		blurView.frame = bounds
		frameLayout.frame = bounds
	}
	
}
