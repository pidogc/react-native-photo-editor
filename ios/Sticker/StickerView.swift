//
//  LKStickerView.swift
//  StickerViewDemo
//
//  Created by Luke on 2022/6/21.
//

import UIKit
//import ZLImageEditor
import SDWebImage

class StickerView: UIView, ZLImageStickerContainerDelegate {
    
    static let baseViewH: CGFloat = 500
    var baseView: UIView!
    var collectionView: UICollectionView!
    var selectImageBlock: ((UIImage) -> Void)?
    var hideBlock: (() -> Void)?
    var datas    : NSMutableArray = NSMutableArray() // 字典数组
    var dataList : NSMutableArray = NSMutableArray() // 模型数组
    
    public init(stickers: NSMutableArray) {
        super.init(frame: .zero)
        self.setupUI()
        self.datas = stickers
        self.setupData()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: StickerView.baseViewH), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 8, height: 8))
        self.baseView.layer.mask = nil
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        
        self.baseView.layer.mask = maskLayer
    }
    
    private func setupData(){
        // let fileManager = FileManager.default
        // datas = datas + fileManager.getListFileNameInBundle(bundlePath: "Stickers.bundle")
        
        // 转模型
        for item in datas {
            let dict : NSDictionary = item as! NSDictionary
            let title = dict["title"] as! String
            let list  = dict["list"] as! Array<String>
            let numColumns = dict["numColumns"] as! CGFloat
            let model:StickerItemModel = StickerItemModel()
            model.initModel(title: title, list: list, numColumns: numColumns)
            dataList.add(model)
        }
    }
    
    func setupUI() {
        self.baseView = UIView()
        self.addSubview(self.baseView)
        self.baseView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self.snp.bottom).offset(StickerView.baseViewH)
            make.height.equalTo(StickerView.baseViewH)
        }
        
        let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.baseView.addSubview(visualView)
        visualView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.baseView)
        }
        
        //set up toolView
        let toolView = UIView()
        toolView.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        self.baseView.addSubview(toolView)
        toolView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.baseView)
            make.height.equalTo(42)
        }
        
        //setup knob view
        let knob = UIView()
        knob.backgroundColor = UIColor(white: 1, alpha: 0.6)
        
        toolView.addSubview(knob)

        knob.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(6)
            make.width.equalTo(64)
        }
        
        knob.layer.cornerRadius = 4
        
        //  gesture
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizerAction))
        toolView.addGestureRecognizer(gesture)
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.baseView.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(toolView.snp.bottom)
            make.left.right.bottom.equalTo(self.baseView)
        }
        
        self.collectionView.register(StickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(StickerCell.classForCoder()))
        self.collectionView.register(SectionHeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideBtnClick))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
//    func gesture(recognizer: UIPanGestureRecognizer) {
//        let translation = recognizer.translation(in: self.baseView)
//        let y = self.baseView.frame.minY
//        self.baseView.frame = CGRect(x: 0, y: y + translation.y, width: baseView.frame.width, height: baseView.frame.height)
//        recognizer.setTranslation(CGPoint.zero, in: self.baseView)
//    }
    
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view)
        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }
        
        let baseViewH = StickerView.baseViewH - 84
        
        self.baseView.frame.origin = CGPoint(x: 0, y: baseViewH + translation.y)
          if sender.state == .ended {
              let dragVelocity = sender.velocity(in: self.baseView)
              if (dragVelocity.y >= baseViewH || translation.y > baseViewH / 2)  {
                  hide()
              } else {
//                Set back to original position of the view controller
                  UIView.animate(withDuration: 0.3) {
                      self.baseView.frame.origin = CGPoint(x: 0, y: baseViewH)
                  }
              }
          }
      }
    
    @objc func hideBtnClick() {
        self.hide()
    }
    
    func show(in view: UIView) {
        if self.superview !== view {
            self.removeFromSuperview()
            
            view.addSubview(self)
            self.snp.makeConstraints { (make) in
                make.edges.equalTo(view)
            }
            view.layoutIfNeeded()
        }
        
        self.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.baseView.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.snp.bottom)
            }
            view.layoutIfNeeded()
        }
    }
    
    func hide() {
        self.hideBlock?()
        
        UIView.animate(withDuration: 0.3) {
            self.baseView.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.snp.bottom).offset(StickerView.baseViewH)
            }
            self.superview?.layoutIfNeeded()
        } completion: { (_) in
            self.isHidden = true
        }
        
    }
    
}


