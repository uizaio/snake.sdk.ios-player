//
//  UZPlayer+.swift
//  UizaSDK
//
//  Created by phan.huynh.thien.an on 7/30/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Foundation
import CoreGraphics
import NKModalViewManager
#if canImport(GoogleCast)
import GoogleCast
#endif

#if canImport(GoogleInteractiveMediaAds)
import GoogleInteractiveMediaAds
#endif

// MARK: - Ads
extension UZPlayer {
    
    internal func setUpAdsLoader() {
        #if canImport(GoogleInteractiveMediaAds)
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: avPlayer)
        
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader!.delegate = self
        #endif
    }
    
    internal func requestAds() {
       
    }
    
	internal func requestAds(url: URL?) {
        #if canImport(GoogleInteractiveMediaAds)
		guard let adsLink = url else { return }
		
		let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
		let request = IMAAdsRequest(adTagUrl: adsLink, adDisplayContainer: adDisplayContainer,
									contentPlayhead: contentPlayhead, userContext: nil)
		
		adsLoader?.requestAds(with: request)
        #endif
        
        //        if let adsLink = cuePoints.first?.link?.absoluteString {
        ////            let testAdTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
        //            let adDisplayContainer = IMAAdDisplayContainer(adContainer: self, companionSlots: nil)
        //            let request = IMAAdsRequest(adTagUrl: adsLink, adDisplayContainer: adDisplayContainer, contentPlayhead: contentPlayhead, userContext: nil)
        //
        //            adsLoader?.requestAds(with: request)
        //        }
    }
}

// MARK: - IMAAdsLoaderDelegate

#if canImport(GoogleInteractiveMediaAds)
extension UZPlayer: IMAAdsLoaderDelegate {
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = UIViewController.topPresented()
        
        adsManager?.initialize(with: adsRenderingSettings)
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        //        print("Error loading ads: \(adErrorData.adError.message)")
        avPlayer?.play()
    }
}

// MARK: - IMAAdsManagerDelegate

extension UZPlayer: IMAAdsManagerDelegate {
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
//        DLog("- \(event.type.rawValue)")
        
        if event.type == IMAAdEventType.LOADED {
            adsManager.start()
        } else if event.type == IMAAdEventType.STARTED {
            avPlayer?.pause()
        }
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        DLog("Ads error: \(String(describing: error.message))")
        //        print("AdsManager error: \(error.message)")
        avPlayer?.play()
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        avPlayer?.pause()
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        avPlayer?.play()
    }
    
}
#endif

// MARK: - Google cast

extension UZPlayer {
	
    @objc open func showAirPlayDevicesSelection() {
        let volumeView = UZAirPlayButton()
        volumeView.alpha = 0
        volumeView.isUserInteractionEnabled = false
        addSubview(volumeView)
        
        for subview in volumeView.subviews where subview is UIButton {
            let button = subview as? UIButton
            button?.sendActions(for: .touchUpInside)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            volumeView.removeFromSuperview()
        }
    }
    
    open func showCastingDeviceList() {
        #if canImport(GoogleCast)
        let viewController = UZDeviceListTableViewController()
        NKModalViewManager.sharedInstance().presentModalViewController(viewController).tapOutsideToDismiss = true
        #else
        showAirPlayDevicesSelection()
        #endif
    }
    
