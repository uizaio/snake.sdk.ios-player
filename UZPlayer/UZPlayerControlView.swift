//
//  UZPlayerControlView.swift
//  SnakePlayerSDK
//
//  Created by Nam Kennic on 10/25/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import SwiftIcons

open class UZPlayerControlView: UIView {
	open weak var delegate: UZPlayerControlViewDelegate?
	open var autoHideControlsInterval: TimeInterval = 5
	open var enableTimeshiftForLiveVideo = true
	
	open var playerConfig: UZPlayerConfig? = nil {
		didSet {
			guard let config = playerConfig else { return }
			
			logoButton.isHidden = !config.showLogo || config.logoImageUrl == nil
//			if let logoImageURL = config.logoImageUrl {
//				logoButton.sd_setImage(with: logoImageURL, for: .normal) { [weak self] (_, _, _, _) in
//					self?.setNeedsLayout()
//				}
//			}
		}
	}
	
	open var logoEdgeInsetsWhenControlsInvisible = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
	open var logoEdgeInsetsWhenControlsVisible = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
	
	open var totalDuration: TimeInterval = 0
	
	var seekedTime: TimeInterval = 0
	var delayItem: DispatchWorkItem?
	
	var resource: UZPlayerResource? {
		didSet {
			theme?.update(withResource: resource, video: currentVideo, playlist: currentPlaylist)
		}
	}
	
	var currentVideo: UZVideoItem? {
		didSet {
			theme?.update(withResource: resource, video: currentVideo, playlist: currentPlaylist)
		}
	}
	
	var currentPlaylist: [UZVideoItem]? {
		didSet {
			theme?.update(withResource: resource, video: currentVideo, playlist: currentPlaylist)
		}
	}
	
	open var tapGesture: UITapGestureRecognizer?
	open var doubleTapGesture: UITapGestureRecognizer?
	
