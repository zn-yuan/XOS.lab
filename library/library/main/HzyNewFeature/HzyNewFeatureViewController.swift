//
//  HzyNewFeatureViewController.swift
//  library
//
//  Created by Ranger on 2018/5/14.
//  Copyright © 2018年 hzy. All rights reserved.
//

import UIKit

protocol ViewControllerConfigable {
    func setupSubviews()
    func setupNav()
}

extension ViewControllerConfigable{
    func setupSubviews(){}
    func setupNav(){}
}

protocol NewFeaturSubViewItemable {
    var  newFeatureView: UIView {get}
    func hzyDidEnterForeground()
    func hzyDidEnterBackGround()
    func setCompleteBlock(block: @escaping ()->Void)
}

extension NewFeaturSubViewItemable {
    func hzyDidEnterForeground() {}
    func hzyDidEnterBackGround() {}
    func setCompleteBlock(block: @escaping ()->Void) {}
}


extension UIViewController: ViewControllerConfigable{}

private let hzy_lastVersionKey = "lastVersionKey"


extension HzyNewFeatureViewController {
    
    class func instantiateViewController(_ animate: Bool = true) ->HzyNewFeatureViewController{
        if animate {
            let items = HzyNewFeatureItemViewController.items(imageNames: "1","2","3", "4")
            return HzyNewFeatureViewController(items)
        } else {
            return HzyNewFeatureViewController(["1","2","3", "4"])
        }
    }
    
    class func isShowNewFeature()-> Bool{
        let lastVersion = UserDefaults.standard.string(forKey: hzy_lastVersionKey)
        if lastVersion == HzyAppInfo.appVersion {
            return false
        } else {
            return  true
        }
    }
}

class HzyNewFeatureViewController: UIViewController {
    typealias T = NewFeaturSubViewItemable
    enum DataSourceType {
        case imageName
        case customContainer
    }
    
    fileprivate var scrollView: UIScrollView!
    
    fileprivate var pageControl: UIPageControl!
    
    fileprivate var imagesNames: [String] = []
    
    fileprivate var customContainerViews: [T] = []
    
    var isPageControlHidden: Bool = false
    
    var pageIndicatorTintColor: UIColor? = UIColor.hzy.randomColor()
    
    var completeBlock: (()->Void)?
    
    var completeBtnTitle: String = "进入"
    var completeBtnTitleColor: UIColor = UIColor.white
    var completeBtnBackgroundColor: UIColor? = UIColor.orange
    var completeBtnCornerRadius: CGFloat = 15
    var completeBtnWidth: CGFloat = 120
    var completeBtnHeight: CGFloat = 30
    var completeBtnBackgroundImage: UIImage?
    var completeBtnImage: UIImage?
    
    fileprivate var fromePage: Int = 0
    
    fileprivate var dataSourceType: DataSourceType = .imageName
    
    fileprivate var numberOfPages: Int {
        return dataSourceType == .imageName ? imagesNames.count : customContainerViews.count
    }

    convenience init(_ imagesNames: [String]) {
        self.init()
        self.dataSourceType = .imageName
        self.imagesNames = imagesNames
    }
    
    convenience init<T: NewFeaturSubViewItemable>(_ customContainerViews: [T]){
        self.init()
        self.dataSourceType = .customContainer
        self.customContainerViews = customContainerViews
    }
    
