//
//  MusicListViewController.swift
//  YYMusic
//
//  Created by 王浩 on 2020/5/13.
//  Copyright © 2020 haoge. All rights reserved.
//

import UIKit
import Kingfisher
import MJRefresh

class MusicListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    fileprivate var songs: [PlayerModel] = []
    fileprivate var pageSize = 20
    fileprivate var currPage = 1
    fileprivate var totalPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "音乐列表"
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            self.getMusicList(true)
        })
        tableView.mj_footer = MJRefreshBackNormalFooter(refreshingBlock: {
            self.getMusicList(false)
        })
        self.tableView.mj_header?.isAutomaticallyChangeAlpha = true
        self.tableView.mj_header?.beginRefreshing()
        
    }

    func getMusicList(_ first: Bool) {
        if first {
            pageSize = 15
            currPage = 1
            totalPage = 0
        } else {
            currPage += 1
        }
        var param = [String: Any]()
        param["pageId"] = currPage
        param["pageSize"] = pageSize
        let d = RequestHelper.getMusicList(param).generate()
        NetWorkingTool.shared.requestData(generate: d, successCallback: { [weak self](data: PlayerModels?) in
            // refresh
            self?.tableView.mj_header?.endRefreshing()
            self?.tableView.mj_footer?.endRefreshing()
            if let list = data {
                self?.totalPage = data?.maxPageId ?? 0
                self?.tableView.mj_footer?.isHidden = (self?.currPage)! >= (self?.totalPage)!
                if first {
                    self?.songs = []
                    if let list = list.list, !list.isEmpty {
                        self?.songs = list
                    }
                } else {
                    if let list = list.list, !list.isEmpty {
                        self?.songs.append(contentsOf: list)
                    }
                }
                self?.tableView.reloadData()
            }
        })
    }
}

extension MusicListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = songs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath)
        let img1 = cell.viewWithTag(1) as! UIImageView
        let lbl2 = cell.viewWithTag(2) as! UILabel
        let lbl3 = cell.viewWithTag(3) as! UILabel
        img1.layer.cornerRadius = img1.frame.height/2
        img1.layer.masksToBounds = true
        if let urlStr = song.coverSmall, let url = URL(string: urlStr) {
            img1.kf.setImage(with: url)
        }
        lbl2.text = song.title ?? ""
        lbl2.font = UIFont.systemFont(ofSize: 17)
        
        lbl3.text = song.nickname ?? ""
        lbl3.font = UIFont.systemFont(ofSize: 13)
        lbl3.textColor = UIColor.gray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("------->")
    }
    
}
