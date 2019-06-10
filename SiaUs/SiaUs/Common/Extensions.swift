//
//  Extensions.swift
//  Sia Companion
//
//  Created by Michal Sefl on 20/11/2018.
//  Copyright © 2018 Michal Sefl. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    struct Sia {
        static var text: UIColor  { return UIColor(red: 56/255, green: 56/255, blue: 56/255, alpha: 1) }
        static var green: UIColor { return UIColor(red: 30/255, green: 214/255, blue: 96/255, alpha: 1) }
        static var red: UIColor { return UIColor.red }
    }
    
}

extension Data {
    
    // FROM
    // http://stackoverflow.com/a/40278391:
    init?(fromHexEncodedString string: String) {
        
        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(u: UInt16) -> UInt8? {
            switch(u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }
        
        self.init(capacity: string.utf16.count/2)
        var even = true
        var byte: UInt8 = 0
        for c in string.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }
}
