//
//  String+AddText.swift
//  MyLocations
//
//  Created by PC-LILY on 15/6/7.
//  Copyright (c) 2015年 PC-LILY. All rights reserved.
//

import Foundation

extension String {
    mutating func addText(text:String?,withSeparator separator:String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}