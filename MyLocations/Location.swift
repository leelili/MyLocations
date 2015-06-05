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
    @NSManaged var photoID:NSNumber?
    
    var hasPhoto: Bool {
        return photoID != nil
    }

    var photoPath: String {
        assert(photoID != nil, "No photo ID set")
        let fileName = "Photo-\(photoID!.integerValue).jpg"
        return applicationDocumentsDirectory.stringByAppendingPathComponent(fileName)
    }
    
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoPath)
    }
    
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
    
    class func nextPhotoID() -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let currentID = userDefaults.integerForKey("PhotoID")
        userDefaults.setInteger(currentID + 1, forKey: "PhotoID")
        userDefaults.synchronize()
        return currentID
    }
    
    func removePhotoFile() {
        if hasPhoto {
            let path = photoPath
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(path) {
                var error: NSError?
                if !fileManager.removeItemAtPath(path, error: &error) {
                    println("Error remving file: \(error)")
                }
            }
        }
    }
}
