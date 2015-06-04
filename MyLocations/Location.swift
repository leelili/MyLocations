//
//  Location.swift
//  MyLocations
//
//  Created by PC-LILY on 15/6/4.
//  Copyright (c) 2015年 PC-LILY. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class Location: NSManagedObject {

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var date: NSDate
    @NSManaged var locationDescription: String
    @NSManaged var category: String
    @NSManaged var placemark: CLPlacemark?

}
