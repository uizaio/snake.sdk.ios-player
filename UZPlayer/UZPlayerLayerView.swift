//
//  UZPlayerLayerView.swift
//  UizaSDK
//
//  Created by Nam Kennic on 7/10/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

/// Player status enum
public enum UZPlayerState: Int {
	/// Not set url yet
	case notSetURL
	/// Player ready to play
	case readyToPlay
	/// Player buffering
	case buffering
	/// Buffer finished
	case bufferFinished
	/// Played to the End
	case playedToTheEnd
	/// Error with playing
	case error
}

/// Video aspect ratio types
public enum UZPlayerAspectRatio {
	/// Default aspect
	case `default`
	/// Aspect Fill
	case aspectFill
	/// 16:9
	case sixteen2Nine
    /// 16:10
    case sixteen2Ten
	/// 4:3
	case four2Three
    
    var description : String {
      switch self {
          case .default: return "Default"
          case .aspectFill: return "Aspect Fill"
          case .sixteen2Nine: return "16:9"
          case .sixteen2Ten: return "16:10"
          case .four2Three: return "4:3"
        }
    }
}
/// Speed rate
public enum UZSpeedRate: Float, CaseIterable {
    case x025 = 0.25
    case x05 = 0.5
    case x075 = 0.75
    case normal = 1.0
    case x125 = 1.25
    case x150 = 1.5
    case x175 = 1.75
    case x2 = 2.0
    
    var description : String {
      switch self {
          case .x025: return "0.25x"
          case .x05: return "0.5x"
          case .x075: return "0.75x"
          case .normal: return "Normal"
          case .x125: return "1.25x"
          case .x150: return "1.5x"
          case .x175: return "1.75x"
          case .x2: return "2x"
        }
    }
}

protocol UZPlayerLayerViewDelegate: class {
	func player(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState)
	func player(player: UZPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
	func player(player: UZPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
	func player(player: UZPlayerLayerView, playerIsPlaying playing: Bool)
	func player(player: UZPlayerLayerView, playerDidFailToPlayToEndTime error: Error?)
	func player(playerRequiresSeekingToLive: UZPlayerLayerView)
	func player(playerDidStall: UZPlayerLayerView)
}

open class UZPlayerLayerView: UIView {
	weak var delegate: UZPlayerLayerViewDelegate?
	
	open var playerItem: AVPlayerItem? {
		didSet {
			onPlayerItemChange()
		}
	}
	
	public internal(set) var currentVideo: UZVideoItem?
	
	public var preferredForwardBufferDuration: TimeInterval = 0 {
		didSet {
			if let playerItem = playerItem {
				if #available(iOS 10.0, *) {
					playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration
				}
			}
		}
	}
	
	open lazy var player: AVPlayer? = {
		guard let item = playerItem else { return nil }
		let player = AVPlayer(playerItem: item)
		return player
	}()
	
	open var videoGravity = AVLayerVideoGravity.resizeAspect {
		didSet {
			playerLayer?.videoGravity = videoGravity
		}
	}
	
	open var isPlaying: Bool = false {
		didSet {
			if oldValue != isPlaying {
				delegate?.player(player: self, playerIsPlaying: isPlaying)
			}
		}
	}
	
	public var aspectRatio: UZPlayerAspectRatio = .default {
		didSet {
			setNeedsLayout()
		}
	}
	
	public internal(set) var playerLayer: AVPlayerLayer?
	
	fileprivate var timer: Timer?
	fileprivate var getLatencytimer: Timer?
	fileprivate var urlAsset: AVURLAsset?
	fileprivate var subtitleURL: URL?
	fileprivate var lastPlayerItem: AVPlayerItem?
	
	fileprivate var state = UZPlayerState.notSetURL {
		didSet {
			if state != oldValue {
				delegate?.player(player: self, playerStateDidChange: state)
			}
		}
	}
	
	fileprivate var isBuffering = false
	fileprivate var isReadyToPlay = false
	internal var shouldSeekTo: TimeInterval = 0
	
	// MARK: - Actions
	
	open func playURL(url: URL) {
		let asset = AVURLAsset(url: url)
		playAsset(asset: asset)
	}
	
	open func playAsset(asset: AVURLAsset, subtitleURL: URL? = nil) {
		self.urlAsset = asset
		self.subtitleURL = subtitleURL
		
		configPlayerAndCheckForPlayable()
		play()
	}
	
	open func replaceAsset(asset: AVURLAsset, subtitleURL: URL? = nil) {
		self.urlAsset = asset
		self.subtitleURL = subtitleURL
		
		playerItem = configPlayerItem()
		player?.replaceCurrentItem(with: playerItem)
		checkForPlayable()
	}
	
	open func play() {
		#if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession {
			UZCastingManager.shared.play()
			setupTimer()
			isPlaying = true
			return
		}
		#endif
		
		if let player = player {
			player.play()
			setupTimer()
			isPlaying = true
		}
	}
	
