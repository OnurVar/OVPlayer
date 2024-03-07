//
//  OVPlayerOptions.swift
//  OVPlayer
//
//  Created by Onur Var on 7.03.2024.
//

public struct OVPlayerOptions {
    let autoPlayVideoWhenReady: Bool
    let isMuted: Bool
    let loopVideoWhenEndReached: Bool
    let loopRangeInMilliseconds: ClosedRange<Double>?

    public init(
        autoPlayVideoWhenReady: Bool = true,
        isMuted: Bool = false,
        loopVideoWhenEndReached: Bool = true,
        loopRangeInMilliseconds: ClosedRange<Double>? = nil
    ) {
        self.autoPlayVideoWhenReady = autoPlayVideoWhenReady
        self.isMuted = isMuted
        self.loopVideoWhenEndReached = loopVideoWhenEndReached
        self.loopRangeInMilliseconds = loopRangeInMilliseconds
    }
}