extension StickerView: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        return !self.baseView.frame.contains(location)
    }
    
}


extension StickerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // Section count
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.dataList.count
    }
    
    // Section item count
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        (self.dataList[section] as! StickerItemModel).list.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let column: CGFloat = (self.dataList[indexPath.section] as! StickerItemModel).numColumns
        let spacing: CGFloat = 20 + 5 * (column - 1)
        let w = (collectionView.frame.width - spacing) / column
        let h = (collectionView.frame.width - spacing) / 5
        return CGSize(width: w, height: h)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(StickerCell.classForCoder()), for: indexPath) as! StickerCell
        
        let item = (self.dataList[indexPath.section] as! StickerItemModel).list[indexPath.item]
        handleImageInCell(from: item) { image in
            cell.imageView.image = image
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = (self.dataList[indexPath.section] as! StickerItemModel).list[indexPath.item]
        handleImageInCell(from: item) { image in
            self.selectImageBlock?(image)
            self.hide()
        }
    }
    
    // Section title
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as? SectionHeaderCollectionReusableView {
            let title = (self.dataList[indexPath.section] as! StickerItemModel).title
            sectionHeader.sectionHeaderLabel.text = title
            return sectionHeader
        }
        
        return UICollectionReusableView()
    }
    
    // Secton title size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width:collectionView.frame.size.width, height:30.0)
    }
    
    private func handleImageInCell(from urlString: String,completion:@escaping (UIImage) -> ()){
        let url = URL(string: urlString)
        if(urlString.contains("http") || urlString.contains("https")){
            SDWebImageManager.shared.loadImage(with: url, options: .continueInBackground, progress: { (recieved, expected, nil) in
            }, completed: { (downloadedImage, data, error, SDImageCacheType, true, imageUrlString) in
                DispatchQueue.main.async {
                    if(error != nil){
                        print("error", error as Any)
                        return;
                    }
                    if downloadedImage != nil{
                        completion(downloadedImage!)
                    }
                }
            })
        }else{
            do{
                let data = try Data(contentsOf: url!)
                completion(UIImage.sd_image(with: data)!)
            }catch{
                
            }
        }
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

}

extension FileManager {
    func getListFileNameInBundle(bundlePath: String, parseName: Bool = false) -> [String] {
        
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent(bundlePath)
        do {
            let contents = try fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)
            if(parseName){
                return contents.map{$0.lastPathComponent}
            }else{
                return contents.map{$0.absoluteString}.sorted()
            }
        }
        catch {
            return []
        }
    }
    
    func getImageInBundle(bundlePath: String) -> UIImage? {
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent(bundlePath)
        return UIImage.init(contentsOfFile: assetURL.relativePath)
    }
}


// Item模型
class StickerItemModel: NSObject {
    var title : String   = ""
    var list  : [String] = []
    var numColumns : CGFloat = 5
    
    func initModel(title:String, list:[String], numColumns:CGFloat) {
        self.title = title
        self.list = list
        self.numColumns = numColumns
    }
}


// SectionHeaderView
class SectionHeaderCollectionReusableView : UICollectionReusableView {
    var sectionHeaderLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sectionHeaderLabel = UILabel(frame: CGRect(x: 10, y: 8, width: frame.size.width, height: frame.size.height))
        sectionHeaderLabel.font = UIFont.boldSystemFont(ofSize:CGFloat(14))
        sectionHeaderLabel.textColor = UIColor(white: 1, alpha: 1)
        self.addSubview(sectionHeaderLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

