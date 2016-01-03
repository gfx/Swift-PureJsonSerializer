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
        case Error(ErrorType)
    }

    func get(url: NSURL, completion: (Result) -> Void) {
        let request = NSMutableURLRequest(URL: url);
        request.HTTPMethod = "GET"

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { (data, request, error) -> Void in
            if let err = error {
                completion(.Error(err))
                return
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                guard let data = data else { return }
                do {
                    let result = try Json.deserialize(data);
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(.Success(result))
                    }
                } catch {
                    completion(.Error(error))
                }
            }
        }
        task.resume()
    }

}