//
//  AVPlayer+LogarithmicVolume.swift
//  UZPlayerExample
//
//  Created by Nam Kennic on 10/25/21.
//  Copyright © 2021 namndev. All rights reserved.
//

import AVFoundation

extension AVPlayer {
	
	/**
	 Logarithmic volume
	 
	 https://dcordero.me/posts/logarithmic_volume_control.html
	 */
	var logarithmicVolume: Float {
		get { sqrt(volume) }
		set { volume = pow(newValue, 2) }
	}
	
}