    func showCastDisconnectConfirmation(at view: UIView) {
        #if canImport(GoogleCast)
        if UZCastingManager.shared.hasConnectedSession {
            if let window = UIApplication.shared.keyWindow,
                let viewController = window.rootViewController {
                let activeViewController: UIViewController = viewController.presentedViewController ?? viewController
                let deviceName = UZCastingManager.shared.currentCastSession?.device.modelName ?? "(?)"
                let alert = UIAlertController(title: "Disconnect", message: "Disconnect from \(deviceName)?", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: { (_) in
                    UZCastingManager.shared.disconnect()
                    alert.dismiss(animated: true, completion: nil)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alert.modalPresentationStyle = .popover
                    alert.popoverPresentationController?.sourceView = view
                    alert.popoverPresentationController?.sourceRect = view.bounds
                }
                
                activeViewController.present(alert, animated: true, completion: nil)
            }
        } else if AVAudioSession.sharedInstance().isAirPlaying {
            showAirPlayDevicesSelection()
        }
        #else
        if AVAudioSession.sharedInstance().isAirPlaying {
            showAirPlayDevicesSelection()
        }
        #endif
    }
    
    #if canImport(GoogleCast)
    @objc func onCastSessionDidStart(_ notification: Notification) {
        if let currentVideo = currentVideo, let linkPlay = currentLinkPlay {
            let item = UZCastItem(id: currentVideo.id, title: currentVideo.name, customData: nil,
                                  streamType: currentVideo.isLive ? .live : .buffered, contentType: "application/dash+xml",
                                  url: linkPlay.url, thumbnailUrl: currentVideo.thumbnailURL, duration: currentVideo.duration,
                                  playPosition: currentPosition, mediaTracks: nil)
            UZCastingManager.shared.castItem(item: item)
        }
        
        playerLayer?.pause(alsoPauseCasting: false)
        controlView.showLoader()
        updateCastingUI()
    }
    
    @objc func onCastClientDidStart(_ notification: Notification) {
        controlView.hideLoader()
        playerLayer?.setupTimer()
        playerLayer?.isPlaying = true
    }
    
    @objc func onCastClientDidUpdate(_ notification: Notification) {
        if let mediaStatus = notification.object as? GCKMediaStatus,
            let currentQueueItem = mediaStatus.currentQueueItem,
            let playlist = playlist {
            let count = mediaStatus.queueItemCount
            var index = 0
            var found = false
            
            while index < count {
                if currentQueueItem == mediaStatus.queueItem(at: UInt(index)) {
                    found = true
                    break
                }
                
                index += 1
            }
            
            if found && index >= 0 && index < playlist.count {
                currentVideo = playlist[index]
            }
        }
    }
    
    @objc func onCastSessionDidStop(_ notification: Notification) {
        let lastPosision = UZCastingManager.shared.lastPosition
        
        playerLayer?.seek(to: lastPosision, completion: { [weak self] in
            self?.playerLayer?.play()
        })
        
        updateCastingUI()
    }
    #endif
    
    func updateCastingUI() {
        #if canImport(GoogleCast)
        if AVAudioSession.sharedInstance().isAirPlaying || UZCastingManager.shared.hasConnectedSession {
            controlView.showCastingScreen()
        } else {
            controlView.hideCastingScreen()
        }
        #else
        if AVAudioSession.sharedInstance().isAirPlaying {
            controlView.showCastingScreen()
        } else {
            controlView.hideCastingScreen()
        }
        #endif
    }
}

// MARK: - Show popup

extension UZPlayer {
    
    open func showShare(from view: UIView) {
        if let window = UIApplication.shared.keyWindow,
            let viewController = window.rootViewController,
            let itemToShare: Any = currentVideo {
            let activeViewController: UIViewController = viewController.presentedViewController ?? viewController
            let activityViewController = UIActivityViewController(activityItems: [itemToShare], applicationActivities: nil)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.modalPresentationStyle = .popover
                activityViewController.popoverPresentationController?.sourceView = view
                activityViewController.popoverPresentationController?.sourceRect = view.bounds
            }
            
            activeViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    open func showQualitySelector() {
        let viewController = UZVideoQualitySettingsViewController()
        viewController.currentDefinition = currentLinkPlay
        viewController.resource = resource
        viewController.collectionViewController.selectedBlock = { [weak self] (linkPlay, index) in
            guard let `self` = self else { return }
            
            self.currentDefinition = index
            self.switchVideoDefinition(linkPlay)
            viewController.dismiss(animated: true, completion: nil)
        }
        NKModalViewManager.sharedInstance().presentModalViewController(viewController)
    }
    
    open func showMediaOptionSelector() {
		guard let currentItem = avPlayer?.currentItem else { return }
		
		let asset = currentItem.asset
		let viewController = UZMediaOptionSelectionViewController()
		viewController.asset = asset
		viewController.selectedSubtitle = selectedSubtitle
		viewController.subtitiles = subtitles
		//            viewController.selectedSubtitleOption = nil
		viewController.collectionViewController.selectedBlock = { [weak self] (option, indexPath) in
			guard let `self` = self else { return }
			
			if indexPath.section == 0 { // audio
				self.selectAudio(index: indexPath.item)
			} else if indexPath.section == 1 { // subtitile
				if self.subtitles.isEmpty {
					self.selectSubtitle(index: indexPath.item)
				} else {
					self.selectExtenalSubtitle(subtitle: self.subtitles[indexPath.row])
				}
			}
			
			viewController.dismiss(animated: true, completion: nil)
		}
		
		NKModalViewManager.sharedInstance().presentModalViewController(viewController)
    }
    
    open func showSettings() {
        
        if let window = UIApplication.shared.windows.first,
            let viewController = window.rootViewController {
            var settingItems = [SettingItem]()
            // VOD
            if !isLive() {
                print("currentBitrate = \(currentBitrate())")
                if let videoStreams = currentVideo?.streams,
                    videoStreams.count > 0 {
                      settingItems.append(SettingItem(tag: .quality, type: .array, initValue:
                        Float(currentBitrate()), streamItems: videoStreams))
                }
                // audio
                if let audioOptions = audioOptions,
                    audioOptions.count > 0 {
                      settingItems.append(SettingItem(tag: .audio, type: .array, initValue: currentAudioOption(),  childItems: audioOptions))
                }
                // subtitles
                if let subtitleOptions = subtitleOptions,
                    subtitleOptions.count > 0 {
                      settingItems.append(SettingItem(tag: .captions, type: .array, initValue: currentSubtileOption(), childItems: subtitleOptions))
                }
                // speed rate
                settingItems.append(SettingItem(tag: .speedRate, type: .array, initValue: playerLayer?.currentSpeedRate().rawValue ?? UZSpeedRate.normal.rawValue))
            }
//            #if DEBUG
//            settingItems.append(SettingItem(tag: .stats))
//            #endif
            if isTimeshiftSupport() {
                settingItems.append(SettingItem(tag: .timeshift, type: .bool, initValue: isTimeshiftOn()))
            }
            let settingViewController = SettingViewController(settingItems: settingItems)
            settingViewController.delegate = self
            let navigationController = BottomSheetNavigationController(rootViewController: settingViewController)
            navigationController.navigationBar.isTranslucent = false
            viewController.topPresented()?.present(navigationController, animated: true)
        }
    }
}

// MARK: - UZSettingViewDelegate

extension UZPlayer: UZSettingViewDelegate {
    public func settingRow(didChanged sender: UISwitch) {
        if let type = UZSettingTag(rawValue: sender.tag) {
              switch type {
              case .timeshift:
                   let result = switchTimeshiftMode(sender.isOn)
                   if(result){
                       setTimeshiftOn(sender.isOn)
                   }
                  break
              default:
                  #if DEBUG
                  print("[UZPlayer] Unhandled Action")
                  #endif
              }
          }
    }
    
