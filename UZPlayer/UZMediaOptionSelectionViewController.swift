//
//  UZMediaOptionSelectionViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/31/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import AVFoundation
import FrameLayoutKit
import NKModalViewManager

class UZMediaOptionSelectionViewController: UIViewController {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let collectionViewController = UZMediaOptionSelectionCollectionViewController()
	let frameLayout = FrameLayout()
	
	var selectedSubtitleOption: AVMediaSelectionOption? {
		didSet {
			self.collectionViewController.selectedSubtitleOption = selectedSubtitleOption
		}
	}
	
	var selectedAudioOption: AVMediaSelectionOption? {
		didSet {
			self.collectionViewController.selectedAudioOption = selectedAudioOption
		}
	}
    
    var subtitiles: [UZVideoSubtitle] = [] {
        didSet {
            collectionViewController.subtitles = subtitiles
        }
    }
    
    var selectedSubtitle: UZVideoSubtitle? {
        didSet {
            collectionViewController.selectedSubtitle = selectedSubtitle
        }
    }
	
	var asset: AVAsset? = nil {
		didSet {
			self.collectionViewController.subtitleOptions = []
			self.collectionViewController.audioOptions = []
			
			if let asset = asset {
				if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
					self.collectionViewController.subtitleOptions = group.options
					DLog("Audios:\(group.options)")
				}
				
				if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
					self.collectionViewController.audioOptions = group.options
					DLog("Subtitles:\(group.options)")
				}
			}
			
			self.collectionViewController.collectionView?.reloadData()
		}
	}
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		frameLayout.targetView = collectionViewController.view
		frameLayout.minSize = CGSize(width: 0, height: 100)
		frameLayout.padding(top: 10, left: 20, bottom: 10, right: 20)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
		view.addSubview(blurView)
		view.addSubview(collectionViewController.view)
		view.addSubview(frameLayout)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		blurView.frame = view.bounds
		frameLayout.frame = view.bounds
	}
	
	override var preferredContentSize: CGSize {
		get {
			var screenSize = UIScreen.main.bounds.size
			screenSize.width = min(320, screenSize.width * 0.8)
			screenSize.height = min(min(400, screenSize.height * 0.8),
                                    CGFloat(self.collectionViewController.audioOptions.count * 50) +
                                        CGFloat(self.collectionViewController.subtitleOptions.count * 50) + 130)
			return frameLayout.sizeThatFits(screenSize)
		}
		set {
			super.preferredContentSize = newValue
		}
	}
	
	override var prefersStatusBarHidden: Bool {
		return UIApplication.shared.isStatusBarHidden
	}
	
	override var shouldAutorotate: Bool {
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .all
	}
	
	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return UIApplication.shared.statusBarOrientation
	}
	
	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		if let modalViewController = NKModalViewManager.sharedInstance()?.modalViewControllerThatContains(self) {
			modalViewController.dismissWith(animated: flag, completion: completion)
		} else {
			super.dismiss(animated: flag, completion: completion)
		}
	}
	
}

extension UZMediaOptionSelectionViewController: NKModalViewControllerProtocol {
	
	func shouldTapOutside(toDismiss modalViewController: NKModalViewController!) -> Bool {
		return true
	}
	
	func presentingStyle(for modalViewController: NKModalViewController!) -> NKModalPresentingStyle {
		return .zoomIn
	}
	
	func dismissingStyle(for modalViewController: NKModalViewController!) -> NKModalDismissingStyle {
		return .zoomOut
	}
	
}

// MARK: - UZMediaOptionSelectionCollectionViewController

internal class UZMediaOptionSelectionCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	private let cellIdentifier	= "OptionItemCell"
	private let reuseHeaderIdentifier = "GroupHeader"
	
	let flowLayout		= UICollectionViewFlowLayout()
	var selectedBlock: ((_ item: AVMediaSelectionOption?, _ indexPath: IndexPath) -> Void)?
	var messageLabel: UILabel?
	
	var selectedSubtitleOption: AVMediaSelectionOption?
	var selectedAudioOption: AVMediaSelectionOption?
	var subtitleOptions: [AVMediaSelectionOption]! = []
	var audioOptions: [AVMediaSelectionOption]! = []
    var selectedSubtitle: UZVideoSubtitle? {
        didSet {
            collectionView?.reloadData()
        }
    }
    var subtitles: [UZVideoSubtitle] = [] {
        didSet {
            collectionView?.reloadData()
        }
    }
	
	init() {
		super.init(collectionViewLayout: flowLayout)
		
		flowLayout.minimumLineSpacing = 10
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.scrollDirection = .vertical
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func indexPath(ofItem item: AVMediaSelectionOption!) -> IndexPath? {
		var index = 0
		var found = false
		
		for option in self.audioOptions {
			if item == option {
				found = true
				break
			}
			
			index += 1
		}
		
		if found {
			return IndexPath(item: index, section: 0)
		}
		
		index = 0
		for option in self.subtitleOptions {
			if item == option {
				found = true
				break
			}
			
			index += 1
		}
		
		if found {
			return IndexPath(item: index, section: 1)
		}
		
		return nil
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let collectionView = self.collectionView!
		collectionView.register(UZMediaOptionItemCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
		#if swift(>=4.2)
		collectionView.register(UZTitleCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: reuseHeaderIdentifier)
		#else
		collectionView.register(UZTitleCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: reuseHeaderIdentifier)
		#endif
		
//		collectionView.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.backgroundColor = UIColor.clear
		collectionView.clipsToBounds = false
		collectionView.allowsMultipleSelection = false
		collectionView.alwaysBounceVertical = false
		collectionView.alwaysBounceHorizontal = true
		collectionView.isDirectionalLockEnabled	= true
		collectionView.scrollsToTop = false
		collectionView.keyboardDismissMode = .interactive
		collectionView.dataSource = self
		collectionView.delegate = self
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if let messageLabel = messageLabel {
			var viewSize = view.bounds.size
			viewSize.width -= 20
			let labelSize = messageLabel.sizeThatFits(viewSize)
			messageLabel.frame = CGRect(x: 10, y: (viewSize.height - labelSize.height)/2, width: viewSize.width, height: labelSize.height)
		}
	}
	
	func resourceItemAtIndexPath(_ indexPath: IndexPath) -> AVMediaSelectionOption? {
		if indexPath.section == 0 {
			return self.audioOptions[indexPath.item]
		} else if indexPath.section == 1 {
			return self.subtitleOptions[indexPath.item]
		}
		
		return nil
	}
	
	func config(cell: UZMediaOptionItemCollectionViewCell, with option: AVMediaSelectionOption?, and indexPath: IndexPath) {
		cell.option = option
		cell.isSelected = selectedSubtitleOption == option || selectedAudioOption == option
	}
    
    func config(cell: UZMediaOptionItemCollectionViewCell, with subtitle: UZVideoSubtitle, and indexPath: IndexPath) {
        cell.subtitle = subtitle
        if let index = subtitles.firstIndex(where: { $0.id == selectedSubtitle?.id }) {
            cell.isSelected = (index == indexPath.row)
        }
    }
	
//	func showMessage(message: String) {
//		if messageLabel == nil {
//			messageLabel = UILabel()
//			if #available(iOS 8.2, *) {
//				messageLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//			} else {
//				messageLabel?.font = UIFont.systemFont(ofSize: 14)
//			}
//			messageLabel?.textColor = .white
//			messageLabel?.textAlignment = .center
//			view.addSubview(messageLabel!)
//		}
//		
//		messageLabel?.text = message
//	}
//	
//	func hideMessage() {
//		messageLabel?.removeFromSuperview()
//		messageLabel = nil
//	}
	
	// MARK: -
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return audioOptions.count
        } else {
            if subtitles.isEmpty {
                return subtitleOptions.count
            } else {
                return subtitles.count
            }
        }
	}
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		#if swift(>=4.2)
		let headerKind = UICollectionView.elementKindSectionHeader
		#else
		let headerKind = UICollectionElementKindSectionHeader
		#endif
		if kind == headerKind {
			let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: headerKind, withReuseIdentifier: reuseHeaderIdentifier,
                                                                             for: indexPath) as? UZTitleCollectionViewHeader
			headerView?.title = indexPath.section == 0 ? (audioOptions.isEmpty ? "Audio: (none)" : "Audio:") :
                (subtitleOptions.isEmpty ? "Subtitle: (none)" : "Subtitle:")
			return headerView ?? UICollectionReusableView()
		} else {
			return UICollectionReusableView()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return CGSize(width: collectionView.frame.size.width, height: 50)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return .zero
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? UZMediaOptionItemCollectionViewCell
		if cell == nil {
			cell = UZMediaOptionItemCollectionViewCell()
		}
		
        if !subtitles.isEmpty && indexPath.section == 1 {
            config(cell: cell!, with: subtitles[indexPath.row], and: indexPath)
        } else {
            config(cell: cell!, with: resourceItemAtIndexPath(indexPath), and: indexPath)
        }
		
		return cell!
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//		collectionView.deselectItem(at: indexPath, animated: true)
		
        if indexPath.section == 1 && !subtitles.isEmpty {
            selectedBlock?(nil, indexPath)
        } else {
            let item = resourceItemAtIndexPath(indexPath)
            selectedBlock?(item, indexPath)
        }
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let itemWidth = collectionView.bounds.size.width - (collectionView.contentInset.left + collectionView.contentInset.right)
		return CGSize(width: itemWidth * 0.9, height: 50)
	}
	
}
