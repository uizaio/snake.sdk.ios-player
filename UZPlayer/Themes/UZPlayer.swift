//
//  UZPlayer.swift
//  SnakePlayerSDK
//
//  Created by Nam Kennic on 11/7/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation
import CoreGraphics
import FrameLayoutKit
import UZM3U8Kit

#if canImport(NHNetworkTime)
import NHNetworkTime
#endif

#if canImport(GoogleInteractiveMediaAds)
import GoogleInteractiveMediaAds
#endif

#if canImport(GoogleCast)
import GoogleCast
#endif

let PLAYER_VERSION = "2.0"


let DEFAULT_SEEK_FORWARD: TimeInterval = TimeInterval(10)
let DEFAULT_SEEK_BACKWARD: TimeInterval = TimeInterval(-10)


func DLog(_ message: String, _ file: String = #file, _ line: Int = #line) {
	#if DEBUG
	print("\((file as NSString).lastPathComponent) [Line \(line)]: \((message))")
	#endif
}

public protocol UZPlayerDelegate: AnyObject {
	func player(player: UZPlayer, playerStateDidChange state: UZPlayerState)
	func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
	func player(player: UZPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
	func player(player: UZPlayer, playerIsPlaying playing: Bool)
	func player(player: UZPlayer, playerDidFailToPlayToEndTime error: Error?)
	func player(playerDidStall: UZPlayer)
	func player(playerDidEndLivestream: UZPlayer)
}

public protocol UZPlayerControlViewDelegate: AnyObject {
	func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int)
	func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton)
	func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
}

public protocol UZSettingViewDelegate: AnyObject {
    func settingRow(didChanged sender: UISwitch)
    func settingRow(didSelected tag: UZSettingTag, value: Float)
    func settingRow(didSelected tag: UZSettingTag, value: AVMediaSelectionOption?)
}

// to make them optional
extension UZPlayerDelegate {
	func player(player: UZPlayer, playerStateDidChange state: UZPlayerState) {}
	func player(player: UZPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {}
	func player(player: UZPlayer, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {}
	func player(player: UZPlayer, playerIsPlaying playing: Bool) {}
	func player(player: UZPlayer, playerDidFailToPlayToEndTime error: Error?) {}
	func player(playerDidStall: UZPlayer) {}
	func player(playerDidEndLivestream: UZPlayer) {}
}

extension UZPlayerControlViewDelegate {
	func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int) {}
	func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton) {}
	func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event) {}
}

open class UZPlayer: UIView {
	static public let ShowAirPlayDeviceListNotification = Notification.Name(rawValue: "ShowAirPlayDeviceListNotification")
	open weak var delegate: UZPlayerDelegate?
	
	public var backBlock: ((Bool) -> Void)?
	public var videoChangedBlock: ((UZVideoItem) -> Void)?
	public var fullscreenToggleBlock: ((Bool?) -> Void)?
	public var buttonSelectionBlock: ((UIButton) -> Void)?
	public var playTimeDidChange: ((_ currentTime: TimeInterval, _ totalTime: TimeInterval) -> Void)?
	public var playStateDidChange: ((_ isPlaying: Bool) -> Void)?
	
	public var videoGravity = AVLayerVideoGravity.resizeAspect {
		didSet {
			self.playerLayerView?.videoGravity = videoGravity
		}
	}
	
	public var aspectRatio: UZPlayerAspectRatio = .default {
		didSet {
			self.playerLayerView?.aspectRatio = self.aspectRatio
		}
	}
	
	public var isPlaying: Bool { playerLayerView?.isPlaying ?? false }
	
	public var avPlayer: AVPlayer? { playerLayerView?.player }
	
    public var subtitleGroup : AVMediaSelectionGroup? { avPlayer?.currentItem?.asset.subtitleGroup }
    
	public var subtitleOptions: [AVMediaSelectionOption]? { avPlayer?.currentItem?.asset.subtitles }
    
