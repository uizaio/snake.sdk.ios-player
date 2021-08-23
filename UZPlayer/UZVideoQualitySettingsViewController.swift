//
//  UZVideoQualitySettingsViewController.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/21/18.
//  Copyright © 2018 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import NKModalViewManager

internal class UZVideoQualitySettingsViewController: UIViewController {
	let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
	let titleLabel = UILabel()
	let collectionViewController = UZVideoQualityCollectionViewController()
	var frameLayout: DoubleFrameLayout!
	var currentDefinition: UZVideoLinkPlay? {
		didSet {
			self.collectionViewController.selectedResource = currentDefinition
		}
	}
	
	var resource: UZPlayerResource? = nil {
		didSet {
			if let resource = resource {
				self.collectionViewController.resources = resource.definitions
				self.collectionViewController.collectionView?.reloadData()
			}
		}
	}
	
	init() {
		super.init(nibName: nil, bundle: nil)
		
		titleLabel.text = "Video Quality"
		if #available(iOS 8.2, *) {
			titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
		} else {
			titleLabel.font = UIFont.systemFont(ofSize: 15)
		}
		titleLabel.textColor = .white
		titleLabel.textAlignment = .center
		frameLayout = DoubleFrameLayout(axis: .vertical, views: [titleLabel, collectionViewController.view])
		frameLayout.bottomFrameLayout.minSize = CGSize(width: 0, height: 100)
		frameLayout.padding(top: 20, left: 10, bottom: 10, right: 10)
		frameLayout.spacing = 20
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
		view.addSubview(blurView)
		view.addSubview(titleLabel)
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
			screenSize.height = min(min(400, screenSize.height * 0.8), CGFloat(self.collectionViewController.resources.count * 50) + 70)
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

extension UZVideoQualitySettingsViewController: NKModalViewControllerProtocol {
	
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

// MARK: - UZVideoQualityCollectionViewController

internal class UZVideoQualityCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	let cellIdentifier	= "VideoQualityItemCell"
	let flowLayout		= UICollectionViewFlowLayout()
	var selectedResource: UZVideoLinkPlay?
	var resources: [UZVideoLinkPlay]! = []
	var selectedBlock: ((_ item: UZVideoLinkPlay, _ index: Int) -> Void)?
	var messageLabel: UILabel?
	
