//
//  UZPlayer+++.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 7/31/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation
import CoreGraphics
import NKModalViewManager
import FrameLayoutKit

#if canImport(NHNetworkTime)
import NHNetworkTime
#endif

#if canImport(GoogleInteractiveMediaAds)
import GoogleInteractiveMediaAds
#endif

#if canImport(GoogleCast)
import GoogleCast
#endif

// MARK: - Pip

extension UZPlayer {
    func setupPictureInPicture() {
        if #available(iOS 9.0, *) {
            pictureInPictureController?.removeObserver(self, forKeyPath: pipKeyPath, context: &playerViewControllerKVOContext)
            pictureInPictureController?.delegate = nil
            pictureInPictureController = nil
            
            if let playerLayer = playerLayer?.playerLayer {
                pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
                pictureInPictureController?.delegate = self
                pictureInPictureController?.addObserver(self, forKeyPath: pipKeyPath,
                                                        options: [.initial, .new], context: &playerViewControllerKVOContext)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    open func togglePiP() {
        if #available(iOS 9.0, *) {
            if pictureInPictureController == nil {
                setupPictureInPicture()
            }
            
            if pictureInPictureController?.isPictureInPictureActive ?? false {
                pictureInPictureController?.stopPictureInPicture()
            } else {
                pictureInPictureController?.startPictureInPicture()
            }
        } else {
            
        }
    }
}

// MARK: - Events
extension UZPlayer {

    @objc func onOrientationChanged() {
        updateUI(isFullScreen)
    }
    
    @objc func onApplicationInactive(notification: Notification) {
        if #available(iOS 9.0, *) {
            if AVAudioSession.sharedInstance().isAirPlaying || (pictureInPictureController?.isPictureInPictureActive ?? false) {
                // user close app or turn off the phone, don't pause video while casting
            } else if autoPauseWhenInactive {
                playerLayer?.pause()
            }
        } else {
            if AVAudioSession.sharedInstance().isAirPlaying {
                // user close app or turn off the phone, don't pause video while casting
            } else if autoPauseWhenInactive {
                playerLayer?.pause()
            }
        }
    }
    
    @objc func onApplicationActive(notification: Notification) {
        guard let currentVideo = currentVideo else {
            return
        }
        
        var isCasting = false
        #if canImport(GoogleCast)
        isCasting = UZCastingManager.shared.hasConnectedSession
        #endif
        
        if !isCasting {
            isCasting = AVAudioSession.sharedInstance().isAirPlaying
        }
        
        if currentVideo.isLive && !isCasting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.seekToLive()
            }
        } else if autoPauseWhenInactive && !isPauseByUser {
            playerLayer?.play()
        }
    }
    
    @objc func onAudioRouteChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateCastingUI()
            self.controlView.setNeedsLayout()
        }
    }
    
    /*
    @objc fileprivate func fullScreenButtonPressed() {
        controlView.updateUI(!isFullScreen)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            if isFullScreen {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
                UIApplication.shared.statusBarOrientation = .portrait
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
                UIApplication.shared.statusBarOrientation = .landscapeRight
            }
        }
    }
    */
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        if (notification.object as? AVPlayerItem) == avPlayer?.currentItem {
            #if canImport(GoogleInteractiveMediaAds)
            adsLoader?.contentComplete()
            #endif
        }
    }

    open func setupAudioCategory() {
        if #available(iOS 10.0, *) {
            #if swift(>=4.2)
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
                                                             mode: AVAudioSession.Mode.moviePlayback, options: [.allowAirPlay])
            #else
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback,
                                                             mode: AVAudioSessionModeMoviePlayback, options: [.allowAirPlay])
            #endif
        } else {
//            try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        }
    }
}

extension UZPlayer {
	
	func showMessage(_ message: String) {
		controlView.showMessage(message)
	}
	
	func hideMessage() {
		controlView.hideMessage()
	}
	
	func updateUI(_ isFullScreen: Bool) {
		controlView.updateUI(isFullScreen)
	}
	
	public func getCurrentLatency() -> TimeInterval {
		guard let currentVideo = currentVideo, currentVideo.isLive else { return 0 }
		guard let currentItem = avPlayer?.currentItem else { return 0 }
		guard let seekableRange = currentItem.seekableTimeRanges.last as? CMTimeRange else { return 0 }
		
		let livePosition = CMTimeGetSeconds(seekableRange.start) + CMTimeGetSeconds(seekableRange.duration)
		let currentPosition = CMTimeGetSeconds(currentItem.currentTime())
		return livePosition - currentPosition
	}
	
