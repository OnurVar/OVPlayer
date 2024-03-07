//
//  OVPlayerCoordinator.swift
//  OVPlayer
//
//  Created by Onur Var on 6.03.2024.
//

import AVKit
import Combine

public class OVPlayerCoordinator: NSObject {
    // MARK: Variables

    private let playerViewController: AVPlayerViewController
    private let playerActionPublisher: PassthroughSubject<OVPlayerPlayerActionPublisherType, Never>?
    private let statusObserver: PassthroughSubject<OVPlayerStatusObserverType, Never>?
    private let timerObserver: PassthroughSubject<OVPlayerTimerObserverType, Never>?
    private var url: URL? = nil
    private let observer = OVPlayerObserver()
    private var cancellables = Set<AnyCancellable>()

    let player = AVPlayer()
    var options: OVPlayerOptions?

    // MARK: Life Cycle

    public init(
        playerViewController: AVPlayerViewController,
        playerActionPublisher: PassthroughSubject<OVPlayerPlayerActionPublisherType, Never>?,
        statusObserver: PassthroughSubject<OVPlayerStatusObserverType, Never>?,
        timerObserver: PassthroughSubject<OVPlayerTimerObserverType, Never>?,
        options: OVPlayerOptions?
    ) {
        // Set the playerViewController
        self.playerViewController = playerViewController
        self.playerActionPublisher = playerActionPublisher
        self.statusObserver = statusObserver
        self.timerObserver = timerObserver
        self.options = options

        // Call the super init
        super.init()

        // Set the delegate of the playerViewController and player
        observer.delegate = self
        observer.addTimeControlStatusObserver(toPlayer: player)
        observer.addTimeObserver(toPlayer: player)

        // Sink the overlayActionPublisher
        playerActionPublisher?.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .Play:
                self.playVideo()
            case .Pause:
                self.pauseVideo()
            case .GoTo(let milliSeconds):
                self.goTo(milliSeconds: milliSeconds)
            }
        }
        .store(in: &cancellables)
    }

    deinit {
        print("OVPlayerCoordinator: deinit")
    }

    func removeAllObservers() {
        if let playerItem = player.currentItem {
            observer.removeStatusObserver(toPlayerItem: playerItem)
            observer.removePlayerReachEndObserver(toPlayerItem: playerItem)
        }
        observer.removeTimeObserver(fromPlayer: player)
        observer.removeTimeControlStatusObserver(fromPlayer: player)
        observer.delegate = nil
    }

    // MARK: URL Methods

    /// Checks if the video URL has changed. If so, it refreshes the video player with the new URL.
    public func checkUrlChange(url: URL?) {
        // Check if the url is not nil
        guard let url = url else {
            cleanVideoPlayer()
            return
        }

        // Check if the url has changed
        guard url.absoluteString != self.url?.absoluteString else { return }

        // Set the new url
        self.url = url

        // Open the video player with the new URL
        openUrl(url: url)
    }

    /// Opens the video player with the given URL
    private func openUrl(url: URL) {
        // Remove observers from the current playerItem if exists
        if let playerItem = player.currentItem {
            observer.removeStatusObserver(toPlayerItem: playerItem)
            observer.removePlayerReachEndObserver(toPlayerItem: playerItem)
        }

        // Create new PlayerItem and replace it with the current one
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 10
        player.replaceCurrentItem(with: playerItem)

        // Set the player's volume and mute status
        player.isMuted = options?.isMuted ?? false

        // Notify the statusObserver that the video player is not ready and is loading
        statusObserver?.send(.PlayerStatusChanged(type: .Loading))
        statusObserver?.send(.VideoStatusChanged(type: .NotReady))

        // Add observers to the new playerItem
        observer.addStatusObserver(toPlayerItem: playerItem)
        observer.addPlayerReachEndObserver(toPlayerItem: playerItem)
    }

    /// Cleans the video player and removes all observers
    private func cleanVideoPlayer() {
        // Remove observers from the current playerItem
        if let playerItem = player.currentItem {
            observer.removeStatusObserver(toPlayerItem: playerItem)
            observer.removePlayerReachEndObserver(toPlayerItem: playerItem)
        }

        // Clean the player
        player.replaceCurrentItem(with: nil)
    }

    // MARK: Action Methods

    /// Plays the video
    private func playVideo() {
        // Check if the video reached the end. If so, seek to the beginning
        if player.currentItem?.duration == player.currentTime() {
            player.seek(to: .zero)
        }

        // Play the video
        player.play()
    }

    /// Pauses the video
    private func pauseVideo() {
        // Pause the video
        player.pause()
    }

    /// Goes to the given milliSeconds
    private func goTo(milliSeconds: Double) {
        let time: CMTime = .init(seconds: milliSeconds / 1000, preferredTimescale: 1000)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

extension OVPlayerCoordinator: AVPlayerViewControllerDelegate {}

extension OVPlayerCoordinator: OVPlayerObserverDelegate {
    func didCurrentTimeChange(currentTimeInMilliSeconds: Double) {
        timerObserver?.send(.CurrentTimeChanged(milliSeconds: currentTimeInMilliSeconds))

        // Check if loopRangeInMilliseconds is set and the currentTimeInMilliSeconds is greater than the upperBound, then go to the lowerBound
        if let loopRangeInMilliseconds = options?.loopRangeInMilliseconds, currentTimeInMilliSeconds > loopRangeInMilliseconds.upperBound {
            let lowerBoundInMilliSeconds = loopRangeInMilliseconds.lowerBound
            goTo(milliSeconds: lowerBoundInMilliSeconds)
        }
    }

    func didTimeControlStatusChange(oldStatus: AVPlayer.TimeControlStatus?, newStatus: AVPlayer.TimeControlStatus?) {
        guard let newStatus, let oldStatus, newStatus != oldStatus else { return }
        let type: OVPlayerPlayerStatusType = switch newStatus {
        case .paused:
            .Paused
        case .waitingToPlayAtSpecifiedRate:
            .Loading
        case .playing:
            .Playing
        @unknown default:
            fatalError()
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.statusObserver?.send(.PlayerStatusChanged(type: type))
        }
    }

    func didStatusChange(status: AVPlayerItem.Status) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            switch status {
            case .readyToPlay:

                // Notify the statusObserver that the video player is ready
                self.statusObserver?.send(.VideoStatusChanged(type: .Ready))

                // Notify the timerObserver that the total time has changed
                let totalTimeInMilliSeconds: Double = CMTimeGetSeconds(player.currentItem?.duration ?? .zero) * 1000
                self.timerObserver?.send(.TotalTimeChanged(milliSeconds: totalTimeInMilliSeconds))

                // Check if the video should play automatically
                if let autoPlayVideoWhenReady = self.options?.autoPlayVideoWhenReady, autoPlayVideoWhenReady {
                    self.playVideo()
                }

            case .failed:

                // Notify the statusObserver that the video player has failed
                self.statusObserver?.send(.VideoStatusChanged(type: .Failed))
            default:

                // Notify the statusObserver that the video player is unknown
                self.statusObserver?.send(.VideoStatusChanged(type: .Unknown))
            }
        }
    }

    func didPlayerReachEnd() {
        guard let loopVideoWhenEndReached = options?.loopVideoWhenEndReached, loopVideoWhenEndReached else { return }
        player.seek(to: .zero)
        player.play()
    }
}
