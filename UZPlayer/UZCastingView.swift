//
//  UZCastingView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/28/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AVFoundation

class UZCastingView: UIView {
	let titleLabel = UILabel()
	let imageView = UIImageView()

	init() {
		super.init(frame: .zero)
		self.backgroundColor = .black
		
		if #available(iOS 8.2, *) {
			titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
		} else {
			titleLabel.font = UIFont.systemFont(ofSize: 14)
		}
		titleLabel.textColor = .white
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 2
		
//		var icon: UIImage? = nil
//		if AVAudioSession.sharedInstance().isAirPlaying {
//			titleLabel.text = "Playing on \(AVAudioSession.sharedInstance().sourceName ?? "(??)")"
//			icon = UIImage(icon: .googleMaterialDesign(.airplay), size: CGSize(width: 120, height: 120), textColor: UIColor(white: 1.0, alpha: 0.7), backgroundColor: .clear)
//		}
//		else if let castSession = UZCastingManager.shared.currentCastSession {
//			let device = castSession.device
//			titleLabel.text = "Playing on \(device.modelName ?? "(??)")"
//			icon = UIImage(icon: .googleMaterialDesign(.tv), size: CGSize(width: 120, height: 120), textColor: UIColor(white: 1.0, alpha: 0.7), backgroundColor: .clear)
//		}
		
//		imageView.image = icon
		imageView.contentMode = .scaleAspectFit
		
		self.addSubview(imageView)
		self.addSubview(titleLabel)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let viewSize = self.bounds.size
		let labelSize = titleLabel.sizeThatFits(viewSize)
		let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
		
		#if swift(>=4.2)
		imageView.frame = self.bounds.inset(by: edgeInsets)
		#else
		imageView.frame = UIEdgeInsetsInsetRect(self.bounds, edgeInsets)
		#endif
		
		titleLabel.frame = CGRect(x: 0, y: viewSize.height - labelSize.height - 20, width: viewSize.width, height: labelSize.height)
	}
	
}
