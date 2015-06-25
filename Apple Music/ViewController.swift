//
//  ViewController.swift
//  Apple Music
//
//  Created by Finn Gaida on 24.06.15.
//  Copyright (c) 2015 Finn Gaida. All rights reserved.
//

import UIKit

class Song {
    var title: String?
    var artist: String?
    var occasion: String?
    var date: NSDate?
    
    init(title: String?, artist: String?, occasion: String?, date: String?) {
        
        self.title = title ?? "No title availble"
        self.artist = artist ?? "No known artist"
        self.occasion = occasion ?? "Occasion unknown"
        
        if let dateStr = date {
            
            let format = NSDateFormatter()
            
            if (dateStr.characters.count == 4) {
                format.dateFormat = "yyyy"
                self.date = format.dateFromString(dateStr)
            } else if (dateStr.characters.count == 7) {
                format.dateFormat = "yyyy/MM"
                self.date = format.dateFromString(dateStr)
            } else if (dateStr.characters.count == 10) {
                format.dateFormat = "yyyy/MM/dd"
                self.date = format.dateFromString(dateStr)
            } else {
                self.date = nil
            }
        }
        
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var data = [Song]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
        
        parseData({Void in
            self.tableView.reloadData()
        })
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        lazyLoad(data[indexPath.row], handler: { (img, uri, url) -> Void in
            print("URI is \(uri)")
            
            if (UIApplication.sharedApplication().canOpenURL(uri!)) {
                UIApplication.sharedApplication().openURL(uri!)
            } else {
                UIApplication.sharedApplication().openURL(url!)
            }
        })
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = UITableViewCell(style: .Default, reuseIdentifier: "Cell") //self.tableView.dequeueReusableCellWithIdentifier("Cell")! as! UITableViewCell
        
        let song = data[indexPath.row] as Song
        
        // TODO: lazyload images
        let cover = UIImageView(frame: CGRectMake(20, 20, 60, 60))
        cell.contentView.addSubview(cover)
        lazyLoad(song, handler: {(image: UIImage?, uri, url) in
            if let img = image {cover.image = img}
        })
        
        let title = UILabel(frame: CGRectMake(100, 15, cell.contentView.frame.width-40, 30))
        title.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        if let ttl = song.title {title.text = ttl}
        cell.contentView.addSubview(title)
        
        let artist = UILabel(frame: CGRectMake(100, 40, cell.contentView.frame.width-40, 20))
        artist.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        if let art = song.artist {artist.text = art}
        cell.contentView.addSubview(artist)
        
        let occasion = UILabel(frame: CGRectMake(100, 60, cell.contentView.frame.width-40, 20))
        occasion.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        if let occ = song.occasion {occasion.text = occ}
        cell.contentView.addSubview(occasion)
        
        return cell
        
    }
    
    func parseData(handler: Void -> Void) {
        
        let path = NSBundle.mainBundle().pathForResource("music", ofType: "csv")
        
        if let unwrappedpath = path {
            let content: String?
            do {
                content = try String(contentsOfFile: unwrappedpath, encoding: NSUTF8StringEncoding)
            } catch let error1 as NSError {
                content = nil
                print("There was an error: \(error1)")
            }
            let lines = content?.componentsSeparatedByString("\n")
            
            for segment in lines! {
                
                let columns = (segment as String).componentsSeparatedByString(",")
                
                data.append(Song(title: columns[2], artist: columns[3], occasion: columns[1], date: columns[0]))
                
            }
            
            data.removeAtIndex(0)       // this is the headlines: Title, Artist, Date, ...
            
            handler()
            
        }
        
    }
    
    func lazyLoad(song: Song, handler: (UIImage?, NSURL?, NSURL?) -> Void) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let url = "https://api.spotify.com/v1/search?type=track&q=\(song.title!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"
            let data = NSData(contentsOfURL: NSURL(string: url as String)!)
            var dict: Dictionary<String, AnyObject>?
            
            do {
                dict = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves) as? Dictionary<String, AnyObject>
            } catch {
                print("There was an error here")
            }
            
            var imgUrl: String?
            var spotifyUri: String?
            var spotifyUrl: String?
            
            // let's walk the safe path
            if let tracks: AnyObject = dict!["tracks"] {
                //print(tracks)
                
                if let items: AnyObject? = tracks["items"] {
                    //print(items!.count, appendNewline: false)
                    
                    if items?.count > 0 {
                        
                        if let first: AnyObject? = items![0] {
                            //print(first)
                            
                            spotifyUri = first!["uri"] as? String
                            
                            if let external: AnyObject? = first!["external_urls"] {
                                spotifyUrl = external!["spotify"] as? String
                            }
                            
                            if let album: AnyObject? = first!["album"] {
                                //print(album)
                                
                                if let images: AnyObject? = album!["images"] {
                                    //print(images)
                                    
                                    if let smallest: AnyObject = images![images!.count - 1] {
                                        //print(smallest)
                                        
                                        if let url: AnyObject? = smallest["url"] {
                                            print(url, appendNewline: false)
                                            
                                            imgUrl = url as? String
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // that didn't work too well... here's the dirty one:
            //imgUrl = dict!["tracks"]!["items"]![0]!["album"]!["images"]![2]!["url"]
            
            if let img = imgUrl {
                
                dispatch_async(dispatch_get_main_queue()) {
                    handler(UIImage(data: NSData(contentsOfURL: NSURL(string: img)!)!), NSURL(string: spotifyUri!), NSURL(string: spotifyUrl!))
                }
                
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

