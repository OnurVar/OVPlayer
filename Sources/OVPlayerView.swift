//
//  OVPlayerView.swift
//  OVPlayer
//
//  Created by Onur Var on 6.03.2024.
//

import Combine
import SwiftUI

public struct OVPlayerView: View {
    // MARK: Variables

    private let url: URL?
    private let playerActionPublisher: PassthroughSubject<OVPlayerPlayerActionPublisherType, Never>?
    private let statusObserver: PassthroughSubject<OVPlayerStatusObserverType, Never>?
    private let timerObserver: PassthroughSubject<OVPlayerTimerObserverType, Never>?
    private let options: OVPlayerOptions?

    // MARK: Life Cycle

    public init(
        url: URL?,
        playerActionPublisher: PassthroughSubject<OVPlayerPlayerActionPublisherType, Never>? = nil,
        statusObserver: PassthroughSubject<OVPlayerStatusObserverType, Never>? = nil,
        timerObserver: PassthroughSubject<OVPlayerTimerObserverType, Never>? = nil,
        options: OVPlayerOptions? = nil
    ) {
        self.url = url
        self.playerActionPublisher = playerActionPublisher
        self.statusObserver = statusObserver
        self.timerObserver = timerObserver
        self.options = options
    }

    // MARK: Body Component

    public var body: some View {
        OVPlayerRepresentable(
            url: url,
            playerActionPublisher: playerActionPublisher,
            statusObserver: statusObserver,
            timerObserver: timerObserver,
            options: options
        )
    }
}
