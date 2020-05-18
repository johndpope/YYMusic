//
//  PlayerManager.swift
//  YYMusic
//
//  Created by 王浩 on 2020/5/14.
//  Copyright © 2020 haoge. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

enum PlayMode: Int {
    case none = 0
    case next = 1
    case previous = 2
    case play = 3
    case pause = 4
    case auto = 5
}

class PlayerManager: NSObject {
    static let shared = PlayerManager()
        
    /*存放歌曲数组*/
    var musicArray: [MusicModel] = []
    /*播放下标*/
    var index: Int = 0
    /*标记是不是没点列表直接点了播放按钮如果是就默认播放按钮*/
    var isFristPlayerPauseBtn: Bool = true
    /*开始播放*///0是开始 1 暂停
    var isStartPlayer: ((_ index: Int) -> Void)?
    /*是不是正在播放*/
    var isPlaying: Bool = false
    /*播放器*/
    var player: AVPlayer!
    /*标记是否在单曲循环 (如果是yes是当前这首播放完时自动还从新开始播放)当前播放的*/
    var isSinglecycle: Bool = false
    /**获取当前播放的歌曲*/
    var currentModel: MusicModel? {
        get {
            if musicArray.count > 0 {
                return musicArray[index]
            }
            return nil
        }
    }
    fileprivate var isFirstTime: Bool = true
    override init() {
        super.init()
        if player == nil {
            player = AVPlayer()
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback)
            try? session.setActive(true, options: [])
        }
    }
    
    //当前时间
    func getCurrentTime() -> String? {
        if self.player.currentTime().timescale == 0  {
            return nil
        }
        //获取当前时间
        let value = self.player.currentTime().value
        let timescale = self.player.currentTime().timescale
        let currentTime = value/Int64(timescale)
        return "\(currentTime)"
    }
    
    //总时长
    func getTotalTime() -> String? {
        if self.player.currentItem?.duration.timescale == 0 {
            return nil
        }
        //获取音乐总时长
        let d = self.player.currentItem?.duration.value
        let t = self.player.currentItem?.duration.timescale
        let totalTime = d!/Int64(t!)
        return "\(totalTime)"
    }
    
    func timerAct(callback: ObjectCallback?) {
        let currentTime = self.getCurrentTime()
        let totalTime = self.getTotalTime()

        //更新进度圆环 如果当前时间=总时长 就直接下一首(或者单曲循环)
        let cT = Double(currentTime ?? "0")
        let dT = Double(totalTime ?? "0")
        if let ct = cT, let dt = dT, dt > 0.0 {
            if let callback = callback {
                callback(CGFloat(ct/dt))
            }
        }
        
        //存储歌曲总时间, 第一次进入才存
        if let t = totalTime, (Int(t) ?? 0) > 0{
            //只记录一次总时间,防止不停的调用存储
            if isFirstTime {
                isFirstTime = false
                UserDefaultsManager.shared.userDefaultsSet(object: "\(t)", key: TOTALTIME)
            }
        }
    }
    
    //播放
    func playerPlay() {
        player.play()
        isPlaying = true
    }
    
    //暂停
    func playerPause() {
        player.pause()
        isPlaying = false
    }

    //前一首
    func playPrevious(callback: ((_ value: Any)->Void)?) {
        if self.index == 0 {
            self.index = self.musicArray.count - 1
        } else {
            self.index -= 1
        }
        
        self.playReplaceItem(with: self.currentModel?.playUrl32 ?? "", callback: callback)
    }
    
    //下一首
    func playNext(callback: ((_ value: Any)->Void)?) {
        if self.index == self.musicArray.count - 1 {
            self.index = 0
        } else {
            self.index += 1
        }
        self.playReplaceItem(with: self.currentModel?.playUrl32 ?? "", callback: callback)
    }
  
    func playerVolume(with volumeFloat: CGFloat) {
        self.player.volume = Float(volumeFloat)
    }

    func playerProgress(with progressFloat: Double, callback: ObjectCallback?) {
        let time = CMTime(seconds: progressFloat, preferredTimescale: 1)
        self.player.seek(to: time) { [weak self](finished) in
            self?.playerPlay()
            if let callback = callback {
                callback((self?.currentModel)!)
            }
        }
    }
    
    //当前播放
    func playReplaceItem(with urlString: String, callback: ObjectCallback?) {
        let url = URL(string: urlString)
        let item = AVPlayerItem(url: url!)
        self.player.replaceCurrentItem(with: item)
        self.playerPlay()
        
        if let callback = callback {
            callback((self.currentModel)!)
        }
        
        //存储当前播放的歌曲
        UserDefaultsManager.shared.archiver(object: (self.currentModel)!, key: CURRENTMUSIC)
        //获取总时间
        if let time = UserDefaultsManager.shared.userDefaultsGet(key: TOTALTIME) as? String {
            lockScreeen(totalTime: time)
        }
    }
    
    //展示音乐播放界面
    func presentPlayController(vc: UIViewController?, mode: MusicModel?, callback: ObjectCallback?) {
        let playVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayViewController") as? PlayViewController
        playVC?.model = mode
        playVC?.callback = callback
        playVC?.modalPresentationStyle = .fullScreen
        vc?.present(playVC!, animated: true, completion: nil)
    }
    
    //MARK:-锁屏传值
    func lockScreeen(totalTime: String) {
        if PlayerManager.shared.musicArray.count > 0 {
            let model = PlayerManager.shared.musicArray[PlayerManager.shared.index]
            var info = [String: Any]()
            //设置歌曲时长
            info[MPMediaItemPropertyPlaybackDuration] = Double(totalTime) ?? 0.0
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            //设置歌曲名
            info[MPMediaItemPropertyTitle] = model.title ?? ""
            //设置演唱者
            info[MPMediaItemPropertyArtist] = model.nickname ?? ""
            //歌手头像
            if let url = (model.coverLarge ?? "").addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                if let data = try? Data(contentsOf: URL(string: url)!) {
                    let artwork = MPMediaItemArtwork.init(boundsSize: CGSize(width: 400, height: 400)) { (size) -> UIImage in
                        return UIImage(data: data)!
                    }
                    info[MPMediaItemPropertyArtwork] = artwork
                }
            }
            //进度光标的速度（这个随 自己的播放速率调整，我默认是原速播放）
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
}