	func updateVisualizeInformation(visible: Bool) {
		visualizeInformationView?.isHidden = !visible
		visualizeInformationView?.closeButton.isHidden = !visible
	}
	
	func tryNextDefinition() {
		if currentDefinition >= resource.definitions.count - 1 {
			return
		}
		
		currentDefinition += 1
		switchVideoDefinition(resource.definitions[currentDefinition])
	}
	
	open func nextVideo() {
		currentVideoIndex += 1
	}
	
	open func previousVideo() {
		currentVideoIndex -= 1
	}
}

// MARK: - Live Video

extension UZPlayer {

    @objc open func loadLiveViews () {
        if liveViewTimer != nil {
            liveViewTimer!.invalidate()
            liveViewTimer = nil
        }
		
		if let currentVideo = currentVideo, currentVideo.isLive {
			UZLiveServices().loadViews(video: currentVideo) { [weak self] (view, _) in
				guard let `self` = self else { return }
				
				let changed = view != self.controlView.liveBadgeView.views
				if changed {
					self.controlView.theme?.updateLiveViewCount(view)
					self.controlView.setNeedsLayout()
				}
				
				self.liveViewTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.loadLiveViews), userInfo: nil, repeats: false)
			}
		}
    }

    open func sendWatchingLiveEvent(every interval: TimeInterval = 5) {
		UZLogger.shared.log(event: "watching")
		
		guard interval > 0 else { return }
		
		if sendWatchingLiveEventTimer != nil {
			sendWatchingLiveEventTimer!.invalidate()
			sendWatchingLiveEventTimer = nil
		}
		
		sendWatchingLiveEventTimer = Timer.scheduledTimer(timeInterval: interval, target: self,
														  selector: #selector(onsendWatchingLiveEventTimer), userInfo: nil, repeats: true)
    }
	
    @objc func onsendWatchingLiveEventTimer() {
        UZLogger.shared.log(event: "watching")
    }
    
    open func showLiveEndedMessage() {
        showMessage(liveEndedMessage)
    }

    /**
     Seek to current time of live video
     */
    open func seekToLive() {
        guard let currentVideo = currentVideo, currentVideo.isLive else { return }
        guard let currentItem = avPlayer?.currentItem else { return }
        guard let seekableRange = currentItem.seekableTimeRanges.last as? CMTimeRange else { return }
        
        let livePosition = CMTimeGetSeconds(seekableRange.start) + CMTimeGetSeconds(seekableRange.duration)
        seek(to: livePosition, completion: { [weak self] in
            self?.playerLayer?.play()
        })
    }
}

// MARK: - Subtitles

extension UZPlayer {
	
    func addSubtitleLabel() {
		if subtitleLabel == nil {
			subtitleLabel = UILabel()
		}
        subtitleLabel!.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel!.backgroundColor = UIColor.black
        subtitleLabel!.numberOfLines = 0
        subtitleLabel!.lineBreakMode = .byWordWrapping
        insertSubview(subtitleLabel!, belowSubview: controlView)
        
        let horizontalContraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(20)-[l]-(20)-|",
                                                                  options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                  metrics: nil, views: ["l": subtitleLabel!])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[l]-(30)-|",
                                                                 options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                 metrics: nil, views: ["l": subtitleLabel!])
        addConstraints(horizontalContraints)
        addConstraints(verticalConstraints)
    }
    
    func removeSubtitleLabel() {
        subtitleLabel?.removeFromSuperview()
        subtitleLabel = nil
    }

    func addPeriodicTime() {
        guard let savedSubtitles = savedSubtitles else { return }
        
        #if swift(>=4.2)
        let interval = CMTimeMake(value: 1, timescale: 60)
        #else
        let interval = CMTimeMake(1, 60)
        #endif
        
        if let timeObserver = timeObserver {
            avPlayer?.removeTimeObserver(timeObserver)
        }
        timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] (time) -> Void in
			guard let `self` = self else { return }
			
			guard let text = savedSubtitles.search(for: TimeInterval(CMTimeGetSeconds(time)))?.text else {
				self.subtitleLabel?.text = ""
				return
			}
			
			do {
				let paragraphStyle = NSMutableParagraphStyle()
				paragraphStyle.alignment = .center
				paragraphStyle.lineBreakMode = .byWordWrapping
				
				let textAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .paragraphStyle: paragraphStyle]
				let attrStr = try NSMutableAttributedString(
					data: text.data(using: String.Encoding.unicode, allowLossyConversion: true)!,
					options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
					documentAttributes: nil)
				attrStr.addAttributes(textAttributes, range: NSRange(location: 0, length: attrStr.length))
				attrStr.enumerateAttribute(
					NSAttributedString.Key.font,
					in: NSRange(location: 0, length: attrStr.length),
					options: .longestEffectiveRangeNotRequired) { value, range, _ in
						let f1 = value as? UIFont
						let f2 = UIFont.systemFont(ofSize: 12)
						if let f3 = self.applyTraitsFromFont(from: f1, to: f2) {
							attrStr.addAttribute(
								NSAttributedString.Key.font, value: f3, range: range)
						}
				}
				self.subtitleLabel?.attributedText = attrStr
			} catch let error {
				DLog(error.localizedDescription)
			}
        })
    }

    private func applyTraitsFromFont(from f1: UIFont?, to f2: UIFont) -> UIFont? {
        guard let f1 = f1 else { return nil }
		
        let t = f1.fontDescriptor.symbolicTraits
        if let fontDescription = f2.fontDescriptor.withSymbolicTraits(t) {
            return UIFont.init(descriptor: fontDescription, size: 0)
        }
        return nil
    }
}

