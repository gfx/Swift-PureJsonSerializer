//
//  DetailViewController.swift
//  SwiftFeed
//
//  Created by Fuji Goro on 2014/09/17.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

import UIKit
import JsonSerializer

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    var detailItem: Json!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureView()
    }

    func configureView() {
        let detail = self.detailItem
        let label = self.detailDescriptionLabel
        label.text = detail.debugDescription
    }
}

