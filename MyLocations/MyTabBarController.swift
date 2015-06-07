//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by PC-LILY on 15/6/7.
//  Copyright (c) 2015年 PC-LILY. All rights reserved.
//

import Foundation
import UIKit

class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}