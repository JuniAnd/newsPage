//
//  ViewController.swift
//  NewsPageTest
//
//  Created by developer on 6/3/18.
//  Copyright © 2018 developer. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageController: UIPageControl!
    @IBOutlet weak var pageView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var segmentedController: UISegmentedControl!
    
    
    let activityIndicator = UIActivityIndicatorView()
    var resultsArray = [[String:AnyObject]]()
    var productsArray = [Products]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        scrollView.delegate = self
        self.hideAllView(true)
        self.initializationActivity()
        self.activityIndicator.startAnimating()
        self.segmentedPreferences()
        self.sendRequest()
    }
    
    func sendRequest () {
        let url = URL(string: "http://allcom.lampawork.com/api/v1.0/products/")
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil { print("Error") } else {
                if let content = data {
                    do {
                        let myJSON = try JSONSerialization.jsonObject(with: content, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                        self.resultsArray = myJSON["results"] as! [[String : AnyObject]]
                        self.productsArray = self.resultsArray.map { Products.init(resultsArray: $0) }
                        self.downloadImage()
                    }
                    catch {
                        print("Can't parse JSON")
                    }
                }
            }
        }
        task.resume()
    }
    
    func downloadImage()  {
        
        var imgCount = 0
        var productCount = 0
        // when imgCount and productCount is equal the downloading is done and i can call func with initiolization content
        
        for product in self.productsArray {
            if let url = product.imageUrl {
                productCount += 1
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: URL(string: url)!)
                    DispatchQueue.main.async {
                        imgCount += 1
                        product.image = UIImage(data: data!)
                        if imgCount == productCount {
                            self.initializationOfContent()
                        }
                    }
                }
            }
        }
    }
    
    func initializationOfContent () {

        hideAllView(false)

        self.activityIndicator.stopAnimating()
        self.collectionView.reloadData()
        
        let subviews = self.scrollView.subviews
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        var j = 0 // use to calculate width of content size of ScrollView and origin.x point of ImageView
        
        for product in self.productsArray {
            if product.topStatus {
                
                // create imageView
                
                let imageView = UIImageView()
                imageView.image = product.image
                imageView.contentMode = .scaleAspectFill
            
                let xPosition = self.scrollView.frame.width * CGFloat(j)
                imageView.frame = CGRect(x: xPosition, y: 0,
                                         width: self.scrollView.frame.width,
                                         height: self.scrollView.frame.height)
            
                // Create label
                
                let label = UILabel()
                label.text = product.name
                label.textColor = UIColor.white
                label.font = UIFont.boldSystemFont(ofSize: 25)
                label.textAlignment = NSTextAlignment.center
                
                label.frame.size = CGSize(width: self.scrollView.frame.width, height: 70)
                
                let labelCenterX = self.scrollView.frame.width * CGFloat(j) + (self.scrollView.frame.width / 2)
                let labelCenterY = self.scrollView.frame.height - label.frame.height / 2
                label.center = CGPoint(x: labelCenterX, y: labelCenterY )
                
                self.scrollView.contentSize.width = self.scrollView.frame.width * CGFloat(j + 1)
                self.scrollView.addSubview(imageView)
                self.scrollView.addSubview(label)
                j += 1
            }
        }
        
        //  button with icon "top"
        
        let button = UIButton()
        button.setImage((#imageLiteral(resourceName: "Без имени-2")) , for: UIControlState.normal)
        button.isUserInteractionEnabled = false
        
        button.frame.size = CGSize(width: 65, height: 25)
        let buttonCenterX = self.scrollView.frame.width - button.frame.width / 2
        let buttonCenterY = self.scrollView.frame.minY + self.scrollView.frame.height / 100 * 20
        button.center = CGPoint(x: buttonCenterX, y: buttonCenterY)
        self.view.addSubview(button)
    }
    
    func hideAllView(_ state: Bool) {
        self.collectionView.isHidden = state
        self.scrollView.isHidden = state
        self.pageView.isHidden = state
    }
    
    func segmentedPreferences () {
        let font: [AnyHashable : Any] = [NSAttributedStringKey.font : UIFont.systemFontSize]
        segmentedController.setTitleTextAttributes(font, for: .application)
        segmentedController.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: UIControlState.selected)
        segmentedController.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.gray], for: UIControlState.normal)
    }
    
    func initializationActivity() {
        self.activityIndicator.center = self.view.center
        self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        self.activityIndicator.hidesWhenStopped = true
        self.view.addSubview(self.activityIndicator)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageController.currentPage = Int(scrollView.contentOffset.x / self.view.frame.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.productsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        
        cell.newsImageView?.image = productsArray[indexPath.row].image
        cell.newsImageView?.contentMode = .scaleAspectFill
        
        cell.newsLabel.text = productsArray[indexPath.row].name
        cell.newsViewCount.text = "Просмотров: " + String(productsArray[indexPath.row].viewCount)
        cell.newsPrice.text = String(productsArray[indexPath.row].price) + " " + String(productsArray[indexPath.row].currency)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
 
        var height : CGFloat
        
        if productsArray[indexPath.row].image == nil {
            height = 81
        }else {
            height = 306
        }
                
        return CGSize(width: self.view.frame.width, height: height )
    }
}

class Products {
    let resultsArray: [String:AnyObject]
    var name : String
    var price : Int
    var currency : String
    var viewCount : Int
    var imageUrl : String?
    var topStatus = false
    var image: UIImage? = nil
    
    init(resultsArray: [String:AnyObject]) {
        self.resultsArray = resultsArray
        
        self.name = self.resultsArray["name"] as? String ?? ""
        self.price = self.resultsArray["price"] as? Int ?? 0
        self.imageUrl = self.resultsArray["image"]!["url"] as? String ?? nil
        
        let someCurrency = self.resultsArray["currency"]!["name"] as? String ?? ""
        self.currency = someCurrency.count > 1 ? someCurrency.htmlToString : someCurrency
        
        self.viewCount = self.resultsArray["view_count"] as? Int ?? 0
        if self.viewCount >= 50 {
            self.topStatus = true
        }
    }
}

// extension String to convert http text from response

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType:  NSAttributedString.DocumentType.html], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}