	init() {
		super.init(collectionViewLayout: flowLayout)
		
		flowLayout.minimumLineSpacing = 10
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.scrollDirection = .horizontal
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func appendItems(items: [UZVideoLinkPlay]!) -> [UZVideoLinkPlay]! {
		var finalItems = [UZVideoLinkPlay]() // remove duplicated items
		items.forEach { (item: UZVideoLinkPlay) in
			let indexPath = self.indexPath(ofItem: item)
			if indexPath == nil {
				finalItems.append(item)
			}
		}
		
		self.resources.append(contentsOf: finalItems)
		
		var indexes = [IndexPath]()
		finalItems.forEach { (item: UZVideoLinkPlay) in
			let indexPath = self.indexPath(ofItem: item)
			if indexPath != nil {
				indexes.append(indexPath!)
			}
		}
		
		if !indexes.isEmpty {
			var currentNumberOfSections = self.collectionView!.numberOfSections - 1
			self.collectionView?.performBatchUpdates({
				self.collectionView?.insertItems(at: indexes)
				
				indexes.forEach({ (indexPath: IndexPath) in
					if indexPath.section>currentNumberOfSections {
						self.collectionView?.insertSections([indexPath.section])
						currentNumberOfSections += 1
					}
				})
			}, completion: nil)
		}
		
		return finalItems
	}
	
	func indexPath(ofItem item: UZVideoLinkPlay!) -> IndexPath? {
		var index = 0
		var found = false
		
		for video in self.resources {
			if item == video {
				found = true
				break
			}
			
			index += 1
		}
		
		if found {
			return IndexPath(item: index, section: 0)
		} else {
			return nil
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let collectionView = self.collectionView!
		collectionView.register(UZQualityItemCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
		
		#if swift(>=4.2)
		let headerKind = UICollectionView.elementKindSectionHeader
		#else
		let headerKind = UICollectionElementKindSectionHeader
		#endif
		
		collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: headerKind, withReuseIdentifier: "Header")
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
	
	func resourceItemAtIndexPath(_ indexPath: IndexPath) -> UZVideoLinkPlay {
		return resources[(indexPath as NSIndexPath).item]
	}
	
	func config(cell: UZQualityItemCollectionViewCell, with resource: UZVideoLinkPlay, and indexPath: IndexPath) {
		cell.resource = resource
		cell.isSelected = selectedResource == resource
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
//	
	// MARK: -
	
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return resources.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		return UICollectionReusableView()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return .zero
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return .zero
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? UZQualityItemCollectionViewCell
		if cell == nil {
			cell = UZQualityItemCollectionViewCell()
		}
		
		config(cell: cell!, with: resourceItemAtIndexPath(indexPath), and: indexPath)
		
		return cell!
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//		collectionView.deselectItem(at: indexPath, animated: true)
		
		let item = resourceItemAtIndexPath(indexPath)
		selectedBlock?(item, indexPath.item)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let itemWidth = collectionView.bounds.size.width - (collectionView.contentInset.left + collectionView.contentInset.right)
		return CGSize(width: itemWidth, height: 50)
	}
	
}

// MARK: - UZQualityItemCollectionViewCell

class UZQualityItemCollectionViewCell: UICollectionViewCell {
	var highlightView: UIView!
	var titleLabel: UILabel!
	var frameLayout: DoubleFrameLayout!
	var highlightMode		= false {
		didSet {
			self.isSelected = super.isSelected
		}
	}
	override var isHighlighted: Bool {
		get {
			return super.isHighlighted
		}
		set (value) {
			super.isHighlighted = value
			self.updateColor()
		}
	}
	
	override var isSelected: Bool {
		get {
			return super.isSelected
		}
		set (value) {
			super.isSelected = value
			if #available(iOS 8.2, *) {
				titleLabel.font = UIFont.systemFont(ofSize: 14, weight: value ? .bold : .regular)
			} else {
				titleLabel.font = UIFont.systemFont(ofSize: 14)
			}
			
			if highlightMode {
				UIView.animate(withDuration: 0.3) {
					self.contentView.alpha = value ? 1.0 : 0.25
				}
			} else {
				self.contentView.alpha = 1.0
				self.updateColor()
			}
		}
	}
	
	var resource: UZVideoLinkPlay? {
		didSet {
			updateView()
		}
	}
	
	func updateColor() {
		if self.isHighlighted {
			highlightView.alpha = 1.0
			highlightView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
			titleLabel.textColor = .black
		} else if self.isSelected {
			highlightView.alpha = 1.0
			highlightView.backgroundColor = UIColor(red: 0.21, green: 0.49, blue: 0.96, alpha: 1.00)
			titleLabel.textColor = .white
		} else {
			titleLabel.textColor = .white
			
			UIView.animate(withDuration: 0.3, animations: {() -> Void in
				self.highlightView.alpha = 0.0
			})
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: CGRect.zero)
		
		self.backgroundColor = .clear
		
		self.backgroundView = UIView()
		self.backgroundView!.backgroundColor = UIColor.white.withAlphaComponent(0.2)
		self.backgroundView!.layer.cornerRadius = 10
		self.backgroundView!.layer.masksToBounds = true
		
		highlightView = UIView()
		highlightView.alpha = 0.0
		highlightView.layer.cornerRadius = 10
		highlightView.layer.masksToBounds = true
		
		titleLabel = UILabel()
		titleLabel.textAlignment = .center
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		titleLabel.numberOfLines = 1
		titleLabel.textColor = .white
		
		self.contentView.addSubview(highlightView)
		self.contentView.addSubview(titleLabel)
		
		frameLayout = DoubleFrameLayout(axis: .horizontal, views: [titleLabel])
		frameLayout.bottomFrameLayout.fixSize = CGSize(width: 0, height: 40)
		frameLayout.distribution = .center
		frameLayout.spacing = 0
		self.contentView.addSubview(frameLayout)
		
		self.updateColor()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	func updateView() {
		titleLabel.text = resource?.definition ?? ""
		self.setNeedsLayout()
	}
	
	// MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		frameLayout.frame = self.bounds
		
		if let backgroundView = backgroundView {
			let edgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
			#if swift(>=4.2)
			backgroundView.frame = self.contentView.bounds.inset(by: edgeInsets)
			#else
			backgroundView.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, edgeInsets)
			#endif
			
			highlightView.frame = backgroundView.frame
		}
	}
	
}
