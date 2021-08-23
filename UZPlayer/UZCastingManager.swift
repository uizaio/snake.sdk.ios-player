//
//  UZCastingManager.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/25/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
#if canImport(GoogleCast)
import GoogleCast

extension Notification.Name {
	
	static let UZDeviceListDidUpdate 	= Notification.Name(rawValue: "UZDeviceListDidUpdate")
	static let UZCastSessionDidStart	= Notification.Name(rawValue: "UZCastSessionDidStart")
	static let UZCastSessionDidStop 	= Notification.Name(rawValue: "UZCastSessionDidStop")
	static let UZCastClientDidStart		= Notification.Name(rawValue: "UZCastClientDidStart")
	static let UZCastClientDidUpdate	= Notification.Name(rawValue: "UZCastClientDidUpdate")
	static let UZDeviceDidReceiveText 	= Notification.Name(rawValue: "UZDeviceDidReceiveText")
	
}

public struct UZCastItem {
	var id: String
	var title: String
	var customData: [String: AnyHashable]?
	var streamType: GCKMediaStreamType
	var contentType: String
	var url: URL
	var thumbnailUrl: URL?
	var duration: TimeInterval
	var playPosition: TimeInterval
	var mediaTracks: [GCKMediaTrack]?
}

/*
Class quản lý việc casting
*/
open class UZCastingManager: NSObject {
	
	public static let shared = UZCastingManager()
	
	open var hasConnectedSession: Bool {
		return sessionManager.hasConnectedCastSession()
	}
	
	open var deviceCount: Int {
		return Int(discoverManager.deviceCount)
	}
	
	open func device(at index: UInt) -> GCKDevice {
		return discoverManager.device(at: index)
	}
	
	open var mediaDuration: TimeInterval {
		return remoteClient?.mediaStatus?.currentQueueItem?.mediaInformation.streamDuration ?? 0
	}
	
	open var lastPosition: TimeInterval = 0
	open var currentPosition: TimeInterval {
        if let remoteClient = remoteClient {
            return remoteClient.approximateStreamPosition()
        } else {
            return initPosition
        }
	}
	private var initPosition: TimeInterval = 0
	
	open var currentPlayerState: GCKMediaPlayerState {
        if let remoteClient = remoteClient,	let mediaStatus = remoteClient.mediaStatus {
            return mediaStatus.playerState
        } else {
            return .unknown
        }
	}
	
	open private(set) var discoverManager: GCKDiscoveryManager!
	open private(set) var sessionManager: GCKSessionManager!
	open private(set) var remoteClient: GCKRemoteMediaClient?
	
	open private(set) var currentCastSession: GCKCastSession?
	open private(set) var currentCastItem: UZCastItem?
	
	// MARK: -
	
	private override init() {
		super.init()
		
		let option = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
		GCKCastContext.setSharedInstanceWith(option)
		
		discoverManager = GCKCastContext.sharedInstance().discoveryManager
		sessionManager = GCKCastContext.sharedInstance().sessionManager
	}
	
	// MARK: - Discover
	
	open func startDiscovering() {
		DLog("Start Discovering")
		discoverManager.passiveScan = true
		discoverManager.add(self)
		discoverManager.startDiscovery()
	}
	
	open func stopDiscovering() {
		DLog("Stop Discovering")
		discoverManager.stopDiscovery()
	}
	
	// MARK: - Connect
	
	open func cast(item: UZCastItem, to device: GCKDevice) {
		connect(to: device, andCast: item)
	}
	
	open func connect(to device: GCKDevice, andCast item: UZCastItem? = nil) {
		currentCastItem = item
		
		sessionManager.add(self)
		sessionManager.startSession(with: device)
	}
	
	open func disconnect() {
		lastPosition = self.currentPosition
		
		sessionManager.endSessionAndStopCasting(true)
		currentCastSession = nil
		currentCastItem = nil
	}
	
	open func castItem(item: UZCastItem, with playlist: [UZCastItem]? = nil) {
		if let currentCastSession = currentCastSession {
			remoteClient = currentCastSession.remoteMediaClient
			remoteClient?.add(self)
		}
		
		if let playlist = playlist {
			for item in playlist {
				let queueItemBuilder = GCKMediaQueueItemBuilder()
				queueItemBuilder.mediaInformation = buildMediaInformation(from: item)
				queueItemBuilder.autoplay = true
				
				let queueLoadOptions = GCKMediaQueueLoadOptions()
				queueLoadOptions.repeatMode = .all
				queueLoadOptions.startIndex = 0
				queueLoadOptions.playPosition = playlist[Int(queueLoadOptions.startIndex)].playPosition
				
				remoteClient?.queueLoad([queueItemBuilder.build()], with: queueLoadOptions)
			}
		} else {
			let mediaInformation = buildMediaInformation(from: item)
			
			let loadOptions = GCKMediaLoadOptions()
			loadOptions.autoplay = true
			loadOptions.playPosition = item.playPosition
			initPosition = item.playPosition
			
			remoteClient?.loadMedia(mediaInformation, with: loadOptions).delegate = self
		}
	}
	
