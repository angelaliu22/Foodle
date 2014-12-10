//
//  FeedViewController.swift
//  Copyright (c) 2014 Angela Liu. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import MapKit


class FeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
                            UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                            CLLocationManagerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    //grab an array of feed items 
    var feedArray: [AnyObject] = []
    
    var locationManager: CLLocationManager!
    
    //runs only once when the feed loads the first time
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set Background color of feed 
        //let backgroundImage = UIImage(named: "OceanBackGround")
        //self.view.backgroundColor = UIColor(patternImage: backgroundImage!)

        // Do any additional setup after loading the view.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization() //Ask the user if we can use their location
        
        //Starting location tracker
        locationManager.distanceFilter = 100.0
        locationManager.startUpdatingLocation()

    }

    //refreshes the feed everytime this view appears
    override func viewDidAppear(animated: Bool) {
        let request = NSFetchRequest(entityName: "FeedItem")
        let appDelegate:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        let context:NSManagedObjectContext = appDelegate.managedObjectContext!
        feedArray = context.executeFetchRequest(request, error: nil)!
        collectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func profileTapped(sender: UIBarButtonItem) {
         self.performSegueWithIdentifier("profileSegue", sender: nil)
    }
    
    
    @IBAction func snapBarButtonItemTapped(sender: UIBarButtonItem) {
        //if the camera is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            //access pictures and videos library
            var cameraController = UIImagePickerController()
            cameraController.delegate = self
            //set the source to camera
            cameraController.sourceType = UIImagePickerControllerSourceType.Camera
            
            //setting up the media type as an image
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            cameraController.mediaTypes = mediaTypes
            cameraController.allowsEditing = false
            
            //show camera the screen
            self.presentViewController(cameraController, animated: true, completion: nil)
        }
        
        //if camera is not available
        else if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            
            var photoLibraryController = UIImagePickerController()
            photoLibraryController.delegate = self
            //set source to phone's photo library
            photoLibraryController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            
            let mediaTypes:[AnyObject] = [kUTTypeImage]
            photoLibraryController.mediaTypes = mediaTypes
            photoLibraryController.allowsEditing = false
            
            //show library on screen
            self.presentViewController(photoLibraryController, animated: true, completion: nil)
        }
        
        //both camera and libaray are unavilable
        else {
            //just do a print statement/alert on the screen
            var alertController = UIAlertController(title: "Alert", message: "Your device does not support the camera or photo Library", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }

    }
    
    //Information about UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        //info is a dictionary which gives us the images
        let image = info[UIImagePickerControllerOriginalImage] as UIImage
        println(image)
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let thumbNailData = UIImageJPEGRepresentation(image, 0.1)
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
        let entityDescription = NSEntityDescription.entityForName("FeedItem", inManagedObjectContext: managedObjectContext!)
        let feedItem = FeedItem(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext!)
        
        //setup the variable for the feed items to be displayed
        let UUID = NSUUID().UUIDString
        feedItem.uniqueID = UUID
        
        feedItem.image = imageData
        feedItem.caption = "test caption"
        feedItem.thumbnail = thumbNailData
        
        feedItem.longitude = locationManager.location.coordinate.longitude
        feedItem.latitude = locationManager.location.coordinate.latitude
        
        feedItem.filtered = false
        
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
        
        //refresh collection
        feedArray.append(feedItem)
        self.collectionView.reloadData()

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //Information about UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView:UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedArray.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
         var cell:FeedCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as FeedCell
        
        let thisItem = feedArray[indexPath.row] as FeedItem
        
        cell.imageView.image = UIImage(data: thisItem.image)
        cell.captionLabel.text = thisItem.caption
        
        return cell
    }
    
    //Information about UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let thisItem = feedArray[indexPath.row] as FeedItem
        
        var filterVC = FilterViewController()
        filterVC.thisFeedItem = thisItem
        
        self.navigationController?.pushViewController(filterVC, animated: false)

    }
    
    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("locations = \(locations)")
    }
    
}
