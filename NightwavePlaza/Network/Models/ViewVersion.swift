//
//  ViewVersion.swift
//  NightwavePlaza
//
//  Created by Jonathan.Haubrich on 2024-06-26.
//  Copyright © 2024 Aleksey Garbarev. All rights reserved.
//

import Foundation

class ViewVersion: Codable {
    // view_version
    var version         : Int
    // android_min_ver
    var androidMinVer   : Int
    // ios_min_ver
    var iosMinVer       : Int
    // view_src
    var source          : String
    
    enum CodingKeys: String, CodingKey {
        case version          = "view_version"
        case androidMinVer    = "android_min_ver"
        case iosMinVer        = "ios_min_ver"
        case source           = "view_src"
    }
}
