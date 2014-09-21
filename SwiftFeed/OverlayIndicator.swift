//
//  OverlapIndicator.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/21.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

import UIKit

public class OverlayIndicator {
    let overlay: UIActivityIndicatorView

    public init() {
        let  window = UIApplication.sharedApplication().keyWindow

        overlay = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        overlay.frame = window.frame
        overlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)

        window.addSubview(overlay)
        overlay.startAnimating()
    }

    deinit {
        let v = self.overlay
        UIView.animateWithDuration(0.1,
            animations: {
                v.alpha = 0
            },
            completion: { (_) -> Void in
                v.removeFromSuperview()
        })
    }
}