//
//  OVPlayerStatusObserverType.swift
//  OVPlayer
//
//  Created by Onur Var on 6.03.2024.
//

public enum OVPlayerStatusObserverType {
    case PlayerStatusChanged(type: OVPlayerPlayerStatusType)
    case VideoStatusChanged(type: OVPlayerVideoStatusType)
}