	open var theme: UZPlayerTheme? = nil {
		willSet {
			cancelAutoFadeOutAnimation()
			showControlView()
			endscreenView.allButtons.forEach { $0.removeTarget(self, action: #selector(onButtonPressed), for: .touchUpInside) }
			theme?.allButtons().forEach { $0.removeTarget(self, action: #selector(onButtonPressed), for: .touchUpInside) }
			theme?.cleanUI()
			resetSkin()
			resetLayout()
			theme?.controlView = nil
		}
		
		didSet {
			theme?.controlView = self
			theme?.updateUI()
			theme?.update(withResource: resource, video: currentVideo, playlist: currentPlaylist)
			
			addSubview(endscreenView)
			
			theme?.allButtons().forEach { $0.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside) }
			endscreenView.allButtons.forEach { $0.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside) }
			
			timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan), for: .touchDown)
			timeSlider.addTarget(self, action: #selector(progressSliderValueChanged), for: .valueChanged)
			timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded), for: [.touchUpInside, .touchCancel, .touchUpOutside])
			
			autoFadeOutControlView(after: autoHideControlsInterval)
		}
	}
	
	var playerLastState: UZPlayerState = .notSetURL
	var messageLabel: UILabel?
	
	public let containerView = UIView()
	open lazy var titleLabel = UILabel()
	open lazy var currentTimeLabel = UILabel()
	open lazy var totalTimeLabel = UILabel()
	open lazy var remainTimeLabel = UILabel()
	open lazy var playpauseCenterButton = UZButton()
	open lazy var playpauseButton = UZButton()
	open lazy var forwardButton = UZButton()
	open lazy var backwardButton = UZButton()
	open lazy var nextButton = UZButton()
	open lazy var previousButton = UZButton()
	open lazy var volumeButton = UZButton()
	open lazy var backButton = UZButton()
	open lazy var fullscreenButton = UZButton()
	open lazy var playlistButton = UZButton()
	open lazy var relateButton = UZButton()
	open lazy var ccButton = UZButton()
	open lazy var settingsButton = UZButton()
	open lazy var helpButton = UZButton()
	open lazy var pipButton = UZButton()
	open lazy var castingButton = UZCastButton()
	open lazy var enlapseTimeLabel = UZButton()
	open lazy var logoButton = UZButton()
	open lazy var airplayButton = UZAirPlayButton()
	open lazy var coverImageView = UIImageView()
	open lazy var liveBadgeView = UZLiveBadgeView()
	open lazy var endscreenView = UZEndscreenView()
	public var loadingIndicatorView: UIActivityIndicatorView?
	public var timeSlider: UZSlider! {
		didSet {
			timeSlider.maximumValue = 1.0
			timeSlider.minimumValue = 0.0
			timeSlider.maximumTrackTintColor = UIColor.clear
		}
	}
	var castingView: UZCastingView?
	
	var liveStartDate: Date? = nil {
		didSet {
			updateLiveDate()
		}
	}
	
	fileprivate var timer: Timer?
	
	open lazy var allButtons: [UIButton] = [backButton, helpButton, ccButton, relateButton, playlistButton, settingsButton, fullscreenButton,
											playpauseCenterButton, playpauseButton, forwardButton, backwardButton, nextButton,
											previousButton, volumeButton, pipButton, castingButton, logoButton]
	open lazy var allLabels: [UILabel] = [titleLabel, currentTimeLabel, totalTimeLabel, remainTimeLabel]
	open lazy var allControlViews: [UIView] = { allButtons + allLabels + [airplayButton, timeSlider, liveBadgeView] }()
	
	// MARK: -
	
	public init() {
		super.init(frame: .zero)
		configUI()
		setupGestures()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	open func configUI() {
		titleLabel.numberOfLines = 2
		titleLabel.text = ""
		
		currentTimeLabel.numberOfLines = 1
		totalTimeLabel.numberOfLines = 1
		remainTimeLabel.numberOfLines = 1
		
		currentTimeLabel.text = "--:--"
		totalTimeLabel.text = "--:--"
		remainTimeLabel.text = "--:--"
		
		if timeSlider == nil { timeSlider = UZSlider() }
		timeSlider.maximumValue = 1.0
		timeSlider.minimumValue = 0.0
		timeSlider.value = 0.0
		timeSlider.maximumTrackTintColor = UIColor.clear
		
		enlapseTimeLabel.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
		enlapseTimeLabel.setTitleColor(.white, for: .normal)
		enlapseTimeLabel.setBackgroundColor(UIColor(white: 0.2, alpha: 0.8), for: .normal)
		enlapseTimeLabel.extendSize = CGSize(width: 10, height: 4)
		enlapseTimeLabel.cornerRadius = 4
		enlapseTimeLabel.isUserInteractionEnabled = false
		
		loadingIndicatorView?.isUserInteractionEnabled = false
		
		playpauseCenterButton.tag = UZButtonTag.play.rawValue
		playpauseButton.tag = UZButtonTag.play.rawValue
		backButton.tag = UZButtonTag.back.rawValue
		fullscreenButton.tag = UZButtonTag.fullscreen.rawValue
		settingsButton.tag = UZButtonTag.settings.rawValue
		forwardButton.tag = UZButtonTag.forward.rawValue
		backwardButton.tag = UZButtonTag.backward.rawValue
		nextButton.tag = UZButtonTag.next.rawValue
		previousButton.tag = UZButtonTag.previous.rawValue
		volumeButton.tag = UZButtonTag.volume.rawValue
		playlistButton.tag = UZButtonTag.playlist.rawValue
		relateButton.tag = UZButtonTag.relates.rawValue
		ccButton.tag = UZButtonTag.caption.rawValue
		helpButton.tag = UZButtonTag.help.rawValue
		pipButton.tag = UZButtonTag.pip.rawValue
		airplayButton.tag = UZButtonTag.airplay.rawValue
		castingButton.tag = UZButtonTag.casting.rawValue
		logoButton.tag = UZButtonTag.logo.rawValue
		liveBadgeView.liveBadge.tag = UZButtonTag.live.rawValue
        
		allButtons.forEach {
			$0.imageView?.contentMode = .scaleAspectFit
			$0.showsTouchWhenHighlighted = true
			$0.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
		}
		
		liveBadgeView.liveBadge.showsTouchWhenHighlighted = true
		liveBadgeView.liveBadge.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
		
		endscreenView.isHidden = true
		liveBadgeView.isHidden = true
		logoButton.isHidden = true
		
		addSubview(containerView)
	}
    
    open func setDefaultThemeIcon() {
        guard let imagePath = Bundle(for: Self.self).uzIconPath() else { return }
        let imageBundle = Bundle(path: imagePath)
        
        backButton.setImage(imageBundle?.getUZImage(named: "ic_close"), for: .normal)
        settingsButton.setImage(imageBundle?.getUZImage(named: "ic_settings"), for: .normal)
        fullscreenButton.setImage(imageBundle?.getUZImage(named: "ic_maximize"), for: .normal)
        fullscreenButton.setImage(imageBundle?.getUZImage(named: "ic_minimize"), for: .selected)
        forwardButton.setImage(imageBundle?.getUZImage(named: "ic_forward"), for: .normal)
        backwardButton.setImage(imageBundle?.getUZImage(named: "ic_backward"), for: .normal)
        timeSlider.setThumbImage(UIImage(icon: .fontAwesomeSolid(.circle), size: CGSize(width: 18, height: 18), textColor: .red, backgroundColor: .clear), for: .normal)
        volumeButton.setImage(UIImage(icon: .fontAwesomeSolid(.volumeUp), size: CGSize(width: 24, height: 24), textColor: .white, backgroundColor: .clear), for: .normal)
        volumeButton.setImage(UIImage(icon: .icofont(.volumeMute), size: CGSize(width: 24, height: 24), textColor: .white, backgroundColor: .clear), for: .selected)
    }
	
	// MARK: - Skins
	
	func resetSkin() {
		allButtons.forEach {
			$0.setImage(nil, for: .normal)
			$0.setImage(nil, for: .highlighted)
			$0.setImage(nil, for: .selected)
			$0.setImage(nil, for: .disabled)
		}
		
		liveBadgeView.liveBadge.images[.normal] = nil
		liveBadgeView.liveBadge.images[.highlighted] = nil
		liveBadgeView.liveBadge.images[.selected] = nil
		liveBadgeView.liveBadge.images[.disabled] = nil
		
		timeSlider.setThumbImage(nil, for: .normal)
		timeSlider.setThumbImage(nil, for: .highlighted)
		timeSlider.setThumbImage(nil, for: .selected)
		timeSlider.setThumbImage(nil, for: .disabled)
		
		timeSlider.removeTarget(self, action: #selector(progressSliderTouchBegan), for: .touchDown)
		timeSlider.removeTarget(self, action: #selector(progressSliderValueChanged), for: .valueChanged)
		timeSlider.removeTarget(self, action: #selector(progressSliderTouchEnded), for: [.touchUpInside, .touchCancel, .touchUpOutside])
		
		loadingIndicatorView?.removeFromSuperview()
		loadingIndicatorView = nil
		
		playpauseCenterButton.isHidden = false
	}
	
	func resetLayout() {
		allControlViews.forEach { $0.removeFromSuperview() }
		containerView.subviews.forEach { $0.removeFromSuperview() }
		containerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
	}
	
	// MARK: -
	
	override open func layoutSubviews() {
		super.layoutSubviews()
		
		containerView.frame = bounds
		castingView?.frame = bounds
		endscreenView.frame = bounds
		theme?.layoutControls(rect: bounds)
		
		if let messageLabel = messageLabel {
			let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
			#if swift(>=4.2)
			let messageBounds = bounds.inset(by: edgeInsets)
			#else
			let messageBounds = UIEdgeInsetsInsetRect(bounds, edgeInsets)
			#endif
			
			let viewSize = messageBounds.size
			let labelSize = messageLabel.sizeThatFits(messageBounds.size)
			messageLabel.frame = CGRect(x: messageBounds.origin.x, y: messageBounds.origin.y + (viewSize.height - labelSize.height)/2,
                                        width: viewSize.width, height: labelSize.height)
		}
		
		alignLogo()
	}
	
	// MARK: -
	
	open func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
		totalTimeLabel.text = totalTime.toString
		var remainingTime: TimeInterval
		
		if seekedTime > -1 {
			if playerLastState == .readyToPlay {
				seekedTime = -1
				timeSlider.value = totalTime>0 ? Float(currentTime) / Float(totalTime) : 0
                currentTimeLabel.text = currentTime.toString
				remainingTime = max(totalTime - currentTime, 0)
				remainTimeLabel.text = remainingTime.toString
			} else {
				timeSlider.value = totalTime>0 ? Float(seekedTime) / Float(totalTime) : 0
				currentTimeLabel.text = seekedTime.toString
				
				remainingTime = max(seekedTime - currentTime, 0)
				remainTimeLabel.text = remainingTime.toString
			}
		} else {
			timeSlider.value = totalTime>0 ? Float(currentTime) / Float(totalTime) : 0
			currentTimeLabel.text = (resource?.isLive ?? false) ? currentTime.toLiveString : currentTime.toString
			remainingTime = max(totalTime - currentTime, 0)
			remainTimeLabel.text = remainingTime.toString
		}
		
		setNeedsLayout()
	}
	
	open func loadedTimeDidChange(loadedDuration: TimeInterval, totalDuration: TimeInterval) {
		let progress = totalDuration>0 ? Float(loadedDuration)/Float(totalDuration) : 0
		timeSlider.progressView.setProgress(progress, animated: true)
	}
	
	open func playerStateDidChange(state: UZPlayerState) {
		switch state {
			case .readyToPlay: hideLoader()
			case .buffering: showLoader()
			case .bufferFinished: hideLoader()
			case .playedToTheEnd:
				playpauseCenterButton.isSelected = false
				playpauseButton.isSelected = false
//				showEndScreen()
//				showControlView()
			
			default: break
		}
		
		playerLastState = state
		setNeedsLayout()
	}
	
	// MARK: - UI update related function
	
	open func prepareUI(for resource: UZPlayerResource, video: UZVideoItem?, playlist: [UZVideoItem]?) {
		self.currentPlaylist = playlist
		self.resource = resource
		self.currentVideo = video
		
		titleLabel.text = resource.name
		endscreenView.title = playerConfig?.endscreenMessage ?? resource.name
		
		let isLiveVideo = (video?.isLive ?? resource.isLive)
		liveBadgeView.isHidden = !isLiveVideo
		theme?.updateLiveViewCount(-1)
		
		let controlsForTimeshift: [UIView] = [totalTimeLabel, remainTimeLabel, currentTimeLabel, timeSlider]
		var hiddenViewsWhenLive: [UIView] = [titleLabel, playpauseButton, playpauseCenterButton, forwardButton,
                                             backwardButton, settingsButton, playlistButton, relateButton]
		if !enableTimeshiftForLiveVideo {
			hiddenViewsWhenLive.append(contentsOf: controlsForTimeshift)
		}
		
		hiddenViewsWhenLive.forEach { $0.isHidden = isLiveVideo }
		
		helpButton.isHidden = isLiveVideo
		ccButton.isHidden = isLiveVideo
        if resource.timeshiftSupport || !resource.isLive {
            settingsButton.isHidden = false
        } else {
            settingsButton.isHidden = (playerConfig?.showQualitySelector ?? false) || resource.definitions.count < 2
        }
		autoFadeOutControlView(after: autoHideControlsInterval)
        if resource.timeshiftSupport {
            setUIWithTimeshift(resource.timeShiftOn)
        }
		setNeedsLayout()
	}
	
	open func autoFadeOutControlView(after interval: TimeInterval) {
		cancelAutoFadeOutAnimation()
		
		delayItem = DispatchWorkItem { [weak self] in
			if self?.playerLastState != .playedToTheEnd {
				self?.hideControlView()
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + interval, execute: delayItem!)
	}
    
    open func setUIWithTimeshift(_ timeshiftOn: Bool) {
        timeSlider.isHidden = !timeshiftOn
        currentTimeLabel.isHidden = !timeshiftOn
        totalTimeLabel.isHidden = !timeshiftOn
        remainTimeLabel.isHidden = !timeshiftOn
    }
	
	open func cancelAutoFadeOutAnimation() {
		delayItem?.cancel()
	}
	
	open func alignLogo() {
		if !logoButton.isHidden {
			let logoSize = logoButton.sizeThatFits(bounds.size)
			let logoPosition = playerConfig?.logoDisplayPosition ?? "top-right"
			let components = logoPosition.components(separatedBy: "-")
			let position: (vertical: String, horizontal: String) = (components[0], components[1])
			var x: CGFloat = 0.0
			var y: CGFloat = 0.0
			
			switch position.horizontal.lowercased() {
			case "left", "l":
				x = 0.0
				
			case "center", "c":
				x = (bounds.size.width - logoSize.width)/2
				
			case "right", "r":
				x = bounds.size.width - logoSize.width
				
			default:
				x = 0.0
			}
			
			switch position.vertical.lowercased() {
			case "top", "t":
				y = 0.0
				
			case "center", "c":
				y = (bounds.size.height - logoSize.height)/2
				
			case "bottom", "b":
				y = bounds.size.height - logoSize.height
				
			default:
				y = 0.0
			}
			
			let logoFrame = CGRect(origin: CGPoint(x: x, y: y), size: logoSize)
			let edgeInsets = containerView.isHidden ? logoEdgeInsetsWhenControlsInvisible : logoEdgeInsetsWhenControlsVisible
			
			#if swift(>=4.2)
			logoButton.frame = logoFrame.inset(by: edgeInsets)
			#else
			logoButton.frame = UIEdgeInsetsInsetRect(logoFrame, edgeInsets)
			#endif
			
		}
		
		theme?.alignLogo()
	}
	
	open func updateUI(_ isForFullScreen: Bool) {
		fullscreenButton.isSelected = isForFullScreen
	}
    
	// MARK: - Action
	
	@objc open func onButtonPressed(_ button: UIButton) {
		autoFadeOutControlView(after: autoHideControlsInterval)
		
		if let type = UZButtonTag(rawValue: button.tag) {
			switch type {
				case .play, .replay:
					hideEndScreen()
				
				default:
					break
			}
		}
		
		delegate?.controlView(controlView: self, didSelectButton: button)
		setNeedsLayout()
	}
	
}

extension UZPlayerControlView {
    internal func setupGestures() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTapGesture?.numberOfTapsRequired = 2
        doubleTapGesture?.delegate = self
        tapGesture!.require(toFail: doubleTapGesture!)
        
        addGestureRecognizer(tapGesture!)
        addGestureRecognizer(doubleTapGesture!)
    }
    
    fileprivate func updateLiveDate() {
        timer?.invalidate()
        timer = nil
        
        if liveStartDate != nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimer), userInfo: nil, repeats: true)
        } else {
            enlapseTimeLabel.setTitle(nil, for: .normal)
            enlapseTimeLabel.isHidden = true
        }
    }
}