	open func pause(alsoPauseCasting: Bool = true) {
		player?.pause()
		isPlaying = false
		timer?.fireDate = Date.distantFuture
		
		#if canImport(GoogleCast)
		if UZCastingManager.shared.hasConnectedSession && alsoPauseCasting {
			UZCastingManager.shared.pause()
		}
		#endif
	}
	
	var retryTimer: Timer?
	open func retryPlaying(after interval: TimeInterval = 0) {
		if retryTimer != nil {
			retryTimer!.invalidate()
			retryTimer = nil
		}
		
		if interval > 0 {
			retryTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(retry), userInfo: nil, repeats: false)
		} else {
			retry()
		}
	}
	
	@objc func retry() {
		DLog("Retrying...")
		if #available(iOS 10.0, *) {
			player?.playImmediately(atRate: UZSpeedRate.normal.rawValue)
		} else {
            player?.rate = UZSpeedRate.normal.rawValue
			player?.play()
		}
		guard let playerItem = playerItem else { return }
		if playerItem.isPlaybackLikelyToKeepUp {
			playerLayer?.removeFromSuperlayer()
			player?.removeObserver(self, forKeyPath: "rate")
			player?.replaceCurrentItem(with: nil)
			player = nil
			
			if configPlayerAndCheckForPlayable() {
				delegate?.player(playerRequiresSeekingToLive: self)
			}
		} else {
			retryPlaying(after: 2.0)
		}
	}
    
    open func changeSpeedRate(_ speedRate: UZSpeedRate){
        player?.rate = speedRate.rawValue        
    }
    
    open func currentSpeedRate() -> UZSpeedRate {
        let rate =  player?.rate ?? 1.0
        return UZSpeedRate(rawValue: rate) ?? UZSpeedRate.normal
    }
	
	override open func layoutSubviews() {
		CATransaction.begin()
		CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
		
		super.layoutSubviews()
		
		switch aspectRatio {
            case .default:
                playerLayer?.videoGravity = .resizeAspect
                playerLayer?.frame  = bounds
                break
			case .aspectFill:
				playerLayer?.videoGravity = .resizeAspectFill
				playerLayer?.frame  = bounds
				break
            case .sixteen2Nine:
                let height = bounds.width/(16/9)
                playerLayer?.videoGravity = .resize
                playerLayer?.frame = CGRect(x: 0, y: (bounds.height - height)/2, width: bounds.width, height: height)
                break
            case .sixteen2Ten:
                let height = bounds.width/(16/10)
                playerLayer?.videoGravity = .resize
                playerLayer?.frame = CGRect(x: 0, y: (bounds.height - height)/2, width: bounds.width, height: height)
                break
            case .four2Three:
                playerLayer?.videoGravity = .resize
                let width = bounds.height * 4 / 3
                playerLayer?.frame = CGRect(x: (bounds.width - width)/2, y: 0, width: width, height: bounds.height)
                break
		}
		
		CATransaction.commit()
	}
	
	open func seek(to seconds: TimeInterval, completion: (() -> Void)?) {
		if seconds.isNaN { return }
        
		if player?.currentItem?.status == .readyToPlay {
			#if swift(>=4.2)
			let draggedTime = CMTimeMake(value: Int64(seconds), timescale: 1)
			let zeroTime = CMTime.zero
			#else
			let draggedTime = CMTimeMake(Int64(seconds), 1)
			let zeroTime = kCMTimeZero
			#endif
			
			player?.seek(to: draggedTime, toleranceBefore: zeroTime, toleranceAfter: zeroTime, completionHandler: { [weak self] (_) in
				self?.setupTimer()
				completion?()
			})
		} else {
			shouldSeekTo = seconds
		}
	}
	
	fileprivate func onPlayerItemChange() {
		guard lastPlayerItem != playerItem else { return }
        
		let notificationCenter = NotificationCenter.default
    
		if let item = lastPlayerItem {
      
			notificationCenter.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
			notificationCenter.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: item)
			notificationCenter.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: item)
			
			item.removeObserver(self, forKeyPath: "status")
			item.removeObserver(self, forKeyPath: "loadedTimeRanges")
			item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
			item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
		}
        
		lastPlayerItem = playerItem
		if let item = playerItem {
			notificationCenter.addObserver(self, selector: #selector(moviePlayerDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
			notificationCenter.addObserver(self, selector: #selector(moviePlayerDidFailToPlayToEndTime), name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
			notificationCenter.addObserver(self, selector: #selector(moviePlayerDidStall), name: .AVPlayerItemPlaybackStalled, object: playerItem)
			
			item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
			item.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
			item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
			item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
			if #available(iOS 10.0, *) {
				item.preferredForwardBufferDuration = preferredForwardBufferDuration
			}
		}
	}
	
	fileprivate func configPlayerItem() -> AVPlayerItem? {
        let assetKeys = [
            "playable",
            "hasProtectedContent"
        ]
		guard let videoAsset = urlAsset, let subtitleURL = subtitleURL else { // Embed external subtitle link to player item, This does not work
			return urlAsset != nil ? AVPlayerItem(asset: urlAsset!, automaticallyLoadedAssetKeys: assetKeys) : nil
		}
		
		#if swift(>=4.2)
		let zeroTime = CMTime.zero
		let timeRange = CMTimeRangeMake(start: zeroTime, duration: videoAsset.duration)
		#else
		let zeroTime = kCMTimeZero
		let timeRange = CMTimeRangeMake(zeroTime, videoAsset.duration)
		#endif
		
		let mixComposition = AVMutableComposition()
		let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
		try? videoTrack?.insertTimeRange(timeRange, of: videoAsset.tracks(withMediaType: .video).first!, at: zeroTime)
		
		let subtitleAsset = AVURLAsset(url: subtitleURL)
		let subtitleTrack = mixComposition.addMutableTrack(withMediaType: .text, preferredTrackID: kCMPersistentTrackID_Invalid)
		try? subtitleTrack?.insertTimeRange(timeRange, of: subtitleAsset.tracks(withMediaType: .text).first!, at: zeroTime)
		
		return AVPlayerItem(asset: mixComposition, automaticallyLoadedAssetKeys: assetKeys)
	}
	
	@discardableResult
	fileprivate func configPlayerAndCheckForPlayable() -> Bool {
		player?.removeObserver(self, forKeyPath: "rate")
		playerLayer?.removeFromSuperlayer()
		
		playerItem = configPlayerItem()
		player = AVPlayer(playerItem: playerItem!)
		player!.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
		
		playerLayer = AVPlayerLayer(player: player)
		playerLayer!.videoGravity = videoGravity
		
//		#if ALLOW_MUX
//		if UizaSDK.appId == "a9383d04d7d0420bae10dbf96bb27d9b" {
//			let key = "ei4d2skl1bkrh6u2it9n3idjg"
//			let playerData = MUXSDKCustomerPlayerData(environmentKey: key)!
////			playerData.viewerUserId = "1234"
//			playerData.experimentName = "uiza_player_test"
//			playerData.playerName = "UizaPlayer"
//			playerData.playerVersion = SDK_VERSION
//
//			let videoData = MUXSDKCustomerVideoData()
//			if let videoItem = currentVideo {
//				videoData.videoId = videoItem.id
//				videoData.videoTitle = videoItem.name
//				videoData.videoDuration = NSNumber(value: videoItem.duration * 1000)
//				videoData.videoIsLive = NSNumber(value: videoItem.isLive)
////				DLog("\(videoData) - \(playerData)")
//			}
//
//			MUXSDKStats.monitorAVPlayerLayer(playerLayer!, withPlayerName: "UizaPlayer", playerData: playerData, videoData: videoData)
//		}
//		#endif
		
		layer.addSublayer(playerLayer!)
		
		setNeedsLayout()
		layoutIfNeeded()
		
		return checkForPlayable()
	}
	
	@discardableResult
	fileprivate func checkForPlayable() -> Bool {
		guard let playerItem = playerItem else { return false }
		
		if playerItem.asset.isPlayable == false {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.delegate?.player(player: self, playerStateDidChange: .error)
			}
		}
		
		return playerItem.asset.isPlayable
	}
	
	fileprivate func updateStatus(includeLoading: Bool = false) {
		guard let player = player else { return }
		
		if let playerItem = playerItem {
			if includeLoading {
				if playerItem.isPlaybackLikelyToKeepUp || playerItem.isPlaybackBufferFull {
					state = .bufferFinished
				} else {
					state = .buffering
				}
			}
		}
		
		if player.rate == 0.0 {
			if player.error != nil {
				state = .error
				return
			}
			
			if let currentItem = player.currentItem {
				if player.currentTime() >= currentItem.duration {
					moviePlayerDidEnd()
					return
				}
//				if currentItem.isPlaybackLikelyToKeepUp || currentItem.isPlaybackBufferFull {
//
//				}
			}
		}
	}
	
	@objc open func moviePlayerDidEnd() {
		guard state != .playedToTheEnd else { return }
		
		if let playerItem = playerItem {
			delegate?.player(player: self, playTimeDidChange: CMTimeGetSeconds(playerItem.duration), totalTime: CMTimeGetSeconds(playerItem.duration))
		}
		
		state = .playedToTheEnd
		isPlaying = false
		timer?.invalidate()
		getLatencytimer?.invalidate()
	}
	
	@objc open func moviePlayerDidFailToPlayToEndTime(_ notification: Notification) {
		let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
		DLog("Player failed with error: \(String(describing: error))")
		delegate?.player(player: self, playerDidFailToPlayToEndTime: error)
	}
	
	@objc open func moviePlayerDidStall() {
		DLog("Player stalled")
		retryPlaying(after: 2.0)
		delegate?.player(playerDidStall: self)
	}
	
	private func updateVideoQuality() {
		if let item = player?.currentItem {
			UZVisualizeSavedInformation.shared.quality = item.presentationSize.height
		}
	}
	
	private func setupGetLatencyTimer() {
		getLatencytimer?.invalidate()
		getLatencytimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(getLatencyAction), userInfo: nil, repeats: true)
	}
	
	@objc private func getLatencyAction() {
		UZVisualizeSavedInformation.shared.isUpdateLivestreamLatency = true
	}
    
    // swiftlint:disable block_based_kvo
	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		guard let item = object as? AVPlayerItem, let keyPath = keyPath else { return }
		guard item == playerItem else { return }
		
		switch keyPath {
        case "status":
			updateVideoQuality()
			if player?.status == .readyToPlay {
				if let video = currentVideo, video.isLive {
					UZVisualizeSavedInformation.shared.isUpdateLivestreamLatency = true
					setupGetLatencyTimer()
				} else {
					getLatencytimer?.invalidate()
				}
				state = .buffering
				
				if shouldSeekTo != 0 {
					seek(to: shouldSeekTo, completion: {
						self.shouldSeekTo = 0
						self.isReadyToPlay = true
						self.state = .readyToPlay
					})
				} else {
					isReadyToPlay = true
					state = .readyToPlay
				}
			} else if player?.status == AVPlayer.Status.failed {
				state = .error
			}
			
		case "loadedTimeRanges":
			if let timeInterVarl = availableDuration() {
				let duration = item.duration
				var totalDuration = CMTimeGetSeconds(duration)
				
				if totalDuration.isNaN {
					guard let seekableRange = item.seekableTimeRanges.last?.timeRangeValue else { return }
					
					let seekableStart = CMTimeGetSeconds(seekableRange.start)
					let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
					totalDuration = seekableStart + seekableDuration
				}
				
				delegate?.player(player: self, loadedTimeDidChange: timeInterVarl, totalDuration: totalDuration)
			}
			
		case "playbackBufferEmpty":
			if playerItem!.isPlaybackBufferEmpty {
				state = .buffering
				bufferingSomeSecond()
			}
			
		case "playbackLikelyToKeepUp":
			if item.isPlaybackBufferEmpty {
				if state != .bufferFinished && isReadyToPlay {
					state = .bufferFinished
				}
			}
			
		case "rate":
			updateStatus()
		default:
			break
		}
	}
	
	// MARK: -
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}

