//
//  UZMediaOptionSelectionViewController+.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 5/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVFoundation
import NKModalViewManager

// MARK: - UZMediaOptionItemCollectionViewCell

import FrameLayoutKit

class UZMediaOptionItemCollectionViewCell: UICollectionViewCell {
    var highlightView: UIView!
    var titleLabel: UILabel!
    var frameLayout: DoubleFrameLayout!
    var highlightMode        = false {
        didSet {
            self.isSelected = super.isSelected
        }
    }
    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set (value) {
            super.isHighlighted = value
            self.updateColor()
        }
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set (value) {
            super.isSelected = value
            if #available(iOS 8.2, *) {
                titleLabel.font = UIFont.systemFont(ofSize: 14, weight: value ? .bold : .regular)
            } else {
                titleLabel.font = UIFont.systemFont(ofSize: 14)
            }
            
            if highlightMode {
                UIView.animate(withDuration: 0.3) {
                    self.contentView.alpha = value ? 1.0 : 0.25
                }
            } else {
                self.contentView.alpha = 1.0
                self.updateColor()
            }
        }
    }
    
    var option: AVMediaSelectionOption? = nil {
        didSet {
            updateView()
        }
    }
    
    var subtitle: UZVideoSubtitle? {
        didSet {
            if let name = subtitle?.name {
                titleLabel.text = name
                self.setNeedsLayout()
            }
        }
    }
    
    func updateColor() {
        if self.isHighlighted {
            highlightView.alpha = 1.0
            highlightView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
            titleLabel.textColor = .black
        } else if self.isSelected {
            highlightView.alpha = 1.0
            highlightView.backgroundColor = UIColor(red: 0.21, green: 0.49, blue: 0.96, alpha: 1.00)
            titleLabel.textColor = .white
        } else {
            titleLabel.textColor = .white
            
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                self.highlightView.alpha = 0.0
            })
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .clear
        
        self.backgroundView = UIView()
        self.backgroundView!.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        self.backgroundView!.layer.cornerRadius = 10
        self.backgroundView!.layer.masksToBounds = true
        
        highlightView = UIView()
        highlightView.alpha = 0.0
        highlightView.layer.cornerRadius = 10
        highlightView.layer.masksToBounds = true
        
        titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.numberOfLines = 1
        titleLabel.textColor = .white
        
        self.contentView.addSubview(highlightView)
        self.contentView.addSubview(titleLabel)
        
        frameLayout = DoubleFrameLayout(axis: .horizontal, views: [titleLabel])
        frameLayout.bottomFrameLayout.fixSize = CGSize(width: 0, height: 40)
        frameLayout.distribution = .center
        frameLayout.spacing = 0
        self.contentView.addSubview(frameLayout)
        
        self.updateColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    func updateView() {
        titleLabel.text = option?.displayName
        self.setNeedsLayout()
    }
    
    // MARK: -
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frameLayout.frame = self.bounds
        
        if let backgroundView = backgroundView {
			let edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
			
			#if swift(>=4.2)
			backgroundView.frame = self.contentView.bounds.inset(by: edgeInsets)
			#else
			backgroundView.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, edgeInsets)
			#endif
			
            highlightView.frame = backgroundView.frame
        }
    }
    
}

// MARK: - UZTitleCollectionViewHeader

class UZTitleCollectionViewHeader: UICollectionReusableView {
    
    let label = UILabel()
    var frameLayout: FrameLayout!
    
    var title: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
            self.setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        } else {
            label.font = UIFont.systemFont(ofSize: 14)
        }
        label.textColor = .gray
        
        frameLayout = FrameLayout(targetView: label)
        frameLayout.addSubview(label)
        frameLayout.padding(top: 10, left: 10, bottom: 0, right: 0)
        self.addSubview(frameLayout)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        //        layoutAttributes.zIndex = 0
        super.apply(layoutAttributes)
        self.layer.zPosition = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return frameLayout.sizeThatFits(size)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        frameLayout.frame = self.bounds
    }
    
}
