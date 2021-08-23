//
//  AVAsset+Selection.swift
//  UizaSDK
//
//  Created by Nam Kennic on 5/17/19.
//  Copyright © 2019 Uiza. All rights reserved.
//

import AVFoundation

extension AVAsset {
    
    var subtitleGroup: AVMediaSelectionGroup? {
        return self.mediaSelectionGroup(forMediaCharacteristic: .legible)
    }
    
    var subtitles: [AVMediaSelectionOption]? {
        if let group = self.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            return group.options
        }
        return nil
    }
    
    var audioGroup: AVMediaSelectionGroup? {
        return self.mediaSelectionGroup(forMediaCharacteristic: .audible)
    }
    
    var audioTracks: [AVMediaSelectionOption]? {
        if let group = self.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            return group.options
        }
        return nil
    }

    var videoTracks: [AVAssetTrack]? {
       return self.tracks
    }
}
