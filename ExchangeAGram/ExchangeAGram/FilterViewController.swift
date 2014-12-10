//
//  FilterViewController.swift
//  Copyright (c) 2014 Angela Liu. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var thisFeedItem: FeedItem!
    var collectionView: UICollectionView!
    let kIntensity = 0.7 //constant for intensity level
    var context:CIContext = CIContext(options: nil)
    var filters:[CIFilter] = []
    let placeHolderImage = UIImage(named: "Placeholder")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 150.0, height: 150.0)
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.whiteColor()
        //register the class
        collectionView.registerClass(FilterCell.self, forCellWithReuseIdentifier: "MyCell")
        
        self.view.addSubview(collectionView)
        
        filters = photoFilters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:FilterCell = collectionView.dequeueReusableCellWithReuseIdentifier("MyCell", forIndexPath: indexPath) as FilterCell
        
        if cell.imageView.image == nil {
            cell.imageView.image = placeHolderImage
            
            //Create a queue for multi-threading to prevent lagging
            let filterQueue:dispatch_queue_t = dispatch_queue_create("filter queue", nil)
            
            //run on another thread
            dispatch_async(filterQueue, { () -> Void in
                let filterImage = self.filteredImageFromImage(self.thisFeedItem.thumbnail, filter: self.filters[indexPath.row])
                
                //go back to main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    cell.imageView.image = filterImage
                })
            })
        }
        return cell
    }
    
    //UICollectionViewDelagate 
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        createUIAlertController(indexPath)
    }

    
    //Helper Function for array of possible filters
    func photoFilters () -> [CIFilter] {
        let blur = CIFilter(name: "CIGaussianBlur")
        let instant = CIFilter(name: "CIPhotoEffectInstant")
        let noir = CIFilter(name: "CIPhotoEffectNoir")
        let transfer = CIFilter(name: "CIPhotoEffectTransfer")
        let unsharpen = CIFilter(name: "CIUnsharpMask")
        let monochrome = CIFilter(name: "CIColorMonochrome")
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls.setValue(0.5, forKey: kCIInputSaturationKey)
        //0.5 is for saturation value
        
        let sepia = CIFilter(name: "CISepiaTone")
        sepia.setValue(kIntensity, forKey: kCIInputIntensityKey)
        
        let colorClamp = CIFilter(name: "CIColorClamp")
        colorClamp.setValue(CIVector(x: 0.9, y: 0.9, z: 0.9, w: 0.9), forKey: "inputMaxComponents")
        colorClamp.setValue(CIVector(x: 0.2, y: 0.2, z: 0.2, w: 0.2), forKey: "inputMinComponents")
        
        //composite filters
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite.setValue(sepia.outputImage, forKey: kCIInputImageKey)
        
        let vignette = CIFilter(name: "CIVignette")
        vignette.setValue(composite.outputImage, forKey: kCIInputImageKey)
        
        vignette.setValue(kIntensity * 2, forKey: kCIInputIntensityKey)
        vignette.setValue(kIntensity * 30, forKey: kCIInputRadiusKey)
        
        //add all filters into an array
        return [blur, instant, noir, transfer, unsharpen, monochrome, colorControls, sepia, colorClamp, composite, vignette]
    }
    
    func filteredImageFromImage (imageData: NSData, filter: CIFilter) -> UIImage {
        
        let unfilteredImage = CIImage(data: imageData)
        filter.setValue(unfilteredImage, forKey: kCIInputImageKey)
        let filteredImage:CIImage = filter.outputImage
        
        let extent = filteredImage.extent()
        let cgImage:CGImageRef = context.createCGImage(filteredImage, fromRect: extent)
        
        let finalImage = UIImage(CGImage: cgImage)
        
        return finalImage!
    }

    //Helper Functions for UIAlertController
    func createUIAlertController (indexPath: NSIndexPath) {
        let alert = UIAlertController(title: "Photo Options", message: "What would you like to do with the photo?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Add a caption!"
            textField.secureTextEntry = false
        }
        
        let textField = alert.textFields![0] as UITextField
        
        //Option to only save the filtered photo to collection without posting
        let saveFilterAction = UIAlertAction(title: "Save Filter without posting on Facebook", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            var text = textField.text
            self.saveFilterToCoreData(indexPath, caption:text)
        }
        alert.addAction(saveFilterAction)
        
        //Option to post to Facebook
        let photoAction = UIAlertAction(title: "Post Photo to Facebook", style: UIAlertActionStyle.Destructive) { (UIAlertAction) -> Void in
            
            self.self.shareToFacebook(indexPath)
            var text = textField.text
            self.saveFilterToCoreData(indexPath, caption: text)
            
        }
        alert.addAction(photoAction)

        
        //Option to cancel and select another filter
        let cancelAction = UIAlertAction(title: "Select another Filter", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
        }
        alert.addAction(cancelAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //Helper function to save the filter
    func saveFilterToCoreData (indexPath: NSIndexPath, caption: String) {
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        let imageData = UIImageJPEGRepresentation(filterImage, 1.0)
        self.thisFeedItem.image = imageData
        let thumbNailData = UIImageJPEGRepresentation(filterImage, 0.1)
        self.thisFeedItem.thumbnail = thumbNailData
        self.thisFeedItem.caption = caption
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //Helper function to post to facebooks
    func shareToFacebook (indexPath: NSIndexPath) {
        let filterImage = self.filteredImageFromImage(self.thisFeedItem.image, filter: self.filters[indexPath.row])
        
        let photos:NSArray = [filterImage]
        var params = FBPhotoParams()
        params.photos = photos
        
        FBDialogs.presentShareDialogWithPhotoParams(params, clientState: nil) { (call, result, error) -> Void in
            if (result? != nil) {
                println(result)
            } else {
                println(error)
            }
        }
    }
}




