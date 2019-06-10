//
//  Keys.swift
//  SiaUs
//
//  Created by Michal Sefl on 09/06/2019.
//  Copyright © 2019 Michal Sefl. All rights reserved.
//

import Foundation

struct Keys {
    struct UserDefaults {
        static let contract = "contract"
        static let shardServer = "shardServer"
        static let fileName = "fileName"
    }
}

struct Contracts {
    static let testContract: String? = nil // enter your contract data here as "string" if you want it to be pre-filled, else keep it nil
}
