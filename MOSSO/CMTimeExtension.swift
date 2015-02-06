//
//  CMTimeExtension.swift
//  MOSSO
//
//  Created by DFA Film 9: K-9 on 2/6/15.
//  Copyright (c) 2015 Dog Pound Productions. All rights reserved.
//

import AVFoundation

func < (left: CMTime, right: CMTime) -> Bool {
    return left.floatTime() < right.floatTime()
}

func > (left: CMTime, right: CMTime) -> Bool {
    return left.floatTime() > right.floatTime()
}


extension CMTime {
    
    func floatTime() -> Float {
        return Float(value) / Float(timescale)
    }
    
}