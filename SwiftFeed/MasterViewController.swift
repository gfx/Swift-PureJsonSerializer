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

    let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.dateFormat = "yyyy/M/d HH:mm:dd"
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()


        let indicator = OverlayIndicator()

        ApiClient().get(NSURL(string: url)!) { result in
            indicator

            switch result {
            case .Success(let json):
                NSLog("quota max: %@", json["quota_max"]?.string ?? "")
                self.entries = json["items"]?.array ?? []
                self.tableView.reloadData()
            case .Error(let error):
                print("Error: \(error)")
            }
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard
            segue.identifier == "showDetail",
            let indexPath = self.tableView.indexPathForSelectedRow,
            let detailViewController = segue.destinationViewController as? DetailViewController
            where indexPath.row < entries.count
            else { return }
        
        let object = entries[indexPath.row]
        detailViewController.detailItem = object
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let object = entries[indexPath.row]
        cell.textLabel?.text = object["title"]?.string

        if let timeInterval = object["last_activity_date"]?.doubleValue {
            let date = NSDate(timeIntervalSince1970: timeInterval)
            cell.detailTextLabel?.text = dateFormatter.stringFromDate(date)
        }
        return cell
    }
}

