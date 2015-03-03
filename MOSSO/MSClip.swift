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
        return buildInstruction(composition: composition, selectedTimeRange: [CMTimeRangeMake(kCMTimeZero, asset.duration)])
    }
    
    
    func buildInstruction(#composition: AVMutableComposition, selectedTimeRange: [CMTimeRange], hideClip: Bool = false) -> AVMutableVideoCompositionLayerInstruction {
        let track = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: 1)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        layerInstruction.setOpacityRampFromStartOpacity(1, toEndOpacity: 0, timeRange:CMTimeRangeMake(fadeOutStart, kMSFadeLength))
        if fadeIn {
            layerInstruction.setOpacityRampFromStartOpacity(0, toEndOpacity: 1, timeRange:CMTimeRangeMake(startTime, kMSFadeLength))
            
        }
        
        var nextSelectionStart = startTime

        for timeRange in selectedTimeRange {
            track.insertTimeRange(timeRange, ofTrack: asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack, atTime: nextSelectionStart, error: nil)
            
            if includeSound && !hideClip {
                if let assetSound = asset.tracksWithMediaType(AVMediaTypeAudio)[0] as? AVAssetTrack {
                    let soundtrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 1)
                    soundtrack.insertTimeRange(timeRange, ofTrack: assetSound, atTime: nextSelectionStart, error: nil)
                    let soundtrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: soundtrack)
                }
            }
            
            nextSelectionStart = CMTimeAdd(nextSelectionStart, timeRange.duration)
        }
        
        let naturalSize = track.naturalSize
        let preferred = track.preferredTransform
        let rect = CGRect(origin: CGPointMake(0,0), size: naturalSize)
        let actualSize = CGRectApplyAffineTransform(rect, preferred).size
        let exportSize = CGSizeMake(720, 480)
        if actualSize != exportSize {
            ViewController.Static.needsMultiplePasses = true
            let fixedWidth : CGFloat = exportSize.width
            let fixedHeight = (fixedWidth / actualSize.width) * actualSize.height
            let scaleFactor = (fixedWidth / actualSize.width)
            let scaleTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor)
            
            let yOffset = (exportSize.height - fixedHeight)
            let letterbox = CGAffineTransformTranslate(scaleTransform, 0, yOffset/2 * (1/scaleFactor))
            
            layerInstruction.setTransform(letterbox, atTime: kCMTimeZero)
        }
        
        if hideClip {
            layerInstruction.setOpacity(0, atTime: startTime)
        }
        
        return layerInstruction
    }
    
}