//
//  UZPlayerConfig.swift
//  UizaSDK
//
//  Created by Nam Kennic on 9/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit

public struct UZPlayerConfig {
	public var endscreenMessage: String?
	public var autoStart = true
	public var preloadVideo = true
	public var allowFullscreen = true
	public var allowSharing = true
	public var displayPlaylist = true
	public var showEndscreen = true
	public var showQualitySelector = false
	public var showLogo = false
	public var logoImageUrl: URL?
	public var logoRedirectUrl: URL?
	public var logoDisplayPosition: String?
}
