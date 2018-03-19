//
//  extensions.swift
//
//  Created by John Borkowski on 9/26/17.
//  Copyright © 2017 John Borkowski. All rights reserved.
//

import UIKit


extension NSDictionary {
    func stringFromHttpParameters() -> String {
        let parameterArray = self.map { (key, value) -> String in
            let percentEscapedKey: String = (key as! String)
            let percentEscapedValue: Any = (value)
            if (percentEscapedValue as? String) != nil {
                return "\"\(percentEscapedKey)\":\"\(percentEscapedValue)\""
            } else if (percentEscapedValue as? NSArray) != nil {
                var arrayString: String = "["
                var mutablePercentEscapedValue: [String] = []
                for element in percentEscapedValue as! NSArray {
                    if element as? NSDictionary != nil {
                        let dict: NSDictionary = element as! NSDictionary
                        mutablePercentEscapedValue.append("\(dict.stringFromHttpParameters())")
                        
                    } else {
                        mutablePercentEscapedValue.append("\"\(element)\"")
                    }
                }
                arrayString += (mutablePercentEscapedValue as NSArray).componentsJoined(by: ",")
                arrayString += "]"
                return "\"\(percentEscapedKey)\":\(arrayString)"
            } else {
                return "\"\(percentEscapedKey)\":\(percentEscapedValue)"
            }
        }
        return "{" + parameterArray.joined(separator: ",") + "}"
    }
    
}
