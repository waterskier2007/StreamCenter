//
//  ViewController.swift
//  TestTVApp
//
//  Created by Olivier Boucher on 2015-09-13.
//  Copyright © 2015 Rivus Media Inc. All rights reserved.
//

import UIKit

class GamesViewController : LoadingViewController {
    
    private let NUM_COLUMNS = 5;
    private let ITEMS_INSETS_X : CGFloat = 25;
    private let ITEMS_INSETS_Y : CGFloat = 40;
    private let TOP_BAR_HEIGHT : CGFloat = 100;
    
    private var topBar : TopBarView?
    private var collectionView : UICollectionView?
    private var games : Array<TwitchGame>?
    
    convenience init(){
        self.init(nibName: nil, bundle: nil);
    }
    
    //We want the latest data to be fetched each time
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if(self.collectionView == nil){
            self.displayLoadingView()
        }
        
        TwitchApi.getTopGamesWithOffset(0, limit: 17) {
            (games, error) in
            
            if(error != nil || games == nil){
                dispatch_async(dispatch_get_main_queue(),{
                    if(self.errorView == nil){
                        self.removeLoadingView()
                        self.displayErrorView("Error loading game list.\nPlease check your internet connection.")
                    }
                });
            }
            else {
                self.games = games!;
                dispatch_async(dispatch_get_main_queue(),{
                    if((self.topBar == nil) || !(self.topBar!.isDescendantOfView(self.view))) {
                        let topBarBounds = CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y, width: self.view.bounds.size.width, height: self.TOP_BAR_HEIGHT)
                        self.topBar = TopBarView(frame: topBarBounds, withMainTitle: "Top Games")
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
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func displayCollectionView() {
        
        if((collectionView == nil) || !(collectionView!.isDescendantOfView(self.view))) {
            let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout();
            layout.scrollDirection = UICollectionViewScrollDirection.Vertical;
            layout.minimumInteritemSpacing = 10;
            layout.minimumLineSpacing = 10;
            
            let collectionViewBounds = CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            
            self.collectionView = UICollectionView(frame: collectionViewBounds, collectionViewLayout: layout);
            
            self.collectionView!.registerClass(GameCellView.classForCoder(), forCellWithReuseIdentifier: GameCellView.cellIdentifier);
            self.collectionView!.dataSource = self;
            self.collectionView!.delegate = self;
            self.collectionView!.contentInset = UIEdgeInsets(top: ITEMS_INSETS_Y + 10, left: ITEMS_INSETS_X, bottom: ITEMS_INSETS_Y, right: ITEMS_INSETS_X)
            
            self.view.addSubview(self.collectionView!)
            self.view.bringSubviewToFront(self.topBar!)
        }
        else {
            collectionView?.reloadData()
        }
    }
}

extension GamesViewController : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedGame = games![(indexPath.section * NUM_COLUMNS) +  indexPath.row]
        let streamsViewController = StreamsViewController(game: selectedGame)
        
        self.presentViewController(streamsViewController, animated: true, completion: nil)
    }
}

extension GamesViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            let width = self.view.bounds.width / CGFloat(NUM_COLUMNS) - CGFloat(ITEMS_INSETS_X * 2);
            let height = (width * 1.39705882353) + 80;
            
            return CGSize(width: width, height: height)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            let topInset = (section == 0) ? TOP_BAR_HEIGHT : ITEMS_INSETS_X
            return UIEdgeInsets(top: topInset, left: ITEMS_INSETS_X, bottom: ITEMS_INSETS_Y, right: ITEMS_INSETS_X);
    }
}

extension GamesViewController : UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        let test = Double(games!.count) / Double(NUM_COLUMNS);
        let test2 = ceil(test);
        
        return Int(test2);
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if((section+1) * NUM_COLUMNS <= games!.count){
            //NSLog("count for section #%d : %d", section, NUM_COLUMNS);
            return NUM_COLUMNS;
        }
        else {
            //NSLog("count for section #%d : %d", section, games!.count - ((section) * NUM_COLUMNS));
            return games!.count - ((section) * NUM_COLUMNS)
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell : GameCellView = collectionView.dequeueReusableCellWithReuseIdentifier(GameCellView.cellIdentifier, forIndexPath: indexPath) as! GameCellView;
        //NSLog("Indexpath => section:%d row:%d", indexPath.section, indexPath.row);
        cell.setGame(games![(indexPath.section * NUM_COLUMNS) +  indexPath.row]);
        return cell;
    }
}

