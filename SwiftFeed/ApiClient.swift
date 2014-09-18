//
//  ApiClient.swift
//  JsonSerializer
//
//  Created by Fuji Goro on 2014/09/19.
//  Copyright (c) 2014年 Fuji Goro. All rights reserved.
//

import Foundation
import JsonSerializer

class ApiClient {

    enum Result {
        case Success(Json)
        case Error(NSError)
    }

    func get(url: NSURL, completion: (Result) -> Void) {
        let request = NSMutableURLRequest(URL: url);
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

}