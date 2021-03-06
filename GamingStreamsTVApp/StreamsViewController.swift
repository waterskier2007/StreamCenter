//
//  StreamsViewController.swift
//  GamingStreamsTVApp
//
//  Created by Olivier Boucher on 2015-09-14.
//  Copyright © 2015 Rivus Media Inc. All rights reserved.
//
import UIKit
import Foundation


class StreamsViewController : LoadingViewController {
    
    private let NUM_COLUMNS = 3;
    private let ITEMS_INSETS_X : CGFloat = 45;
    private let ITEMS_INSETS_Y : CGFloat = 30;
    private let TOP_BAR_HEIGHT : CGFloat = 100;
    
    private var game : TwitchGame?
    private var topBar : TopBarView?
    private var collectionView : UICollectionView?;
    private var streams : Array<TwitchStream>?;
    
    convenience init(game : TwitchGame){
        self.init(nibName: nil, bundle: nil);
        self.game = game;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if(self.collectionView == nil){
           self.displayLoadingView()
        }
        
        TwitchApi.getTopStreamsForGameWithOffset(self.game!.name, offset: 0, limit: 20) {
            (streams, error) in
            
            if(error != nil || streams == nil){
                dispatch_async(dispatch_get_main_queue(),{
                    if(self.errorView == nil){
                        self.removeLoadingView()
                        self.displayErrorView("Error loading streams list.\nPlease check your internet connection.")
                    }
                });
            }
            else {
                self.streams = streams!
                dispatch_async(dispatch_get_main_queue(),{
                    if((self.topBar == nil) || !(self.topBar!.isDescendantOfView(self.view))) {
                        let topBarBounds = CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y, width: self.view.bounds.size.width, height: self.TOP_BAR_HEIGHT)
                        self.topBar = TopBarView(frame: topBarBounds, withMainTitle: "Live Streams - \(self.game!.name)", backButtonTitle : "Games") {
                            //This is the callback that gets called on back button exit
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                        self.topBar?.backgroundColor = UIColor.init(white: 0.5, alpha: 1)
                        
                        self.view.addSubview(self.topBar!)
                    }
                    self.removeLoadingView()
                    self.removeErrorView()
                    self.displayCollectionView();
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func displayCollectionView() {
        if((collectionView == nil) || !(collectionView!.isDescendantOfView(self.view))) {
            let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout();
            layout.scrollDirection = UICollectionViewScrollDirection.Vertical;
            layout.minimumInteritemSpacing = 10;
            layout.minimumLineSpacing = 10;
            
            self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout);
            
            self.collectionView!.registerClass(StreamCellView.classForCoder(), forCellWithReuseIdentifier: StreamCellView.cellIdentifier);
            self.collectionView!.dataSource = self;
            self.collectionView!.delegate = self;
            self.collectionView!.contentInset = UIEdgeInsets(top: ITEMS_INSETS_Y + 10, left: ITEMS_INSETS_X, bottom: ITEMS_INSETS_Y, right: ITEMS_INSETS_X)
            
            self.view.addSubview(self.collectionView!);
            self.view.bringSubviewToFront(self.topBar!)
        }
        else {
            self.collectionView!.reloadData()
        }
    }
}

extension StreamsViewController : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //TODO: get stream info and launch it
        let selectedStream = streams![(indexPath.section * NUM_COLUMNS) +  indexPath.row]
        let videoViewController = VideoViewController(stream: selectedStream)
        
        self.presentViewController(videoViewController, animated: true, completion: nil)
    }
}

extension StreamsViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            let width = self.view.bounds.width / CGFloat(NUM_COLUMNS) - CGFloat(ITEMS_INSETS_X * 2);
            let height = width / 1.777777777 + 80;
            
            return CGSize(width: width, height: height)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            let topInset = (section == 0) ? TOP_BAR_HEIGHT : ITEMS_INSETS_X
            return UIEdgeInsets(top: topInset, left: ITEMS_INSETS_X, bottom: ITEMS_INSETS_Y, right: ITEMS_INSETS_X);
    }
}

extension StreamsViewController : UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        let test = Double(streams!.count) / Double(NUM_COLUMNS);
        let test2 = ceil(test);
        
        return Int(test2);
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if((section+1) * NUM_COLUMNS <= streams!.count){
            //NSLog("count for section #%d : %d", section, NUM_COLUMNS);
            return NUM_COLUMNS;
        }
        else {
            //NSLog("count for section #%d : %d", section, games!.count - ((section) * NUM_COLUMNS));
            return streams!.count - ((section) * NUM_COLUMNS)
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell : StreamCellView = collectionView.dequeueReusableCellWithReuseIdentifier(StreamCellView.cellIdentifier, forIndexPath: indexPath) as! StreamCellView;
        //NSLog("Indexpath => section:%d row:%d", indexPath.section, indexPath.row);
        cell.setStream(streams![((indexPath.section * NUM_COLUMNS) +  indexPath.row)]);
        return cell;
    }
}