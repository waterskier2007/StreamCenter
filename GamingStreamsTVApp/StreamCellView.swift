//
//  StreamCellView.swift
//  GamingStreamsTVApp
//
//  Created by Olivier Boucher on 2015-09-14.
//  Copyright © 2015 Rivus Media Inc. All rights reserved.
//
import UIKit
import Foundation

class StreamCellView : UICollectionViewCell {
    static let cellIdentifier : String = "kStreamCellView"
    
    private var _stream : TwitchStream?
    private var _image : UIImage?
    private var _imageView : UIImageView?
    private var _activityIndicator : UIActivityIndicatorView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self._imageView = UIImageView(frame: self.bounds)
        self._imageView!.adjustsImageWhenAncestorFocused = true
        self._imageView!.layer.cornerRadius = 10
        self._imageView!.backgroundColor = UIColor(white: 0.25, alpha: 0.7)
        
        self._activityIndicator = UIActivityIndicatorView(frame: self.bounds)
        self._activityIndicator?.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        self._activityIndicator?.startAnimating()
        
        self._imageView?.addSubview(self._activityIndicator!)
        self.addSubview(self._imageView!);
    }
    convenience init() {
        self.init()
    }
    
    convenience init(stream : TwitchStream) {
        self.init();
        _stream = stream
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setStream(stream : TwitchStream) {
        self._stream = stream
        self.assignImageAndDisplay()
    }
    
    private func assignImageAndDisplay() {
        
        self.downloadImageWithSize(self.frame.size) {
            (image, error) in
            
            if(error != nil || image == nil) {
                //TODO : Set error image, not available
                self._image = nil;
            }
            else {
                self._image = image!;
            }
            
            dispatch_async(dispatch_get_main_queue(),{
                if((self._activityIndicator != nil) && (self._activityIndicator!.isDescendantOfView(self._imageView!))) {
                    self._activityIndicator?.removeFromSuperview()
                    self._activityIndicator = nil
                }
                self._imageView!.image = self._image;
            })
            
        }
    }
    
    private func downloadImageWithSize(size : CGSize, completionHandler : (image : UIImage?, error : NSError?) -> ()) {
        
        if let imgUrlTemplate = _stream?.getPreviews()["template"] as? String {
            if let imgUrlString : String? = imgUrlTemplate.stringByReplacingOccurrencesOfString("{width}", withString: "\(Int(size.width))")
                .stringByReplacingOccurrencesOfString("{height}", withString: "\(Int(size.height))") {
                    //Now that we have our correct template, we download the image
                    let imgUrl = NSURL(string: imgUrlString!);
                    let task = NSURLSession.sharedSession().dataTaskWithURL(imgUrl!) {(data, response, error) in
                        //We check for errors
                        if(error != nil){
                            completionHandler(image : nil, error : error);
                            return
                        }
                        let image = UIImage(data: data!);
                        completionHandler(image: image, error: nil);
                    };
                    task.resume();
            }
        }
    }

}