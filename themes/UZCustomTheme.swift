//
//  UZCustomTheme.swift
//  Uiza
//
//  Created by Nam Kennic on 8/17/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import UizaSDK

open class UZCustomTheme: UZPlayerTheme {
	// player will set this value automatically, you can access to all button controls inside this view
	public weak var controlView: UZPlayerControlView? = nil
	
	/*
	init your own controls in this function
	*/
	open func updateUI() {
		
	}
	
	/*
	layout your controls in this function
	*/
	open func layoutControls(rect: CGRect) {
		
	}
	
	/*
	put all cleanning code here, like removing delegate, remove gesture target ...
	*/
	open func cleanUI() {
		
	}
	
	/*
	override this to returns all custom buttons if applicable
	*/
	open func allButtons() -> [UIButton] {
		return []
	}
	
	/*
	show loading indicator
	*/
	open func showLoader() {
		
	}
	
	/*
	hide loading indicator
	*/
	open func hideLoader() {
		controlView?.loadingIndicatorView?.isHidden = true
		controlView?.loadingIndicatorView?.stopAnimating()
	}
	
	/*
	update your UI according to video or playlist
	*/
	open func update(withResource: UZPlayerResource?, video: UZVideoItem?, playlist: [UZVideoItem]?) {
		let isEmptyPlaylist = (playlist?.count ?? 0) == 0
		
		controlView?.nextButton.isHidden = isEmptyPlaylist
		controlView?.previousButton.isHidden = isEmptyPlaylist
		controlView?.forwardButton.isHidden = !isEmptyPlaylist
		controlView?.backwardButton.isHidden = !isEmptyPlaylist
	}
	
}
