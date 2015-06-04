//
//  FirstViewController.swift
//  MyLocations
//
//  Created by PC-LILY on 15/5/24.
//  Copyright (c) 2015年 PC-LILY. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController,CLLocationManagerDelegate {

    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getLocationButton: UIButton!
    
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    var placeMark:CLPlacemark?
    var location:CLLocation?
    var performingReverseGeocoding = false
    var updatingLocation = false
    var lastLocationError:NSError?
    var lastGeocodingError:NSError?
    var timer:NSTimer?
    var managedObjectContext:NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
       
    }

    @IBAction func getLocation(sender: AnyObject) {
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined{
            locationManager.requestWhenInUseAuthorization()
        }
        if authStatus == .Denied || authStatus == .Restricted{
            showLocationServiceDeniedAlert()
            return
        }
        if updatingLocation {
            stopLocationManager()
        }else{
            location = nil
            lastLocationError = nil
            placeMark = nil
            lastGeocodingError = nil
            startLocationManager()
 
        }
        updateLabels()
        configureGetButton()

    }
    
    func showLocationServiceDeniedAlert(){
        let alert = UIAlertController(title: "Location Service Disabled", message: "Please enable location services for this app in Settings", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler:nil)
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateLabels(){
        if let location = location{
            latitudeLabel.text = String(format: "%.8f",location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            if let placemark = placeMark{
                addressLabel.text = stringFromPlacemark(placeMark!)
            }else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            }else if lastGeocodingError != nil{
                addressLabel.text = "Error Finding Address"
            }else{
                addressLabel.text = "No Address Found"
            }
        }else{
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            var statusMessage:String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain &&
                    error.code == CLError.Denied.rawValue{
                        statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error Getting Location"
                }
            }else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            }else if updatingLocation {
                statusMessage = "Searching..."
            }else{
                statusMessage = "Tap ‘Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager(){
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func configureGetButton(){
        if updatingLocation {
            getLocationButton.setTitle("Stop", forState: .Normal)
        }else{
            getLocationButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    func stringFromPlacemark(placemark:CLPlacemark) -> String{
        var address: String = ""
        if let area = placemark.administrativeArea{
            address += "\(area) "
        }
        if let locality = placemark.locality{
            address += "\(locality)\n"
        }
        if let thoroughfare = placemark.thoroughfare{
            address += "\(thoroughfare) "
        }
        if let subThoroughfare = placemark.subThoroughfare{
            address += "\(subThoroughfare) \n"
        }
        if let postCode = placemark.postalCode{
            address += "\(postCode)"
        }
        return address
    }
    
    func didTimeOut(){
        println("***Time out")
        
        if location == nil{
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationErrorDomain", code: 1, userInfo: nil)
            updateLabels()
            configureGetButton()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placeMark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    //MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("didFailWithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue{
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newLocation = locations.last as! CLLocation
        println("didUpdateLocations \(newLocation)")
    
        if newLocation.timestamp.timeIntervalSinceNow < -5{
            return
        }
        if newLocation.horizontalAccuracy < 0{
            return
        }
        var distance = CLLocationDistance(DBL_MAX)
        if let  location = location{
            distance = newLocation.distanceFromLocation(location)
        }
        if location == nil || location?.horizontalAccuracy > newLocation.horizontalAccuracy{
            lastLocationError = nil
            location = newLocation
            updateLabels()
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                println("***We're done!")
                stopLocationManager()
                configureGetButton()
                if distance > 0{
                    performingReverseGeocoding = false
                }
            }
            if !performingReverseGeocoding{
                println("***Going to geocode")
                performingReverseGeocoding = true
                geocoder.reverseGeocodeLocation(location, completionHandler: {
                    placemarks,error in
                    println("***Found placemarks:\(placemarks),error:\(error)")
                    self.lastLocationError = error
                    if error == nil && !placemarks.isEmpty{
                        self.placeMark = placemarks.last as? CLPlacemark
                    }else {
                        self.placeMark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
        }else if distance < 1.0{
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            if timeInterval > 10 {
                println("***Force Done!")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }


}