extension UZPlayerLayerView {
    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
        timer?.fireDate = Date()
    }
    
    @objc fileprivate func playerTimerAction() {
        if let playerItem = playerItem {
            #if canImport(GoogleCast)
            let currentTime = UZCastingManager.shared.hasConnectedSession ? UZCastingManager.shared.currentPosition :
																			CMTimeGetSeconds(playerItem.currentTime()) // CMTimeGetSeconds(player!.currentTime())
            #else
            let currentTime = CMTimeGetSeconds(playerItem.currentTime()) // CMTimeGetSeconds(player!.currentTime())
            #endif
            
            var totalDuration: TimeInterval
            if playerItem.duration.timescale != 0 {
                totalDuration = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
            } else {
                guard let seekableRange = playerItem.seekableTimeRanges.last?.timeRangeValue else { return }
                
                let seekableStart = CMTimeGetSeconds(seekableRange.start)
                let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
                totalDuration = seekableStart + seekableDuration
            }
            
            delegate?.player(player: self, playTimeDidChange: currentTime, totalTime: totalDuration)
            updateStatus(includeLoading: true)
        }
    }
    
    public func availableDuration() -> TimeInterval? {
        if let loadedTimeRanges = player?.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first {
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSecound = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSecound
            return result
        }
        
        if let seekableRange = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue {
            let seekableStart = CMTimeGetSeconds(seekableRange.start)
            let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
            return seekableStart + seekableDuration
        }
        
        return nil
    }
    
    fileprivate func bufferingSomeSecond() {
        state = .buffering
        guard !isBuffering else { return }
        
        isBuffering = true
        
        player?.pause()
        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * 1.0 )) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            self.isBuffering = false
            
            if let item = self.playerItem {
                if !item.isPlaybackLikelyToKeepUp {
                    self.bufferingSomeSecond()
                } else {
                    self.state = .bufferFinished
                }
            }
        }
    }
    
    open func resetPlayer() {
        playerItem = nil
        
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        
        if getLatencytimer != nil {
            getLatencytimer!.invalidate()
            getLatencytimer = nil
        }
        
        if retryTimer != nil {
            retryTimer!.invalidate()
            retryTimer = nil
        }
        
        player?.removeObserver(self, forKeyPath: "rate")
        pause()
        playerLayer?.removeFromSuperlayer()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
    
    open func prepareToDeinit() {
        resetPlayer()
        
        #if canImport(GoogleCast)
        if UZCastingManager.shared.hasConnectedSession {
            UZCastingManager.shared.disconnect()
        }
        #endif
    }
    
    open func onTimeSliderBegan() {
        player?.pause()
        
        if player?.currentItem?.status == .readyToPlay {
            timer?.fireDate = .distantFuture
        }
    }
}
