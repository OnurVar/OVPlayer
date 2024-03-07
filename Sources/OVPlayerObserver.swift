//
//  OVPlayerObserver.swift
//  OVPlayer
//
//  Created by Onur Var on 6.03.2024.
//

import AVKit

protocol OVPlayerObserverProtocol {
    func addTimeObserver(toPlayer player: AVPlayer)
    func removeTimeObserver(fromPlayer player: AVPlayer)
    func addTimeControlStatusObserver(toPlayer player: AVPlayer)
    func removeTimeControlStatusObserver(fromPlayer player: AVPlayer)
    func addStatusObserver(toPlayerItem playerItem: AVPlayerItem)
    func removeStatusObserver(toPlayerItem playerItem: AVPlayerItem)
    func addPlayerReachEndObserver(toPlayerItem playerItem: AVPlayerItem)
    func removePlayerReachEndObserver(toPlayerItem playerItem: AVPlayerItem)
}

protocol OVPlayerObserverDelegate {
    func didCurrentTimeChange(currentTimeInMilliSeconds: Double)
    func didTimeControlStatusChange(oldStatus: AVPlayer.TimeControlStatus?, newStatus: AVPlayer.TimeControlStatus?)
    func didStatusChange(status: AVPlayerItem.Status)
    func didPlayerReachEnd()
}

class OVPlayerObserver: NSObject, OVPlayerObserverProtocol {
    // MARK: Variables

    static let kTimeControlStatus = "timeControlStatus"
    static let kStatus = "status"

    var delegate: OVPlayerObserverDelegate?

    var currentTimeObserver: Any?
    var playerReachEndObserver: Any?

    var timeControlStatusContext = 0
    var itTimeControlStatusContextEnabled = false

    var statusContext = 1
    var isStatusContextEnabled = false

    // MARK: Life Cycle

    override init() {
        super.init()
    }

    deinit {
        print("CoreVideoPlayerObserver: deinit")
    }

    // MARK: Methods

    private func didCurrentTimeChange(time: CMTime) {
        let currentTimeInMilliSeconds = time.seconds * 1000
        //            logger.info("Time: \(currentTimeInMilliSeconds)")
        delegate?.didCurrentTimeChange(currentTimeInMilliSeconds: currentTimeInMilliSeconds)
    }

    func didPlayerReachEnd(notification: Notification) {
        delegate?.didPlayerReachEnd()
    }

    // MARK: Protocol Methods

    func addTimeObserver(toPlayer player: AVPlayer) {
        currentTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: nil, using: didCurrentTimeChange)
    }

    func removeTimeObserver(fromPlayer player: AVPlayer) {
        if let currentTimeObserver {
            player.removeTimeObserver(currentTimeObserver)
        }

        currentTimeObserver = nil
    }

    func addTimeControlStatusObserver(toPlayer player: AVPlayer) {
        player.addObserver(self, forKeyPath: OVPlayerObserver.kTimeControlStatus, options: [.new, .old], context: &timeControlStatusContext)
        itTimeControlStatusContextEnabled = true
    }

    func removeTimeControlStatusObserver(fromPlayer player: AVPlayer) {
        guard itTimeControlStatusContextEnabled else { return }
        player.removeObserver(self, forKeyPath: OVPlayerObserver.kTimeControlStatus, context: &timeControlStatusContext)
        itTimeControlStatusContextEnabled = false
    }

    func addStatusObserver(toPlayerItem playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: OVPlayerObserver.kStatus, options: [.new, .old], context: &statusContext)
        isStatusContextEnabled = true
    }

    func removeStatusObserver(toPlayerItem playerItem: AVPlayerItem) {
        guard isStatusContextEnabled else { return }
        playerItem.removeObserver(self, forKeyPath: OVPlayerObserver.kStatus, context: &statusContext)
        isStatusContextEnabled = false
    }

    func addPlayerReachEndObserver(toPlayerItem playerItem: AVPlayerItem) {
        playerReachEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main, using: didPlayerReachEnd)
    }

    func removePlayerReachEndObserver(toPlayerItem playerItem: AVPlayerItem) {
        if let playerReachEndObserver {
            NotificationCenter.default.removeObserver(playerReachEndObserver)
        }
        playerReachEndObserver = nil
    }

    // MARK: KVO Methods

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case OVPlayerObserver.kTimeControlStatus:
            if context == &timeControlStatusContext {
                if let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
                    let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
                    let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
                    delegate?.didTimeControlStatusChange(oldStatus: oldStatus, newStatus: newStatus)
                    return
                }
            }
        case OVPlayerObserver.kStatus:
            if context == &statusContext {
                if let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let newStatus = AVPlayerItem.Status(rawValue: newValue) {
                    delegate?.didStatusChange(status: newStatus)
                    return
                }
            }
        default:
            break
        }

        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
