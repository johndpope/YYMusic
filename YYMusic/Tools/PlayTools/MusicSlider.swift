//
//  MusicSlider.swift
//  YYMusic
//
//  Created by 王浩 on 2020/5/20.
//  Copyright © 2020 haoge. All rights reserved.
//

import UIKit

class MusicSlider: UISlider {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    func setup() {
        let highlighted = UIImage(named: "music_slider_circle")
        let normal = UIImage(named: "icon_dot")
        self.setThumbImage(highlighted, for: .highlighted)
        self.setThumbImage(normal, for: .normal)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var rect = rect
        rect.origin.x = rect.origin.x-10
        rect.size.width = rect.size.width+20
        return super.thumbRect(forBounds: bounds, trackRect: rect, value: value).insetBy(dx: 10, dy: 10)
    }
}