// MARK: - Select media

extension UZPlayer {
    /**
     Select subtitle track

     - parameter index: index of subtitle track, `nil` for turning off, `-1` for default track
     */
    open func selectSubtitle(index: Int?) {
        selectMediaOption(option: .legible, index: index)
    }

    /**
     Select audio track

     - parameter index: index of audio track, `nil` for turning off, `-1` for default audio track
     */
    open func selectAudio(index: Int?) {
        selectMediaOption(option: .audible, index: index)
    }

    /**
     Select media selection option

     - parameter index: index of media selection, `nil` for turning off, `-1` for default option
     */
    open func selectMediaOption(option: AVMediaCharacteristic, index: Int?) {
		guard let currentItem = avPlayer?.currentItem else { return }
		let asset = currentItem.asset
		if let group = asset.mediaSelectionGroup(forMediaCharacteristic: option) {
			currentItem.select(nil, in: group)
			
			let options = group.options
			if let index = index {
				if index > -1 && index < options.count {
					currentItem.select(options[index], in: group)
				} else if index == -1 {
					let defaultOption = group.defaultOption
					currentItem.select(defaultOption, in: group)
				}
			}
		}
    }

    func selectExtenalSubtitle(subtitle: UZVideoSubtitle) {
        if selectedSubtitle?.id != subtitle.id {
            selectedSubtitle = subtitle
            guard let url = URL(string: subtitle.url) else { return }
            savedSubtitles = UZSubtitles(url: url)
        } else {
            selectedSubtitle = nil
            savedSubtitles = nil
        }
    }
}

// MARK: - Log Event

extension UZPlayer {
    func logPlayEvent(currentTime: TimeInterval, totalTime: TimeInterval) {
        if round(currentTime) == 5 {
            if playThroughEventLog[5] == false || playThroughEventLog[5] == nil {
                playThroughEventLog[5] = true
                
                UZLogger.shared.log(event: "view", params: ["play_through": "0"])
            }
        } else if totalTime > 0 {
            let playthrough: Float = roundf(Float(currentTime) / Float(totalTime) * 100)
            
            if logPercent.contains(playthrough) {
                if playThroughEventLog[playthrough] == false || playThroughEventLog[playthrough] == nil {
                    playThroughEventLog[playthrough] = true
                    
                    UZLogger.shared.log(event: "play_through", params: ["play_through": playthrough])
                }
            }
        }
    }
}

// MARK: - Listener

extension UZPlayer {
    @objc func volumeDidChange(notification: NSNotification) {
        if let volume = notification.userInfo?["AVSystemController_AudioVolumeNotificationParameter"] as? Float {
            UZVisualizeSavedInformation.shared.volume = volume
        }
    }

    @objc func completeSyncTime() {
        if let video = currentVideo, video.isLive {
            UZVisualizeSavedInformation.shared.livestreamCurrentDate = playerLayer?.player?.currentItem?.currentDate()
        }
    }
    
