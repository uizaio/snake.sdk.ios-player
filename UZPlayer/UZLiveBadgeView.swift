//
//  UZLiveBadgeView.swift
//  UZPlayer
//
//  Created by Nam Nguyễn on 5/29/20.
//  Copyright © 2020 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit

open class UZLiveBadgeView: UIView {
	
	public var views: Int = 0 {
		didSet {
			if views < 0 {
				viewBadge.setTitle("0", for: .normal)
			} else {
				viewBadge.setTitle("\(views.abbreviated)", for: .normal)
			}
			
			viewBadge.isHidden = views < 0
			setNeedsLayout()
		}
	}
	
	open var liveBadge = UZButton()
	open var viewBadge = UZButton()
	let frameLayout = DoubleFrameLayout(axis: .horizontal)
	
	init() {
		super.init(frame: .zero)
		
		if #available(iOS 8.2, *) {
			liveBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
		} else {
			liveBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12)
		}
		liveBadge.setTitle("LIVE", for: .normal)
		liveBadge.titleColors[.normal] = .white
		liveBadge.titleColors[.disabled] = .white
		liveBadge.backgroundColors[.normal] = .gray
		liveBadge.backgroundColors[.disabled] = UIColor(red: 0.91, green: 0.31, blue: 0.28, alpha: 1.00)
		liveBadge.cornerRadius = 4
		liveBadge.extendSize = CGSize(width: 10, height: 0)
		
		let icon = UIImage.init(icon: .googleMaterialDesign(.removeRedEye), size: CGSize(width: 20, height: 20),
								textColor: .white, backgroundColor: .clear)
		
        
        viewBadge.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
		viewBadge.setTitleColor(.white, for: .normal)
		viewBadge.setTitle("0", for: .normal)
		viewBadge.setImage(icon, for: .normal)
		viewBadge.setBackgroundColor(UIColor(white: 0.6, alpha: 0.8), for: .normal)
		viewBadge.extendSize = CGSize(width: 10, height: 0)
		viewBadge.cornerRadius = 4
		viewBadge.spacing = 2
		
		addSubview(viewBadge)
		addSubview(liveBadge)
		
		frameLayout <+ liveBadge
		frameLayout +> viewBadge
		
		frameLayout.spacing = 5
		frameLayout.isIntrinsicSizeEnabled = true
		frameLayout.isUserInteractionEnabled = false
		addSubview(frameLayout)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open override func sizeThatFits(_ size: CGSize) -> CGSize {
		return frameLayout.sizeThatFits(size)
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		frameLayout.frame = bounds
	}
	
}