    private init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.dataSourceType == .customContainer,
        let firstItem = customContainerViews.first
        else {
            return
        }
        firstItem.hzyDidEnterForeground()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        UserDefaults.standard.set(HzyAppInfo.appVersion, forKey: hzy_lastVersionKey)
    }
    
    @objc fileprivate func completeClickAction(){
      
        completeBlock?()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //解决方法1：AutoLayout状态下，执行完viewDidLoad、viewWillAppear等方法后，还会执行viewDidLayoutSubviews方法，在这个方法中，我们可以重新对某个子View，甚至某个ChildViewController的View进行Frame调整。(网上的)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard self.dataSourceType == .customContainer else {
            return
        }
        let sh = UIScreen.height
        let sw = UIScreen.width
        for (index, customContainer) in customContainerViews.enumerated() {
            customContainer.newFeatureView.frame = CGRect(x: sw*index.cgFloat, y: 0, width: sw, height: sh)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HzyNewFeatureViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.fromePage = self.pageControl.currentPage
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageControl.currentPage = ((scrollView.contentOffset.x + UIScreen.width/2) / UIScreen.width).int
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        guard self.pageControl.currentPage != fromePage else {
            return
        }
        
        guard self.dataSourceType == .customContainer else {
            return
        }
        
        let currentContainer = customContainerViews[self.pageControl.currentPage]
        
        currentContainer.hzyDidEnterForeground()
        
        let fromeContainer = customContainerViews[self.fromePage]
        fromeContainer.hzyDidEnterBackGround()
    }
}

extension HzyNewFeatureViewController {
    
    fileprivate func setupSubviews() {
        self.view.backgroundColor = UIColor.white
        guard numberOfPages > 0 else {
            return
        }
       
        scrollView = UIScrollView().config{
            $0.backgroundColor = UIColor.white
            $0.delegate = self
            $0.showsHorizontalScrollIndicator = false
            $0.isPagingEnabled = true
            $0.bounces = false
            $0.contentSize = CGSize(width: UIScreen.width*numberOfPages.cgFloat, height: UIScreen.height)
        }
        
        pageControl = {
            let pageControl = UIPageControl()
            pageControl.pageIndicatorTintColor = self.pageIndicatorTintColor ?? UIColor.gray
            pageControl.numberOfPages = numberOfPages
            pageControl.hidesForSinglePage = true
            pageControl.isHidden = self.isPageControlHidden
            pageControl.defersCurrentPageDisplay = true
            return pageControl
        }()
        
        setNetFeatureViews()
        
        scrollView.addHere(toSuperview: self.view)
        
        scrollView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(self.view)
        }
    
        pageControl.addHere(toSuperview: self.view)
        
        pageControl.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(-30)
            maker.width.equalToSuperview()
            maker.height.equalTo(30)
            maker.centerX.equalToSuperview()
        }
        
    }
    
   fileprivate func setNetFeatureViews(){
        let sh = UIScreen.height
        let sw = UIScreen.width
        if self.dataSourceType == .imageName {
            
            for (index, imageName) in imagesNames.enumerated() {
                
                let imageView = UIImageView(image: UIImage(named: imageName))
                imageView.frame = CGRect(x: sw * index.cgFloat, y: 0, width: sw, height: sh)
                imageView.addHere(toSuperview: scrollView)
                
                guard index == numberOfPages - 1 else{
                    continue
                }
                
                let completeBtn: UIButton = {
                    let btn = UIButton()
                    btn.addTarget(self, action: #selector(completeClickAction), for: .touchUpInside)
                    btn.setTitle(completeBtnTitle, for: .normal)
                    btn.setTitleColor(completeBtnTitleColor, for: .normal)
                    btn.layer.cornerRadius = completeBtnCornerRadius
                    btn.layer.masksToBounds = true
                    btn.backgroundColor = completeBtnBackgroundColor
                    btn.setImage(completeBtnImage, for: .normal)
                    btn.setBackgroundImage(completeBtnBackgroundImage, for: .normal)
                    return btn
                }()
                
                completeBtn.addHere(toSuperview: imageView)
                completeBtn.snp.makeConstraints( { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.bottom.equalTo(-90)
                    maker.width.equalTo(completeBtnWidth)
                    maker.height.equalTo(completeBtnHeight)
                })
                
            }
            
        } else {
            for (index, customContainer) in customContainerViews.enumerated() {
                customContainer.newFeatureView.frame = CGRect(x: sw*index.cgFloat, y: 0, width: sw, height: sh)
                customContainer.setCompleteBlock(block: {[unowned self] in
                    self.completeBlock?()
                })
                scrollView.addSubview(customContainer.newFeatureView)
            }
        }
    }
}
