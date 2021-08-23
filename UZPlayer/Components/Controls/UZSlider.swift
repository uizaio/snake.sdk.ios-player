//
//  UZSlider.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/4/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit

open class UZSlider: UISlider {
	
	public let progressView = NKProgressView()
	
	public init() {
		super.init(frame: .zero)
		
		progressView.isRounded = true
		progressView.progressColor = UIColor(red: 0.18, green: 0.44, blue: 0.81, alpha: 1.00)
		self.insertSubview(progressView, at: 0)
		
		let thumbImage = UIImage(icon: .googleMaterialDesign(.fiberManualRecord), size: CGSize(width: 32, height: 32),
                                 textColor: .black, backgroundColor: .clear)
		self.setThumbImage(thumbImage, for: .normal)
		
		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(gesture:)))
		self.addGestureRecognizer(panGesture)
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture(gesture:)))
		self.addGestureRecognizer(tapGesture)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	// MARK: -
	
	@objc func tapGesture(gesture: UITapGestureRecognizer) {
		handleTouchGesture(gesture: gesture)
	}
	
	@objc func panGesture(gesture: UITapGestureRecognizer) {
		handleTouchGesture(gesture: gesture)
	}
	
	open func handleTouchGesture(gesture: UITapGestureRecognizer) {
		let currentPoint = gesture.location(in: self)
		let percentage = currentPoint.x / self.bounds.size.width
		let delta = Float(percentage) *  (self.maximumValue - self.minimumValue)
		let value = self.minimumValue + delta
		self.setValue(value, animated: true)
		self.sendActions(for: .valueChanged)
		
		if gesture.state == .began || gesture.state == .changed {
			self.sendActions(for: .touchDown)
		} else {
			self.sendActions(for: .touchUpInside)
		}
	}
	
	// MARK: -
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		progressView.frame = self.trackRect(forBounds: self.bounds)
	}
	
	override open func trackRect(forBounds bounds: CGRect) -> CGRect {
		let trackHeight = CGFloat(2)
		let position = CGPoint(x: 0, y: bounds.origin.y + (bounds.size.height - trackHeight) / 2)
		let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeight))
		super.trackRect(forBounds: customBounds)
		return customBounds
	}
	
	override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
//		let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
//		let thumbSize = CGSize(width: 48, height: 48)
//		let newx = rect.origin.x - (CGFloat(value) * (rect.size.width + thumbSize.width))
//		let newRect = CGRect(x: newx, y: rect.origin.y + (rect.size.height - thumbSize.height)/2, width: thumbSize.width, height: thumbSize.height)
//		return newRect
		
		return super.thumbRect(forBounds: bounds, trackRect: rect, value: value)//.offsetBy(dx: 0, dy: -7)
	}
	
	override open func sizeThatFits(_ size: CGSize) -> CGSize {
		return CGSize(width: size.width, height: min(size.height, 48))
	}
	
}
