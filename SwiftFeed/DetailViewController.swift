//
//  DetailViewController.swift
//  SwiftFeed
//
//  Created by Fuji Goro on 2014/09/17.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

import UIKit
import JsonSerializer

class DetailViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!

    var detailItem: Json!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    func configureView() {
        title = detailItem["title"].stringValue

        let url = NSURL(string: detailItem["link"].stringValue)!
        let request = NSURLRequest(URL: url)

        webView.loadRequest(request)
        webView.delegate = self
    }

    var indicator: OverlayIndicator?
    func webViewDidStartLoad(webView: UIWebView) {
        indicator = OverlayIndicator()
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        indicator = nil
    }
}