	fileprivate func buildMediaInformation(from item: UZCastItem) -> GCKMediaInformation {
		let metadata = GCKMediaMetadata(metadataType: .movie)
		metadata.setString(item.title, forKey: kGCKMetadataKeyTitle)
		
		if let device = currentCastSession?.device, let deviceName = device.friendlyName {
			metadata.setString(deviceName, forKey: kGCKMetadataKeyStudio)
		}
		
		if let thumbnailUrl = item.thumbnailUrl {
			metadata.addImage(GCKImage(url: thumbnailUrl, width: 720, height: 480))
		}
		
		let builder = GCKMediaInformationBuilder(contentURL: item.url)
		builder.streamType = item.streamType
		builder.contentType = item.contentType // "video/m3u8" , "application/dash+xml"
		builder.mediaTracks = item.mediaTracks
		builder.customData = item.customData
		builder.streamDuration = item.duration
		builder.textTrackStyle = GCKMediaTextTrackStyle.createDefault()
		builder.metadata = metadata
		
		return builder.build()
	}
	
	// MARK: -
	
	open func play() {
		remoteClient?.play()
	}
	
	open func pause() {
		remoteClient?.pause()
	}
	
	open func stop() {
		lastPosition = self.currentPosition
		remoteClient?.stop()
	}
	
	open func seek(to interval: TimeInterval, resumeState: GCKMediaResumeState = .unchanged) {
		let option = GCKMediaSeekOptions()
		option.interval = interval
		option.resumeState = resumeState
		remoteClient?.seek(with: option)
	}
	
	open func setVolume(_ volume: Float) {
		remoteClient?.setStreamVolume(volume)
	}
	
	open func setMute(_ muted: Bool) {
		remoteClient?.setStreamMuted(muted)
	}
	
	open func selectTracksIDs(_ tracks: [NSNumber]) {
		remoteClient?.setActiveTrackIDs(tracks)
	}

}

extension UZCastingManager: GCKDiscoveryManagerListener {
	
	public func didUpdateDeviceList() {
		PostNotification(Notification.Name.UZDeviceListDidUpdate)
	}
	
}

extension UZCastingManager: GCKSessionManagerListener {
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
		DLog("Did start cast session \(session)")
		
		currentCastSession = session
		PostNotification(Notification.Name.UZCastSessionDidStart, object: session, userInfo: nil)
		
		if let castItem = currentCastItem {
			self.castItem(item: castItem)
		}
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
		DLog("Did resume cast session \(session)")
		
		currentCastSession = session
		PostNotification(Notification.Name.UZCastSessionDidStart, object: session, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceStatus statusText: String?) {
		DLog("Did receive status: \(String(describing: statusText))")
		
		PostNotification(Notification.Name.UZDeviceDidReceiveText, object: statusText, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
		DLog("Did end with error \(String(describing: error))")
		
		currentCastSession = nil
		currentCastItem = nil
		PostNotification(Notification.Name.UZCastSessionDidStop, object: currentCastSession, userInfo: nil)
	}
	
	public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
		DLog("Did suspend with reason: \(reason.rawValue)")
		
		lastPosition = self.currentPosition
		currentCastSession = nil
		PostNotification(Notification.Name.UZCastSessionDidStop, object: currentCastSession, userInfo: nil)
	}
	
}

extension UZCastingManager: GCKRemoteMediaClientListener {
	
	public func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
		DLog("Client did start: \(sessionID)")
		PostNotification(Notification.Name.UZCastClientDidStart, object: sessionID, userInfo: nil)
	}
	
	public func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
		DLog("Client did update: \(String(describing: mediaStatus?.idleReason.rawValue))")
		PostNotification(Notification.Name.UZCastClientDidUpdate, object: mediaStatus, userInfo: nil)
	}
	
}

extension UZCastingManager: GCKRequestDelegate {
	
	public func requestDidComplete(_ request: GCKRequest) {
		DLog("Request completed")
	}
	
	public func request(_ request: GCKRequest, didFailWithError error: GCKError) {
		DLog("Request failed: \(error)")
		lastPosition = self.currentPosition
	}
	
	public func request(_ request: GCKRequest, didAbortWith abortReason: GCKRequestAbortReason) {
		DLog("Request aborted: \(abortReason.rawValue)")
	}
	
}
#endif
