//
//  OVPlayerRepresentable.swift
//  OVPlayer
//
//  Created by Onur Var on 6.03.2024.
//

import AVKit
import Combine
import SwiftUI

public struct OVPlayerRepresentable: UIViewControllerRepresentable {
    // MARK: Variables

    let url: URL?
    private let playerActionPublisher: PassthroughSubject<OVPlayerPlayerActionPublisherType, Never>?
    private let statusObserver: PassthroughSubject<OVPlayerStatusObserverType, Never>?
    private let timerObserver: PassthroughSubject<OVPlayerTimerObserverType, Never>?
    private let options: OVPlayerOptions?

    @State var playerViewController: AVPlayerViewController = .init()

    // MARK: Life Cycle

    public init(
        url: URL?,
        playerActionPublisher: PassthroughSubject<OVPlayerPlayerActionPublisherType, Never>?,
        statusObserver: PassthroughSubject<OVPlayerStatusObserverType, Never>?,
        timerObserver: PassthroughSubject<OVPlayerTimerObserverType, Never>?,
        options: OVPlayerOptions?
    ) {
        self.url = url
        self.playerActionPublisher = playerActionPublisher
        self.statusObserver = statusObserver
        self.timerObserver = timerObserver
        self.options = options
    }

    // MARK: Methods

    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        // Set attributes
        playerViewController.modalPresentationStyle = .automatic
        playerViewController.canStartPictureInPictureAutomaticallyFromInline = true
        playerViewController.entersFullScreenWhenPlaybackBegins = false
        playerViewController.exitsFullScreenWhenPlaybackEnds = false
        playerViewController.allowsPictureInPicturePlayback = true
        playerViewController.showsPlaybackControls = true
        playerViewController.restoresFocusAfterTransition = true
        playerViewController.updatesNowPlayingInfoCenter = true

        // Set the player
        playerViewController.player = context.coordinator.player

        // Add time observer
        playerViewController.delegate = context.coordinator

        return playerViewController
    }

    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Check if the url has changed
        context.coordinator.checkUrlChange(url: url)

        // There may be updates to the options, so we need to update the coordinator
        context.coordinator.options = options
    }

    public func makeCoordinator() -> OVPlayerCoordinator {
        return OVPlayerCoordinator(
            playerViewController: playerViewController,
            playerActionPublisher: playerActionPublisher,
            statusObserver: statusObserver,
            timerObserver: timerObserver,
            options: options
        )
    }

    public static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: OVPlayerCoordinator) {
        coordinator.removeAllObservers()
    }
}