    public var audioGroup : AVMediaSelectionGroup? { avPlayer?.currentItem?.asset.audioGroup }
    
	public var audioOptions: [AVMediaSelectionOption]? { avPlayer?.currentItem?.asset.audioTracks }
    
    public var videoQualities: [AVMediaCharacteristic]? { avPlayer?.currentItem?.asset.availableMediaCharacteristicsWithMediaSelectionOptions }
	
	public var playlist: [UZVideoItem]? = nil {
		didSet {
			controlView.currentPlaylist = playlist
			controlView.playlistButton.isHidden = (playlist?.isEmpty ?? true)
			controlView.setNeedsLayout()
		}
	}
    
    open func currentAudioOption() -> AVMediaSelectionOption? {
        guard let currentItem = avPlayer?.currentItem, let audioGroup = currentItem.asset.audioGroup else { return nil }
		return currentItem.currentMediaSelection.selectedMediaOption(in: audioGroup)
    }
    
    open func changeAudioSelect(option: AVMediaSelectionOption?) {
        guard let currentItem = self.avPlayer?.currentItem, let audioGroup = currentItem.asset.audioGroup else { return }
		currentItem.select(option, in: audioGroup)
    }
    
    open func currentSubtileOption() -> AVMediaSelectionOption? {
        guard let currentItem = avPlayer?.currentItem, let subtitleGroup = currentItem.asset.subtitleGroup else { return nil }
		return currentItem.currentMediaSelection.selectedMediaOption(in: subtitleGroup)
    }
    
    open func changeSubtitleSelect(option: AVMediaSelectionOption?) {
        guard let currentItem = avPlayer?.currentItem, let subtitleGroup = currentItem.asset.subtitleGroup else { return }
		currentItem.select(option, in: subtitleGroup)
    }
    
    open func changeBitrate(bitrate: Double) {
		guard let currentItem = avPlayer?.currentItem else { return }
		currentItem.preferredPeakBitRate = bitrate
    }
    
    open func currentBitrate() -> Double { avPlayer?.currentItem?.preferredPeakBitRate ?? 0.0 }
    
	public var currentVideoIndex: Int {
		get {
			if let currentVideo = currentVideo, let playlist = playlist {
				if let result = playlist.firstIndex(of: currentVideo) {
					return result
				} else {
					var index = 0
					for video in playlist {
						if video == currentVideo {
							return index
						}
						
						index += 1
					}
				}
			}
			
			return -1
		}
		set {
			if let playlist = playlist, newValue > -1 && newValue < playlist.count {
				loadVideo(playlist[newValue])
			}
		}
	}
	
	public internal(set) var currentVideo: UZVideoItem? {
		didSet {
			controlView.currentVideo = currentVideo
			playerLayerView?.currentVideo = currentVideo
		}
	}
	
	public internal(set) var currentLinkPlay: UZVideoLinkPlay? {
		didSet {
			UZLogger.shared.currentLinkPlay = currentLinkPlay?.url
		}
	}
	
	public var themeConfig: UZPlayerConfig? = nil {
		didSet {
			controlView.playerConfig = themeConfig
			
			if let config = themeConfig {
				shouldAutoPlay = config.autoStart
			}
		}
	}
	
	public var isAutoRetry: Bool = false {
		didSet {
			playerLayerView?.isAutoRetry = isAutoRetry
		}
	}
	public var shouldAutoPlay = true
	public var shouldShowsControlViewAfterStoppingPiP = true
	public var autoTryNextDefinitionIfError = true
	public var controlView: UZPlayerControlView!
	public var liveEndedMessage = "This live video has ended"
    
    let pipKeyPath = #keyPath(AVPictureInPictureController.isPictureInPicturePossible)
    var playerViewControllerKVOContext = 0
    
    var playThroughEventLog: [Float: Bool] = [:]
    let logPercent: [Float] = [25, 50, 75, 100]
    var sendWatchingLiveEventTimer: Timer?
	