    public func settingRow(didSelected tag: UZSettingTag, value: Float) {
        switch tag {
        case .speedRate:
            let speedRate = UZSpeedRate(rawValue: value) ?? UZSpeedRate.normal
            playerLayer?.changeSpeedRate(speedRate)
            break
        case .stats:
            break
        case .quality:
            changeBitrate(bitrate: Double(value))
            break
        default:
            #if DEBUG
            print("[UZPlayer] Unhandled Action")
            #endif
        }
    }
    
    public func settingRow(didSelected tag: UZSettingTag, value: AVMediaSelectionOption?) {
        switch tag {
        case .audio:
            changeAudioSelect(option: value)
            break
        case .captions:
            changeSubtitleSelect(option: value)
            break
        default:
            #if DEBUG
            print("[UZPlayer] Unhandled Action")
            #endif
        }
    }
}

// MARK: - UZPlayerControlViewDelegate

extension UZPlayer: UZPlayerControlViewDelegate {
    
    open func controlView(controlView: UZPlayerControlView, didChooseDefinition index: Int) {
        currentDefinition = index
        switchVideoDefinition(resource.definitions[index])
    }
    
    open func controlView(controlView: UZPlayerControlView, didSelectButton button: UIButton) {
        if let action = UZButtonTag(rawValue: button.tag) {
            switch action {
            case .back:
                    backBlock?(true)
                break
            case .play:
                if button.isSelected {
                    pause()
                    isPauseByUser = true
                } else {
                    button.isSelected = true
                    
                    if isPlayToTheEnd {
                        replay()
                    } else {
                        play()
                    }
                }
                break
            case .pause:
                pause()
                isPauseByUser = true
                break
            case .replay:
                replay()
                break
            case .forward:
                seek(offset: DEFAULT_SEEK_FORWARD)
                break
            case .backward:
                seek(offset: DEFAULT_SEEK_BACKWARD)
                break
            case .next:
                nextVideo()
                break
            case .previous:
                previousVideo()
                break
            case .fullscreen:
                fullscreenBlock?(nil)
                break
            case .volume:
                if let avPlayer = avPlayer {
                    avPlayer.isMuted = !avPlayer.isMuted
                    button.isSelected = avPlayer.isMuted
                }
                break
            case .share:
                showShare(from: button)
                button.isEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    button.isEnabled = true
                }
                break
            case .pip:
                togglePiP()
                break
            case .settings:
                showSettings()
                break
            case .caption:
                showMediaOptionSelector()
                break
            case .casting:
                if button.isSelected {
                    showCastDisconnectConfirmation(at: button)
                } else {
                    showCastingDeviceList()
                }
                break
            case .logo:
                if let url = controlView.playerConfig?.logoRedirectUrl {
                    if UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
				break
			case .live:
				seekToLive()
                break
            default:
                #if DEBUG
                print("[UZPlayer] Unhandled Action")
                #endif
            }
        }
        
        buttonSelectionBlock?(button)
    }
    
