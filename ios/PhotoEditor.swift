//
//  PhotoEditor.swift
//  PhotoEditor
//
//  Created by Donquijote on 27/07/2021.
//

import Foundation
import UIKit
import Photos
import SDWebImage
import AVFoundation
//import ZLImageEditor

public enum ImageLoad: Error {
    case failedToLoadImage(String)
}

@objc(PhotoEditor)
class PhotoEditor: NSObject {
    var window: UIWindow?
    var bridge: RCTBridge!
    
    var resolve: RCTPromiseResolveBlock!
    var reject: RCTPromiseRejectBlock!

    var resultImageView: UIImageView!
    
    var originalImagePath: String?
    
    var resultImageEditModels: Dictionary<String, ZLEditImageModel> = [:]    
    
    @objc(open:withResolver:withRejecter:)
    func open(options: NSDictionary, resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) -> Void {
        
        // handle path
        guard let path = options["path"] as? String else {
            reject("DONT_FIND_IMAGE", "Dont find image", nil)
            return;
        }
        
        let editorModelKey = options["editorModelKey"] as? String ?? ""

         // openCanRedoMode
         let canRedo: Bool = options["canRedo"] as? Bool ?? false
                
         let editModel = !canRedo ? nil : self.getTargetResultImageEditModel(editorModelKey: editorModelKey)


        getUIImage(url: path) { image in
            DispatchQueue.main.async {
                
                //  set config
                self.setConfiguration(options: options, canRedo: canRedo, resolve: resolve, reject: reject)
                self.presentController(path: path, editorModelKey: editorModelKey, canRedo: canRedo, image: image, editModel: editModel)
            }
        } reject: {_ in
            reject("LOAD_IMAGE_FAILED", "Load image failed: " + path, nil)
        }
    }
    
    func onCancel() {
        self.reject("USER_CANCELLED", "User has cancelled", nil)
    }
    
    @objc(onInitImageEditorModels)
    func onInitImageEditorModels() -> Void {
        self.resultImageEditModels = [:]
    }
    
    private func setResultImageEditModels(editorModelKey: String, editModel: ZLEditImageModel?) {

      guard (editorModelKey != "") else {
        return
      }

        self.resultImageEditModels[editorModelKey] = editModel
    }
    
    private func getTargetResultImageEditModel(editorModelKey: String) -> ZLEditImageModel? {
        return self.resultImageEditModels[editorModelKey] ?? nil
    }
    
    private func setConfiguration(options: NSDictionary, canRedo: Bool, resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) -> Void{
        self.resolve = resolve;
        self.reject = reject;
        
        // Stickers
        let stickers: NSMutableArray = options["stickers"] as? NSMutableArray ?? []
        
        //Config
        ZLImageEditorUIConfiguration().editDoneBtnBgColor(UIColor(red:255/255.0, green:238/255.0, blue:101/255.0, alpha:1.0))

        ZLImageEditorConfiguration.default().imageStickerContainerView(StickerView(stickers: stickers)).editImageTools([.draw, .clip, .imageSticker, .textSticker, .filter]).canRedo(canRedo)
        
        //Filters Lut
        do {
            let filters = ColorCubeLoader()
            ZLImageEditorConfiguration.default().filters = try filters.load()
        } catch {
            assertionFailure("\(error)")
        }
    }

    private func presentController(path: String, editorModelKey: String, canRedo: Bool, image: UIImage, editModel: ZLEditImageModel?) {
        if let controller = UIApplication.getTopViewController() {
            controller.modalTransitionStyle = .crossDissolve

            ZLEditImageViewController.showEditImageVC(parentVC:controller , image: image, editModel: editModel) { [weak self] (resImage, editModel) in

                if (canRedo) {
                  self?.setResultImageEditModels(editorModelKey: editorModelKey, editModel: editModel)
                }

                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                
                let destinationPath = URL(fileURLWithPath: documentsPath).appendingPathComponent(String(Int64(Date().timeIntervalSince1970 * 1000)) + ".png")
                
                do {
                    try resImage.pngData()?.write(to: destinationPath)
                    self?.resolve(destinationPath.absoluteString)
                } catch {
                    debugPrint("writing file error", error)
                }
            }
        }
    }
    
    
    private func getUIImage (url: String ,completion:@escaping (UIImage) -> (), reject:@escaping(String)->()){
        if let path = URL(string: url) {
            SDWebImageManager.shared.loadImage(with: path, options: .continueInBackground, progress: { (recieved, expected, nil) in
            }, completed: { (downloadedImage, data, error, SDImageCacheType, true, imageUrlString) in
                DispatchQueue.main.async {
                    if(error != nil){
                        print("error", error as Any)
                        reject("false")
                        return;
                    }
                    if downloadedImage != nil{
                        completion(downloadedImage!)
                    }
                }
            })
        }else{
            reject("false")
        }
    }
    
}

extension UIApplication {
    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        
        return base
    }
}
