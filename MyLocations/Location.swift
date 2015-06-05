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
import MapKit
class Location: NSManagedObject,MKAnnotation{

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var date: NSDate
    @NSManaged var locationDescription: String
    @NSManaged var category: String
    @NSManaged var placemark: CLPlacemark?

    var coordinate:CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title:String! {
        if locationDescription.isEmpty {
            return "(No Description)"
        } else {
            return locationDescription
        }
    }
    
    var subtitle:String! {
        return category
    }
}