    open func controlView(controlView: UZPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event) {
        #if canImport(GoogleCast)
        let castingManager = UZCastingManager.shared
        if castingManager.hasConnectedSession {
            switch event {
            case .touchDown:
                isSliderSliding = true
                
            case .touchUpInside :
                isSliderSliding = false
                let targetTime = totalDuration * Double(slider.value)
                
                if isPlayToTheEnd {
                    isPlayToTheEnd = false
                    
                    controlView.hideEndScreen()
                    seek(to: targetTime, completion: { [weak self] in
                        self?.play()
                    })
                } else {
                    seek(to: targetTime, completion: { [weak self] in
                        self?.playIfApplicable()
                    })
                }
                
            default:
                break
            }
            
            return
        }
        #endif
        
        switch event {
        case .touchDown:
            playerLayer?.onTimeSliderBegan()
            isSliderSliding = true
            
        case .touchUpInside :
            isSliderSliding = false
            
            var targetTime = totalDuration * Double(slider.value)
            if targetTime.isNaN {
                guard let currentItem = playerLayer?.playerItem,
                    let seekableRange = currentItem.seekableTimeRanges.last?.timeRangeValue else { return }
                
                let seekableStart = CMTimeGetSeconds(seekableRange.start)
                let seekableDuration = CMTimeGetSeconds(seekableRange.duration)
                let livePosition = seekableStart + seekableDuration
                targetTime = livePosition * Double(slider.value)
            }
            
            if isPlayToTheEnd {
                isPlayToTheEnd = false
                
                controlView.hideEndScreen()
                seek(to: targetTime, completion: { [weak self] in
                    self?.play()
                })
            } else {
                seek(to: targetTime, completion: { [weak self] in
                    self?.playIfApplicable()
                })
            }
            
        default:
            break
        }
    }
    
}

// MARK: - UZPlayerLayerViewDelegate

extension UZPlayer: UZPlayerLayerViewDelegate {
    
    open func player(player: UZPlayerLayerView, playerIsPlaying playing: Bool) {
        controlView.playStateDidChange(isPlaying: playing)
        delegate?.player(player: self, playerIsPlaying: playing)
        playStateDidChange?(player.isPlaying)
    }
    
    open func player(player: UZPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        controlView.loadedTimeDidChange(loadedDuration: loadedDuration, totalDuration: totalDuration)
        delegate?.player(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
        controlView.totalDuration = totalDuration
        self.totalDuration = totalDuration
    }
    
    open func player(player: UZPlayerLayerView, playerStateDidChange state: UZPlayerState) {
        controlView.playerStateDidChange(state: state)
        
        switch state {
        case .readyToPlay:
            if !isPauseByUser {
                play()
                
                updateCastingUI()
                requestAds()
            }
            
        case .buffering:
			UZLogger.shared.log(event: "rebufferstart")
            bufferingCount += 1
            
        case .bufferFinished:
			UZLogger.shared.log(event: "rebufferend")
            playIfApplicable()
            
        case .playedToTheEnd:
			UZLogger.shared.log(event: "viewended")
            isPlayToTheEnd = true
            
            if !isReplaying {
                if themeConfig?.showEndscreen ?? true {
                    controlView.showEndScreen()
                }
            }
            
            #if canImport(GoogleInteractiveMediaAds)
            adsLoader?.contentComplete()
            #endif
            nextVideo()
            
        case .error:
			UZLogger.shared.log(event: "error")
            if autoTryNextDefinitionIfError {
                tryNextDefinition()
            }
            
        default:
            break
        }
        
        delegate?.player(player: self, playerStateDidChange: state)
    }
    
    open func player(player: UZPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        currentPosition = currentTime
        totalDuration = totalTime
        
        delegate?.player(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
        
        if !isSliderSliding {
            logPlayEvent(currentTime: currentTime, totalTime: totalTime)
            controlView.totalDuration = totalDuration
			controlView.liveBadgeView.liveBadge.isEnabled = (totalTime - currentPosition) > 10
            controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
            playTimeDidChange?(currentTime, totalTime)
        }
    }
    
    open func player(player: UZPlayerLayerView, playerDidFailToPlayToEndTime error: Error?) {
        delegate?.player(player: self, playerDidFailToPlayToEndTime: error)
    }
    
    open func player(playerDidStall: UZPlayerLayerView) {
        delegate?.player(playerDidStall: self)
    }
    
    open func player(playerRequiresSeekingToLive: UZPlayerLayerView) {
        seekToLive()
    }
    
}

// MARK: - AVPictureInPictureControllerDelegate

extension UZPlayer: AVPictureInPictureControllerDelegate {
    
    @available(iOS 9.0, *)
    open func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        controlView.hideControlView()
    }
    
    @available(iOS 9.0, *)
    open func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        controlView.pipButton.isSelected = true
    }
    
    @available(iOS 9.0, *)
    open func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        if shouldShowsControlViewAfterStoppingPiP {
            controlView.showControlView()
        }
        
        controlView.pipButton.isSelected = false
    }
    
}
