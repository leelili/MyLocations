//
//  LocationCell.swift
//  MyLocations
//
//  Created by PC-LILY on 15/6/4.
//  Copyright (c) 2015年 PC-LILY. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.blackColor()
        descriptionLabel.textColor = UIColor.whiteColor()
        descriptionLabel.highlightedTextColor = descriptionLabel.textColor
        addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        addressLabel.highlightedTextColor = addressLabel.textColor
        let selectView = UIView(frame: CGRect.zeroRect)
        selectView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        selectedBackgroundView = selectView
        photoImageView.layer.cornerRadius = photoImageView.bounds.size.width / 2
        photoImageView.clipsToBounds = true
        separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let superView = superview {
            descriptionLabel.frame.size.width = superview!.frame.size.width - descriptionLabel.frame.origin.x - 10
            addressLabel.frame.size.width = superview!.frame.size.width - addressLabel.frame.origin.x - 10
        }
    }
    func configureForLocation(location:Location) {
        if location.locationDescription.isEmpty {
            descriptionLabel.text = "(No Description)"
        } else {
            descriptionLabel.text = location.locationDescription
        }
        
        if let placemark = location.placemark {
            var text = ""
            text.addText(placemark.locality)
            text.addText(placemark.thoroughfare, withSeparator: ",")
            text.addText(placemark.subThoroughfare, withSeparator: " ")
            addressLabel.text = text
        } else {
            addressLabel.text = String(format: "Lat:%.8f, Long:%.8f", location.latitude,location.longitude)
        }
        photoImageView.image = imageForLocation(location)
    }
    
    func imageForLocation(location:Location) -> UIImage {
        if location.hasPhoto {
            if let image = location.photoImage {
                return image.resizedImageWithBounds(CGSize(width: 52, height: 52))
            }
        }
        return UIImage(named: "No Photo")!
    }

}
