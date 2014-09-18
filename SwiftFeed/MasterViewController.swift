//
//  MasterViewController.swift
//  SwiftFeed
//
//  Created by Fuji Goro on 2014/09/17.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

import UIKit
import JsonSerializer

class MasterViewController: UITableViewController {

    let url = "http://api.stackexchange.com/2.2/tags/swift/faq?site=stackoverflow.com"

    var entries: [Json] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        ApiClient().get(NSURL(string: url)) { result in
            switch result {
            case .Success(let json):
                NSLog("quota max: %@", json["quota_max"].stringValue)
                self.entries = json["items"].arrayValue
                self.tableView.reloadData()
            case .Error(let error):
                NSLog("Error: %@", error)
            }
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = entries[indexPath.row]
                (segue.destinationViewController as DetailViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let object = entries[indexPath.row]
        cell.textLabel!.text = object["title"].stringValue
        return cell
    }

}