	open var customControlView: UZPlayerControlView? {
		didSet {
			guard customControlView != controlView else { return }
			
			if controlView != nil {
				controlView.delegate = nil
				controlView.removeFromSuperview()
			}
			
			controlView = customControlView ?? UZPlayerControlView()
			controlView.updateUI(isFullScreen)
			controlView.delegate = self
			addSubview(controlView)
		}
	}
	
	public var preferredForwardBufferDuration: TimeInterval = 2 {
		didSet {
			playerLayerView?.preferredForwardBufferDuration = preferredForwardBufferDuration
		}
	}
	
	public internal(set) var resource: UZPlayerResource! {
		didSet {
			controlView.resource = resource
		}
	}

	public internal(set) var currentDefinition = 0
	public internal(set) var playerLayerView: UZPlayerLayerView?
	
    var liveViewTimer: Timer?
    var isFullScreen: Bool { UIApplication.shared.statusBarOrientation.isLandscape }
	
	public internal(set) var totalDuration: TimeInterval = 0
	public internal(set) var currentPosition: TimeInterval = 0
	
	public internal(set) var isURLSet        = false
	public internal(set) var isSliderSliding = false
	public internal(set) var isPauseByUser   = false
	public internal(set) var isPlayToTheEnd  = false
	public fileprivate(set) var isReplaying	 = false
	
    #if canImport(GoogleInteractiveMediaAds)
	fileprivate var contentPlayhead: IMAAVPlayerContentPlayhead?
	fileprivate var adsLoader: IMAAdsLoader?
	fileprivate var adsManager: IMAAdsManager?
    #endif
	
	fileprivate var _pictureInPictureController: Any?
	@available(iOS 9.0, *)
	public internal(set) var pictureInPictureController: AVPictureInPictureController? {
		get { _pictureInPictureController as? AVPictureInPictureController }
		set { _pictureInPictureController = newValue }
	}
    var visualizeInformationView: UZVisualizeInformationView?
	public var autoPauseWhenInactive = true
	
