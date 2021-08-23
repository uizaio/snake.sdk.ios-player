//
//  UZPlayerSDK.swift
//  UZPlayer
//
//  Created by Nam Kennic on 6/21/17.
//  Copyright © 2017 Nam Kennic. All rights reserved.
//

import Foundation

/// API enviroment
public enum UZEnviroment: String {
	/** Production enviroment (Use when releasing to the AppStore) */
	case production = "prod"
	/** Development enviroment */
	case development = "dev"
	/** Staging enviroment */
	case staging = "stag"
}

public class UZPlayerSDK {
	internal static var enviroment: UZEnviroment? = nil // set this before calling the API
	
	public static var language: String = "vi"
	
	/**
	- parameter enviroment: Môi trường hoạt động, mặc định là `.production`
	*/
	public class func initWith(enviroment: UZEnviroment = .production) {
        if self.enviroment == nil {
			self.enviroment = enviroment
			
			#if DEBUG
			print("[UZPlayer] initialized")
			#endif
			
			UZSentry.activate()
		} else {
			#if DEBUG
			print("[UZPlayer] Framework has already been initialized")
			#endif
		}
	}
	
}
