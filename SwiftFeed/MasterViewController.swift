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


        getEntries { result in
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


    enum Result {
        case Success(Json)
        case Error(NSError)
    }

    func getEntries(completion: (Result) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: url));
        request.HTTPMethod = "GET"

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data, request, error) -> Void in
            if (error != nil) {
                completion(.Error(error))
                return
            }

            switch JsonParser.parse(data) {
            case .Success(let json):
                completion(.Success(json))
            case .Error(let error):
                NSLog("json: %@", NSString(data: data, encoding: NSUTF8StringEncoding));
                NSLog("json parse error: %@", error.description)
                completion(.Error(NSError(domain: "SwiftFeed.JsonParseError",
                    code: 100,
                    userInfo: ["parseError": error])))
            }
        }
        task.resume()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = entries[indexPath.row]
            //(segue.destinationViewController as DetailViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("count: %d", entries.count)
        return entries.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let object = entries[indexPath.row]
        cell.textLabel!.text = object["title"].stringValue
        return cell
    }

}

