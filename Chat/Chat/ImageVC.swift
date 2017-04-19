//
//  MediaVC.swift
//  Chat
//
//  Created by Maor Shams on 15/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit

class ImageVC: UIViewController, UIScrollViewDelegate {
    
    var userSentImage: UIImage? = nil
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 10.0 //default is 1.0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
    }
    
    func setup(image : UIImage? = nil, message : MSMessage){
        if let image = image{
            self.image = image
        }
        self.title = formatDate(date: message.date)
    }
    
    func formatDate(date : Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        return dateFormatter.string(from: date)
    }
    
    // Zoom in imageView
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // programmatically create UIImageView with
    // default values (0,0,0,0)
    private var imageView = UIImageView()
    
    // computed var, when setting the image
    // change the size of UIImageView to fit the image
    // change the content size of scrollView to fit the image
    private var image : UIImage? {
        get{
            return imageView.image
        }
        set{
            imageView.image = newValue
            imageView.sizeToFit()
            // optional because scrollview is outlet, avoid crash
            // if image setting happend when prepering
            scrollView?.contentSize = imageView.frame.size

        }
    }
}
