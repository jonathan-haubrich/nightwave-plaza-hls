//
//  RequestToCheckForUpdate.swift
//  NightwavePlaza
//
//  Created by Jonathan.Haubrich on 2024-06-26.
//  Copyright © 2024 Aleksey Garbarev. All rights reserved.
//

import Foundation

class RequestToCheckForUpdate: NSObject, TRCRequest {
    
    func method() -> String! {
        return TRCRequestMethodGet;
    }
    
    func path() -> String! {
        if let currentProjectVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "versions?app_ver=\(currentProjectVersion)&platform=ios"
        }
        return "";
    }
    
}
