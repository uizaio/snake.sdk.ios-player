//
//  MoviePlayerViewController.swift
//  UZPlayerExample
//
//  Created by Nam Kennic on 11/14/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import UIKit
import FrameLayoutKit
import NKButton

public class MoviePlayerViewController: UZFloatingPlayerViewController {
	let label = UILabel()
	let themeButton = NKButton()
	let contentLayout = VStackLayout()
	
	let themes: [UZPlayerTheme] = [UZTheme1(), UZTheme2(), UZTheme3(), UZTheme4(), UZTheme5(), UZTheme6(), UZTheme7()]
	
	var topPadding: CGFloat {
		get { frameLayout.edgeInsets.top }
		set {
			frameLayout.edgeInsets.top = newValue
			view.setNeedsLayout()
		}
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .white
		
		label.numberOfLines = 0
		label.font = .systemFont(ofSize: 13, weight: .regular)
		label.textColor = .black
		label.textAlignment = .center
		label.text = """
		Drag down to enter floating mode.
		Then tap on it to unfloat.
		While floating, drag it out of the screen to dismiss.
		"""
		
		themeButton.title = "Switch Theme"
		themeButton.titleFonts[.normal] = .systemFont(ofSize: 13, weight: .regular)
		themeButton.titleColors[.normal] = .black
		themeButton.borderColors[.normal] = .black
		themeButton.borderSizes[.normal] = 1
		themeButton.cornerRadius = 8
		themeButton.extendSize = CGSize(width: 10, height: 6)
		themeButton.addTarget(self, action: #selector(switchTheme), for: .touchUpInside)
		
		detailsContainerView.addSubview(label)
		detailsContainerView.addSubview(themeButton)
		detailsContainerView.addSubview(contentLayout)
		
		contentLayout + label
		(contentLayout + themeButton).alignment.horizontal = .center
		
		contentLayout.spacing = 24
		contentLayout.padding(top: 24, left: 24, bottom: 24, right: 24)
		
		topPadding = view.extendSafeEdgeInsets.top
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		contentLayout.frame = detailsContainerView.bounds
	}
	
	@objc func switchTheme() {
		if playerViewController.player.controlView.theme?.id == themes.last?.id {
			playerViewController.player.controlView.theme = themes.first
		}
		else {
			let index = themes.firstIndex { $0.id == playerViewController.player.controlView.theme?.id } ?? 0
			playerViewController.player.controlView.theme = themes[index + 1]
		}
	}
	
}