	// MARK: -
	public init() {
		super.init(frame: .zero)
		
		setupUI()
		preparePlayer()
		
		NotificationCenter.default.addObserver(self, selector: #selector(volumeDidChange(notification:)),
                                               name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
                                               object: nil)
		
		#if DEBUG
		print("[UizaPlayer \(PLAYER_VERSION)] initialized")
		#endif
		
		UZLogger.shared.log(event: "playerready")
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public convenience init (customControlView: UZPlayerControlView?) {
		self.init()
		defer { self.customControlView = customControlView }
	}
	
	// MARK: -
	
	/**
	Play a video with given URL
	
	- parameter url: URL of linkplay
	- parameter subtitleURLs: URLs of subtitle if any
	*/
	open func loadVideo(url: URL, subtitleURLS: [URL]? = nil) {
		let linkPlay = UZVideoLinkPlay(definition: "", url: url)
		let item = UZVideoItem(name: "", thumbnailURL: nil, linkPlay: linkPlay, subtitleURLs: subtitleURLS)
		loadVideo(item)
	}
	
	/**
	Play an `UZVideoItem`
	
	- parameter video: UZVideoItem
	*/
	open func loadVideo(_ video: UZVideoItem) {
		UZLogger.shared.log(event: "loadstart")
		if currentVideo != nil {
			stop()
			preparePlayer()
		}
		currentVideo = video
		playThroughEventLog = [:]
		
		removeSubtitleLabel()
		controlView.hideMessage()
		controlView.hideEndScreen()
		controlView.showControlView()
		controlView.showLoader()
		controlView.liveStartDate = nil
        UZVisualizeSavedInformation.shared.currentVideo = video
		
		guard let linkPlay = video.linkPlay else { return }
		
		if let host = linkPlay.url.host { UZVisualizeSavedInformation.shared.host = host }
        
		let resource = UZPlayerResource(name: video.name ?? "", definitions: [linkPlay], subtitles: video.subtitleURLs, cover: video.thumbnailURL, isLive: video.isLive, timeshiftSupport: video.timeshiftSupport, timeShiftOn: video.isTimeshiftOn)
        setResource(resource: resource)
		
		if video.isLive {
			controlView.liveStartDate = nil
			loadLiveViews()
			sendWatchingLiveEvent()
		}
	}
    
    open func switchTimeshiftMode(_ timeshiftOn: Bool) -> Bool {
        guard let video = currentVideo else { return false }
		
        if video.extIsTimeshift {
            guard let extLinkPlay = timeshiftOn ? video.extLinkPlay : video.linkPlay else { return false }
            let resource = UZPlayerResource(name: video.name ?? "", definitions: [extLinkPlay], subtitles: video.subtitleURLs, cover: video.thumbnailURL, isLive: video.isLive, timeshiftSupport: video.timeshiftSupport)
            setResource(resource: resource)
            setTimeshiftOn(timeshiftOn)
            return true
        } else {
            guard let linkPlay = timeshiftOn ? video.linkPlay : video.extLinkPlay else { return false}
            let resource = UZPlayerResource(name: video.name ?? "", definitions: [linkPlay], subtitles: video.subtitleURLs, cover: video.thumbnailURL, isLive: video.isLive, timeshiftSupport: video.timeshiftSupport)
            setResource(resource: resource)
            setTimeshiftOn(timeshiftOn)
            return true
        }
    }
    
    open func setTimeshiftOn(_ timeshiftOn: Bool) {
        currentVideo?.isTimeshiftOn = timeshiftOn
        controlView.setUIWithTimeshift(timeshiftOn)
    }
    
    open func isTimeshiftOn() -> Bool { currentVideo?.isTimeshiftOn ?? false }
    open func isTimeshiftSupport() -> Bool { currentVideo?.timeshiftSupport ?? false }
    open func isLive() -> Bool { currentVideo?.isLive ?? false }
	
	open func playIfApplicable() {
		if !isPauseByUser && isURLSet && !isPlayToTheEnd {
			play()
		}
	}
	
	open func play() {
		if resource == nil { return }
		
		if !isURLSet {
			currentLinkPlay = resource.definitions[currentDefinition]
			playerLayerView?.playAsset(asset: currentLinkPlay!.avURLAsset)
			controlView.hideCoverImageView()
			isURLSet = true
		}
        
        addPeriodicTime()
		
		playerLayerView?.play()
		isPauseByUser = false
		
		if #available(iOS 9.0, *) {
			if pictureInPictureController == nil { setupPictureInPicture() }
		}
		
		if currentPosition == 0 && !isPauseByUser {
			if playThroughEventLog[0] == false || playThroughEventLog[0] == nil {
				playThroughEventLog[0] = true
				UZLogger.shared.log(event: "viewstart")
				
                // select default subtitle
                if subtitles.isEmpty {
                    selectSubtitle(index: 0)
                } else {
                    if let subtitle = subtitles.filter({ $0.isDefault }).first {
                        selectExtenalSubtitle(subtitle: subtitle)
                    } else if let subtitle = subtitles.first {
                        selectExtenalSubtitle(subtitle: subtitle)
                    }
                }
//				selectAudio(index: -1) // select default audio track
			}
		}
		
		if currentVideo?.isLive ?? false {
			sendWatchingLiveEvent(every: 5)
		}
	}
	
