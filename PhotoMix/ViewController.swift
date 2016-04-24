//
//  ViewController.swift
//  PhotoMix
//
//  Created by Chuang HsuanChih on 5/12/15.
//  Copyright (c) 2015 Hsuan-Chih Chuang. All rights reserved.
//

import UIKit

extension UIView {
    
    func toImage() -> UIImage {
        let imageSize = self.bounds.size
        UIGraphicsBeginImageContext(imageSize);
        self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var canvasButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    lazy var activityIndicatorView:UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(
            self.view.center.x,
            self.view.center.y,
            0,
            0))
        activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        return activityIndicatorView
    }()
    
    var unarchivedCanvas:NSArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: NSSelectorFromString("handleApplicationWillTerminateNotification:"),
            name: "ApplicationWillTerminateNotification",
            object: UIApplication.sharedApplication().delegate)
        
        self.unarchivedCanvas = DataManager.manager.unarchiveCanvas()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let unarchivedCanvas = self.unarchivedCanvas {
            for view in unarchivedCanvas as! [TouchView] {
                self.canvasView.addSubview(view)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UIImagePickerController delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        let touchView = TouchView(frame: self.getTouchViewFrame(image))
        touchView.center = self.canvasView.center
        
        let imageViewSize = self.getImageViewSize(image)
        let imageView = UIImageView(frame: CGRectMake(0, 0, imageViewSize.width, imageViewSize.height))
        imageView.center = CGPointMake(CGRectGetWidth(touchView.bounds)/2, CGRectGetHeight(touchView.bounds)/3)
        imageView.image = image
        touchView.addSubview(imageView)
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.canvasView.addSubview(touchView)
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo: UnsafePointer<()>) {
        if error != nil {
            
        }
        if self.activityIndicatorView.isAnimating() {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int_fast64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                self.dismissActivityIndicator()
            })
        }
    }
    
    
    // MARK: Notification handlers
    func handleApplicationWillTerminateNotification(notification: NSNotification) {
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: "ApplicationWillTerminateNotification",
            object: UIApplication.sharedApplication().delegate)
        
        // Archive the current canvas on application terminate if canvas is tainted
        let dataManager = DataManager.manager
        if self.canvasView.subviews.count > 0 {
            dataManager.archiveCanvas(self.canvasView)
        } else {
            dataManager.invalidateArchive()
        }
    }
    
    
    // MARK: Private utility methods
    private func clearCanvas() {
        
        for subview in self.canvasView.subviews {
            subview.removeFromSuperview()
        }
    }
    
    private func saveCanvasToPhotosAlbum() {
        self.launchActivityIndicator()
        let image = self.canvasView.toImage()
        UIImageWriteToSavedPhotosAlbum(image, self, NSSelectorFromString("image:didFinishSavingWithError:contextInfo:"), nil)
    }
    
    private func deletePhoto() {
        self.canvasView.subviews[self.canvasView.subviews.count-1].removeFromSuperview()
    }
    
    private func getImageViewSize(image: UIImage?)->CGSize {
        
        if image != nil {
            let longSide = CGRectGetWidth(self.view.bounds) - TouchView.horizontalMargin * 2
            if ( image!.size.width >= image!.size.height ) {
                return CGSizeMake(longSide, longSide * image!.size.height/image!.size.width)
            } else {
                return CGSizeMake(longSide * image!.size.width/image!.size.height, longSide)
            }
        }
        return CGSizeZero
    }
    
    private func getTouchViewFrame(image: UIImage?)->CGRect {
        
        if image != nil {
            let imageViewSize = self.getImageViewSize(image)
            if ( image!.size.width >= image!.size.height ) {
                return CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), imageViewSize.height + TouchView.verticalMargin * 2)
            }
            else {
                return CGRectMake(0, 0, imageViewSize.width + TouchView.verticalMargin * 2, CGRectGetWidth(self.view.bounds))
            }
        }
        return CGRectZero
    }
    
    private func launchActivityIndicator() {
        self.view.addSubview(self.activityIndicatorView)
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.activityIndicatorView.frame = self.view.bounds
            self.activityIndicatorView.startAnimating()
        })
    }
    
    private func dismissActivityIndicator() {
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.activityIndicatorView.stopAnimating()
            self.activityIndicatorView.frame = CGRectMake(
                self.view.center.x,
                self.view.center.y,
                0,
                0)
        })
        self.activityIndicatorView.removeFromSuperview()
    }
    
    
    
    // MARK: Button actions
    @IBAction func newCanvasButtonTapped(sender: UIButton) {
        
        let alertController = UIAlertController(
            title: "清空",
            message: "是否清空之前的所有的操作?",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addAction(
            UIAlertAction(
                title: "取消",
                style: UIAlertActionStyle.Cancel,
                handler: nil))
        
        alertController.addAction(
            UIAlertAction(
                title: "继续",
                style: UIAlertActionStyle.Default,
                handler: { (action:UIAlertAction) -> Void in
                    self.clearCanvas()
            }))
        
        self.presentViewController(alertController, animated:true, completion: nil)
    }
    
    @IBAction func photoButtonTapped(sender: UIButton) {
        
        let alertController = UIAlertController(
            title: nil,
            message: "从相机获取一个新的头像或者从相册中添加",
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        alertController.addAction(
            UIAlertAction(
                title: "照一个新头像",
                style: UIAlertActionStyle.Default,
                handler: { (action:UIAlertAction) -> Void in
                    
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
                        
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
                        imagePickerController.delegate = self
                        //允许照片可编辑
                        imagePickerController.allowsEditing = true
                        self.presentViewController(imagePickerController, animated: true, completion: nil)
                    }
                    else {
                        
                        let alertController = UIAlertController(
                            title: "错误",
                            message: "相机不可用",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
        }))
        
        alertController.addAction(
            UIAlertAction(
                title: "从相册中选择",
                style: UIAlertActionStyle.Default,
                handler: { (action:UIAlertAction) -> Void in
                    
                    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
                        
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
                        imagePickerController.delegate = self
                        self.presentViewController(imagePickerController, animated: true, completion: nil)
                    }
            
        }))
        
        alertController.addAction(
            UIAlertAction(
                title: "取消",
                style: UIAlertActionStyle.Cancel,
                handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(sender: UIButton) {
        
        if self.canvasView.subviews.count > 0 {
            
            let ac = UIAlertController(
                title: "是否保存?",
                message: nil,
                preferredStyle: UIAlertControllerStyle.Alert)
            
            ac.addAction(UIAlertAction(title: "确定",
                style: .Default)
                { (action: UIAlertAction) in
                    self.saveCanvasToPhotosAlbum()
                }
            )
            
            ac.addAction(UIAlertAction(title: "取消",
                style: .Cancel,
                handler: nil)
            )
            
            self.presentViewController(ac, animated: true, completion: nil)
            
        } else {
            
            let alertController = UIAlertController(
                title: "无图片",
                message: "没有可以保存的图片",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alertController.addAction(
                UIAlertAction(
                    title: "确定",
                    style: UIAlertActionStyle.Default,
                    handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }

    @IBAction func deleteButtonTapped(sender: UIButton) {
        
        if self.canvasView.subviews.count > 0 {

            let alertController = UIAlertController(
                title: "删除?",
                message: "上一张照片将会被删除",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            alertController.addAction(
                UIAlertAction(
                    title: "取消",
                    style: UIAlertActionStyle.Cancel,
                    handler: nil))
            
            alertController.addAction(
                UIAlertAction(
                    title: "继续",
                    style: UIAlertActionStyle.Default,
                    handler: { (action:UIAlertAction) -> Void in
                        self.deletePhoto()
                }))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let ac = UIAlertController(
                title: "没用可删除的图片",
                message: nil,
                preferredStyle: .Alert)
            
            ac.addAction(UIAlertAction(title: "关闭",
                style: .Cancel,
                handler: nil)
            )
            
            self.presentViewController(ac, animated: true, completion: nil)

        }
    }
}

