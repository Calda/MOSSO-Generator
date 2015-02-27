//
//  MOSSOClip.swift
//  MOSSO
//
//  Created by DFA Film 9: K-9 on 2/6/15.
//  Copyright (c) 2015 Dog Pound Productions. All rights reserved.
//

import Foundation
import AVFoundation

import QuartzCore

class MSClip {
    
    let kMSFadeLength = CMTimeMake(3, 2)
    
    let asset : AVAsset
    let startTime : CMTime
    let fadeIn : Bool
    let includeSound : Bool
    
    var fadeUpEnd : CMTime {
        get {
            return CMTimeAdd(startTime, kMSFadeLength)
        }
    }
    
    var fadeOutStart : CMTime {
        get {
            return CMTimeSubtract(fadeOutEnd, kMSFadeLength)
        }
    }
    
    var fadeOutEnd : CMTime {
        get {
            return CMTimeAdd(startTime, asset.duration)
        }
    }
    
    var nextClipStart : CMTime {
        get {
            return fadeOutStart
        }
    }
    
    
    init(asset: AVAsset, startTime: CMTime, fadeIn: Bool, includeSound: Bool) {
        self.asset = asset
        self.startTime = startTime
        self.fadeIn = fadeIn
        self.includeSound = includeSound
    }
    
    
    func buildInstruction(composition : AVMutableComposition) -> AVMutableVideoCompositionLayerInstruction {
        return buildInstruction(composition, selectedTimeRange: CMTimeRangeMake(kCMTimeZero, asset.duration))
    }
    
    
    func buildInstruction(composition: AVMutableComposition, selectedTimeRange: CMTimeRange) -> AVMutableVideoCompositionLayerInstruction {
        let track = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: 1)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        layerInstruction.setOpacityRampFromStartOpacity(1, toEndOpacity: 0, timeRange:CMTimeRangeMake(fadeOutStart, kMSFadeLength))
        if fadeIn {
            layerInstruction.setOpacityRampFromStartOpacity(0, toEndOpacity: 1, timeRange:CMTimeRangeMake(startTime, kMSFadeLength))
        }
        track.insertTimeRange(selectedTimeRange, ofTrack: asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack, atTime: startTime, error: nil)
        
        if includeSound {
            if let assetSound = asset.tracksWithMediaType(AVMediaTypeAudio)[0] as? AVAssetTrack {
                let soundtrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 1)
                soundtrack.insertTimeRange(selectedTimeRange, ofTrack: assetSound, atTime: startTime, error: nil)
            }
        }
        
        return layerInstruction
    }
    
}