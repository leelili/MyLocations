//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by PC-LILY on 15/5/27.
//  Copyright (c) 2015年 PC-LILY. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter:NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    println("creat dateformatter")
    return formatter
}()

class LocationDetailsViewController: UITableViewController {

    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark:CLPlacemark?
    var descriptionText = ""
    var categoryName = "No Category"
    var date = NSDate()
    var managedObjectContext:NSManagedObjectContext!
    var observer: AnyObject!
    var image: UIImage?
    var locationToEdit:Location?{
        didSet{
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            title = "Edit Location"
            if location.hasPhoto {
                if let image = location.photoImage {
                    showImage(image)
                }
            }
        }
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark {
            addressLabel.text = stringFromPlacemark(placemark)
        } else {
            addressLabel.text = "No Address Found"
        }
        
        dateLabel.text = formateDate(date)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard:"))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        listenForBackgroundNotification()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        descriptionTextView.frame.size.width = view.frame.size.width - 30
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        println("***********deinit")
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
    
    //MARK: - Function
    
    func stringFromPlacemark(placemark:CLPlacemark) -> String {
        return
         "\(placemark.subThoroughfare) \(placemark.thoroughfare), " +
         "\(placemark.location), " +
         "\(placemark.administrativeArea) \(placemark.postalCode), " +
         "\(placemark.country)"
    }
    
    func formateDate(date:NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    func hideKeyboard(gestureRecognizer:UIGestureRecognizer) {
        let point = gestureRecognizer.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(point)
        if indexPath != nil && indexPath?.section == 0 && indexPath?.row == 0 {
            return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func showImage(image:UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.hidden = true
    }
    
    func listenForBackgroundNotification() {
        observer =  NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()){
            [weak self] notification in
            if let strongSelf = self {
                if strongSelf.presentedViewController != nil {
                    strongSelf.dismissViewControllerAnimated(true, completion: nil)
                }
                strongSelf.descriptionTextView.resignFirstResponder()
            }
            println(self)
        }
    }
   
    //MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section,indexPath.row) {
        case (0,0):
            return 88
        case (1,_):
            return imageView.hidden ? 44 : 280
        case (2,2):
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 1000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        default:
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 1 && indexPath.row == 0 {
//            takePhotoWithCamera()
//            choosePhotoFromLibrary()
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            pickPhoto()
        }
    }
    
    //MARK: - IBAction
    
    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func Done(sender: AnyObject) {
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        
        var location:Location
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else{
            hudView.text = "Tagged"
            location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
            location.photoID = nil
        }
        
        location.locationDescription = descriptionText
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        if let image = image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID()
            }
            let data = UIImageJPEGRepresentation(image, 0.5)
            var error:NSError?
            if !data.writeToFile(location.photoPath, options: .DataWritingAtomic, error: &error) {
                println("Error writing file: \(error)")
            }
        }
        
        var error:NSError?
        if !managedObjectContext.save(&error) {
            fatalCoreDataError(error)
            return
        }
        
        afterDelay(0.6){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func categoryPickerDidCategoty(segue:UIStoryboardSegue) {
        let controller = segue.sourceViewController as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "PickCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }


}

extension LocationDetailsViewController:UITextViewDelegate{
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        descriptionText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        descriptionText = textView.text
    }
}

extension LocationDetailsViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "拍摄", style: UIAlertActionStyle.Default, handler: {
            _ in self.takePhotoWithCamera()
        })
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title: "从相册选择", style: .Default, handler:{
            _ in self.choosePhotoFromLibrary()
        })
        alertController.addAction(chooseFromLibraryAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func takePhotoWithCamera() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        image = info[UIImagePickerControllerEditedImage] as! UIImage?
        if let image = image {
            showImage(image)
        }
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
