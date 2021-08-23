//
//  UZMediaResource.swift
//  UizaPlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation

public struct UZPlayerResource {
	public let name: String
	public let cover: URL?
	public let subtitles: [URL]?
	public let definitions: [UZVideoLinkPlay]
	public var isLive: Bool = false
    public var timeshiftSupport: Bool = false
    public var timeShiftOn: Bool = false
	
	/**
	Player recource item with url, used to play single difinition video
	
	- parameter name:      video name
	- parameter url:       video url
	- parameter subtitles:   video subtitles
	- parameter cover:     video cover, will show before playing, and hide when play
	- parameter isLive:     set `true` if live video
	*/
    public init(name: String = "", url: URL, subtitles: [URL]? = nil, cover: URL? = nil, isLive: Bool = false, timeshiftSupport: Bool = false) {
		let definition = UZVideoLinkPlay(definition: "", url: url)
        self.init(name: name, definitions: [definition], subtitles: subtitles, cover: cover, isLive: isLive, timeshiftSupport: timeshiftSupport)
	}
	
	/**
	Play resouce with multi definitions
	
	- parameter name:        video name
	- parameter definitions: video definitions
	- parameter subtitles:   video subtitles
	- parameter cover:       video cover
	- parameter isLive:     set `true` if live video
	*/
    public init(name: String = "", definitions: [UZVideoLinkPlay], subtitles: [URL]? = nil, cover: URL? = nil, isLive: Bool = false, timeshiftSupport: Bool = false, timeShiftOn: Bool = false) {
		self.name        = name
		self.subtitles	 = subtitles
		self.cover       = cover
		self.definitions = definitions
		self.isLive 	 = isLive
        self.timeshiftSupport = timeshiftSupport
        self.timeShiftOn = timeShiftOn
	}
}