	/**
	Stop and unload the player
	*/
	open func stop() {
		if liveViewTimer != nil {
			liveViewTimer!.invalidate()
			liveViewTimer = nil
		}
		
		if sendWatchingLiveEventTimer != nil {
			sendWatchingLiveEventTimer!.invalidate()
			sendWatchingLiveEventTimer = nil
		}
		
		controlView.liveStartDate = nil
		controlView.hideEndScreen()
		controlView.hideMessage()
		controlView.hideCoverImageView()
		controlView.playTimeDidChange(currentTime: 0, totalTime: 0)
		controlView.loadedTimeDidChange(loadedDuration: 0, totalDuration: 0)
		
		playerLayerView?.prepareToDeinit()
		playerLayerView = nil
	}
	
	/**
	Seek to 0.0 and replay the video
	*/
	open func replay() {
		UZLogger.shared.log(event: "replay")
		
		playThroughEventLog = [:]
		isPlayToTheEnd = false
		isReplaying = true
		
		seek(to: 0.0) { [weak self] in
			self?.isReplaying = false
		}
	}
	
	/**
	Pause
	*/
	open func pause() {
		UZLogger.shared.log(event: "pause")
		playerLayerView?.pause()
		
		if sendWatchingLiveEventTimer != nil {
			sendWatchingLiveEventTimer!.invalidate()
			sendWatchingLiveEventTimer = nil
		}
	}
	
	/**
	Seek to time
	
	- parameter to: target time
	*/
	open func seek(to interval: TimeInterval, completion: (() -> Void)? = nil) {
		UZLogger.shared.log(event: "seeking")

		currentPosition = interval
		controlView.hideEndScreen()
		
		playerLayerView?.seek(to: interval, completion: {
			UZLogger.shared.log(event: "seeked")
			completion?()
		})
		
        #if canImport(GoogleCast)
		let castingManager = UZCastingManager.shared
		if castingManager.hasConnectedSession {
			playerLayerView?.pause()
			castingManager.seek(to: interval)
		}
		#endif
	}
	
	/**
	Seek offset
	
	- parameter offset: offset from current time
	*/
	open func seek(offset: TimeInterval, completion: (() -> Void)? = nil) {
		guard let avPlayer = avPlayer else { return }
		let currentTime = CMTimeGetSeconds(avPlayer.currentTime())
		let maxTime = max(currentTime + offset, 0)
		let toTime = min(maxTime, totalDuration)
		seek(to: toTime, completion: completion)
	}
	
	open func switchVideoDefinition(_ linkplay: UZVideoLinkPlay) {
		guard currentLinkPlay != linkplay else { return }
		currentLinkPlay = linkplay
		playerLayerView?.shouldSeekTo = currentPosition
		
		playerLayerView?.replaceAsset(asset: linkplay.avURLAsset)
		setupPictureInPicture() // reset it
	}

    public var isVisualizeInfoEnabled: Bool = false {
        didSet {
            if isVisualizeInfoEnabled {
				if visualizeInformationView == nil {
					visualizeInformationView = UZVisualizeInformationView()
				}
				
                addSubview(visualizeInformationView!)
                addSubview(visualizeInformationView!.closeButton)
            } else {
                visualizeInformationView?.removeFromSuperview()
                visualizeInformationView?.closeButton.removeFromSuperview()
            }
        }
    }
	
    var subtitleLabel: UILabel?
    var subtitles: [UZVideoSubtitle] = []
    var selectedSubtitle: UZVideoSubtitle?
    var timeObserver: Any?
    var savedSubtitles: UZSubtitles? {
        didSet {
            removeSubtitleLabel()
            if savedSubtitles != nil {
                addSubtitleLabel()
                addPeriodicTime()
            }
        }
    }
	
	// MARK: -
	
	deinit {
		if #available(iOS 9.0, *) {
			if pictureInPictureController != nil {
				pictureInPictureController!.delegate = nil
				pictureInPictureController!.removeObserver(self, forKeyPath: pipKeyPath, context: &playerViewControllerKVOContext)
			}
		} else {
			// Fallback on earlier versions
		}
		
		playerLayerView?.pause()
		playerLayerView?.prepareToDeinit()
		NotificationCenter.default.removeObserver(self)
	}
}