    // MARK: - KVO
    // swiftlint:disable block_based_kvo
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        //        guard context == &playerViewControllerKVOContext else {
        //            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        //            return
        //        }
        
        if keyPath == pipKeyPath {
            let newValue = change?[NSKeyValueChangeKey.newKey] as? NSNumber
            let isPictureInPicturePossible: Bool = newValue?.boolValue ?? false
            controlView.pipButton.isEnabled = isPictureInPicturePossible
        }
        
    }
}

extension UZPlayer {
    /**
     Set video resource
     
     - parameter resource:        media resource
     - parameter definitionIndex: starting definition index, default start with the first definition
     */
    open func setResource(resource: UZPlayerResource, definitionIndex: Int = 0) {
        isURLSet = false
        
        self.resource = resource
        
        seekCount = 0
        bufferingCount = 0
        playThroughEventLog = [:]
        currentDefinition = definitionIndex
        
        controlView.prepareUI(for: resource, video: currentVideo, playlist: playlist)
        controlView.relateButton.isHidden = true // currentVideo == nil || (currentVideo?.isLive ?? false)
        controlView.playlistButton.isHidden = (playlist?.isEmpty ?? true)
        
        #if canImport(GoogleCast)
        if UZCastingManager.shared.hasConnectedSession {
            if let currentVideo = currentVideo, let linkPlay = currentLinkPlay {
                let item = UZCastItem(id: currentVideo.id, title: currentVideo.name, customData: nil,
                                      streamType: currentVideo.isLive ? .live : .buffered, contentType: "application/dash+xml",
                                      url: linkPlay.url, thumbnailUrl: currentVideo.thumbnailURL, duration: currentVideo.duration,
                                      playPosition: self.currentPosition, mediaTracks: nil)
                UZCastingManager.shared.castItem(item: item)
            }
        }
        #endif
        
        if shouldAutoPlay {
            isURLSet = true
			let count = resource.definitions.count
			currentLinkPlay = definitionIndex > -1 && definitionIndex < count ? resource.definitions[definitionIndex] : resource.definitions.first
			guard currentLinkPlay != nil else { return }
            playerLayer?.playAsset(asset: currentLinkPlay!.avURLAsset)
            
            setupPictureInPicture()
        } else {
            controlView.showCover(url: resource.cover)
            controlView.hideLoader()
        }
    }
}

// MARK: - Setup

extension UZPlayer {
    func setupUI() {
        backgroundColor = UIColor.black
        
        controlView = customControlView ?? UZPlayerControlView()
        controlView.updateUI(isFullScreen)
        controlView.delegate = self
        addSubview(controlView)
        
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged), name: AVAudioSession.routeChangeNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged), name: .UIApplicationDidChangeStatusBarOrientation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAudioRouteChanged), name: .AVAudioSessionRouteChange, object: nil)
        #endif
        
        NotificationCenter.default.addObserver(self, selector: #selector(showAirPlayDevicesSelection), name: UZPlayer.ShowAirPlayDeviceListNotification, object: nil)
        #if canImport(GoogleCast)
        NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStart), name: .UZCastSessionDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCastSessionDidStop), name: .UZCastSessionDidStop, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidStart), name: .UZCastClientDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCastClientDidUpdate), name: .UZCastClientDidUpdate, object: nil)
        #endif
    }
    
    func preparePlayer() {
        playerLayer = UZPlayerLayerView()
        playerLayer!.preferredForwardBufferDuration = preferredForwardBufferDuration
        playerLayer!.videoGravity = videoGravity
        playerLayer!.delegate = self
        
        insertSubview(playerLayer!, at: 0)
        layoutIfNeeded()
        
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationInactive), name: UIApplication.didEnterBackgroundNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationInactive), name: .UIApplicationDidEnterBackground, object: nil)
        #endif
        
        #if canImport(NHNetworkTime)
        NotificationCenter.default.addObserver(self, selector: #selector(completeSyncTime), name: NSNotification.Name(rawValue: kNHNetworkTimeSyncCompleteNotification), object: nil)
        #endif
        setupAudioCategory()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        visualizeInformationView?.frame = bounds
        playerLayer?.frame = bounds
        controlView.frame = bounds
        controlView.setNeedsLayout()
        controlView.layoutIfNeeded()
    }
}
