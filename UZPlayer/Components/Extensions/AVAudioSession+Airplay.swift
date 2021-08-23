//
//  AVAudioSession+Airplay.swift
//  Uiza
//
//  Created by Nam Kennic on 11/17/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

import Foundation
import AVFoundation

extension AVAudioSession {
	
    var isAirPlaying: Bool {
        var result = false
        
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for port in currentRoute.outputs {
            #if swift(>=4.2)
            let isAirPlay = port.portType == AVAudioSession.Port.airPlay
            #else
            let isAirPlay = port.portType == AVAudioSessionPortAirPlay
            #endif
            
            if isAirPlay {
                result = true
                break
            }
        }
        
        return result
    }
	
    var sourceName: String? {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        return currentRoute.outputs.first?.portName
    }
	
}
