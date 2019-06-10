//
//  ViewController.swift
//  SiaUs
//
//  Created by Michal Sefl on 09/06/2019.
//  Copyright © 2019 Michal Sefl. All rights reserved.
//

import UIKit
import AVFoundation
import Us
import Photos

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    // properties - text fields
    @IBOutlet weak var contractTextField: UITextField!
    @IBOutlet weak var shardServerTextField: UITextField!
    @IBOutlet weak var fileNameTextField: UITextField!
    
    // properties - buttons
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    
    // properties - image views
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var downloadedImageView: UIImageView!
    
    // properties - activity indicators
    @IBOutlet weak var uploadActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var downloadActivityIndicatorView: UIActivityIndicatorView!
    
    // properties - images
    var imagePicker = UIImagePickerController()
    var selectedPhoto: UIImage? = nil
    var downloadedPhoto: UIImage? = nil
    
    // create the reader lazily to avoid cpu overload during the initialization and each time we need to scan a QRCode
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            
            // configure the view controller
            $0.showTorchButton        = false
            $0.showSwitchCameraButton = false
            $0.showCancelButton       = false
            $0.showOverlayView        = true
            $0.rectOfInterest         = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    // MARK: - UI
    
    func setupUI() {
        
        // detect changes on text field
        contractTextField.addTarget(self, action: Selector(("contractTextFieldDidChange")), for: UIControl.Event.editingChanged)
        shardServerTextField.addTarget(self, action: Selector(("shardServerTextFieldDidChange")), for: UIControl.Event.editingChanged)
        fileNameTextField.addTarget(self, action: Selector(("fileNameFieldDidChange")), for: UIControl.Event.editingChanged)
        
        // setup image picker
        imagePicker.delegate = self
        
        // setup borders
        setupBorderForView(selectedImageView)
        setupBorderForView(downloadedImageView)
        setupBorderForView(contractTextField)
        setupBorderForView(shardServerTextField)
        setupBorderForView(fileNameTextField)
        
        // pre-fill --> contract
        if let contractValue = UserDefaults.standard.string(forKey: Keys.UserDefaults.contract) {
            self.contractTextField.text = contractValue
            
            // you can use Data.contract to force set own contract data from code; if you don't want to use it, keep it nil
            if let contract = Contracts.testContract {
                self.contractTextField.text = contract
            }
        }
        
        // pre-fill --> shard server
        if let shardServerValue = UserDefaults.standard.string(forKey: Keys.UserDefaults.shardServer) {
            self.shardServerTextField.text = shardServerValue
        }
        
        // pre-fill --> fileName
        if let fileNameValue = UserDefaults.standard.string(forKey: Keys.UserDefaults.fileName) {
            self.fileNameTextField.text = fileNameValue
        }
        
        updateControlStates()
    }
    
    func setupBorderForView(_ view: UIView, cornerRadius: CGFloat = 6) {
        
        // set rounded colored borders for any view passed as param
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor(red: 136/255, green: 136/255, blue: 136/255, alpha: 1).cgColor
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
    }
    
    // MARK: - QR Codes
    
    @IBAction func scanAction(_ sender: AnyObject) {
        
        // retrieve the qr code using completion
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            self.readerVC.dismiss(animated: true, completion: nil)
            if let scannedValue = result?.value {
                self.contractTextField.text = scannedValue
                self.updateControlStates()
                self.logMessage("QR code scanned: \(scannedValue)")
            } else {
                Tooltip.show("QR code scanning ended with no result.")
            }
        }
        
        // presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    // MARK: - Text Field Changes
    
    @IBAction func done(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    @objc func contractTextFieldDidChange() {
        
        // each time this field changes (either manually or from as result of QR code scanning), store this value
        UserDefaults.standard.set(contractTextField.text ?? "", forKey: Keys.UserDefaults.contract)
        UserDefaults.standard.synchronize()
        updateControlStates()
    }
    
    @objc func shardServerTextFieldDidChange() {
        
        // each time this field changes (either manually or from as result of QR code scanning), store this value
        UserDefaults.standard.set(shardServerTextField.text ?? "", forKey: Keys.UserDefaults.shardServer)
        UserDefaults.standard.synchronize()
        updateControlStates()
    }
    
    @objc func fileNameFieldDidChange() {
        
        // each time this field changes (either manually or from as result of QR code scanning), store this value
        UserDefaults.standard.set(fileNameTextField.text ?? "", forKey: Keys.UserDefaults.fileName)
        UserDefaults.standard.synchronize()
        updateControlStates()
    }
    
    func updateControlStates() {
        
        // check if contract is valid and photo selected
        let isContractValid = contractTextField.text?.count == 192
        let isPhotoSelected = selectedPhoto != nil
        
        // set state of controls based on previous checks
        contractTextField.textColor = isContractValid ? UIColor.white : UIColor.Sia.red
        uploadButton.isEnabled = isContractValid && isPhotoSelected && shardServerTextField.text != nil && getFileName() != nil
        downloadButton.isEnabled = isContractValid && shardServerTextField.text != nil && getFileName() != nil
        
        // set different titles for enabled and disabled buttons
        if let fileName = getFileName() {
            uploadButton.setTitle("Upload \(fileName)", for: .normal)
            downloadButton.setTitle("Download \(fileName)", for: .normal)
        } else {
            uploadButton.setTitle("Upload File", for: .normal)
            downloadButton.setTitle("Download File", for: .normal)
        }
    }
    
    // MARK: - Sia Us, Files & Contracts
    
    func getFileName() -> String? {
        
        // returns nil if user didn't enter anything or name of file
        
        guard let fileNameValue = fileNameTextField.text else { return nil }
        if fileNameValue.isEmpty { return nil }
        
        return fileNameValue.contains(".") ? fileNameValue : "\(fileNameValue).png"
    }
    
    func getSelectedPictureData() -> Data? {
        
        // returns selected photo as base64 data or nil
        
        if let pngData = selectedPhoto?.pngData() {
            return pngData.base64EncodedData()
        }
        
        return nil
    }
    
    func decodeContract(_ contractValue: String) -> UsContract? {
        
        // returns UsContract object or nil
        
        if let contract = UsContract(Data(fromHexEncodedString: contractValue)) {
            logMessage("Contract successfully decoded.")
            return contract
        }
        
        Tooltip.show("Contract decoding failed.")
        return nil
    }
    
    func getRootFolder() -> String? {
        
        // returns path that `Us.Framework` can use; creates folder if neccessary
        
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let fsroot = documentsDirectory?.appendingPathComponent("meta").path else { return nil }
        
        if !fileManager.fileExists(atPath: fsroot) {
            do {
                try FileManager.default.createDirectory(atPath: fsroot, withIntermediateDirectories: true, attributes: nil)
                logMessage("Document directory created.")
                return fsroot
            } catch {
                Tooltip.show("Couldn't create document directory.")
                return nil
            }
        }
        logMessage("Document directory found.")
        return fsroot
    }

    @IBAction func uploadFile() {
        
        // uploads selected photo
        
        guard let contractValue = contractTextField.text else { return }
        guard let contract = decodeContract(contractValue) else { return }
        guard let shardServer = shardServerTextField.text else { return }
        guard let fileName = getFileName() else { return }
        guard let rootFolder = getRootFolder() else { return }
        
        uploadActivityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // run after delay so activity indicator has time to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            do {
                // prepare host set
                var error: NSError?
                let host = UsNewHostSet(shardServer, &error)
                try host?.addHost(contract)
                
                // prepare file system
                let fileSystem = UsFileSystem.init(rootFolder, hs: host)
                
                // upload file
                try fileSystem?.upload(fileName, data: self.getSelectedPictureData(), minHosts: 1)
                try fileSystem?.close()
                
                self.logMessage("\(fileName) was successfuly uploaded.")
                Tooltip.show("\(fileName) was successfuly uploaded.")
                
                self.uploadActivityIndicatorView.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                
            } catch let error {
                Tooltip.show("\(fileName) couldn't be uploaded.")
                self.logMessage("-> Error: \(error.localizedDescription)")
                
                self.uploadActivityIndicatorView.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            
        }
    }
    
    @IBAction func downloadFile() {
        
        // downloads photo
        
        guard let contractValue = contractTextField.text else { return }
        guard let contract = decodeContract(contractValue) else { return }
        guard let shardServer = shardServerTextField.text else { return }
        guard let fileName = getFileName() else { return }
        guard let rootFolder = getRootFolder() else { return }
        
        downloadedImageView.image = nil
        downloadActivityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // run after delay so activity indicator has time to appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
            do {
                // prepare host set
                var error: NSError?
                let host = UsNewHostSet(shardServer, &error)
                try host?.addHost(contract)
                
                // prepare file system
                let fileSystem = UsFileSystem.init(rootFolder, hs: host)
                
                // download file
                self.logMessage("Downloading \(fileName).")
                
                if let data = try fileSystem?.download(fileName) {
                    self.logMessage("\(fileName) was successfuly downloaded.")
                    Tooltip.show("\(fileName) was successfuly downloaded.")
                    
                    self.downloadActivityIndicatorView.stopAnimating()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    if let base64data = Data(base64Encoded: data) {
                        self.downloadedPhoto = UIImage(data: base64data)
                        
                        self.downloadedImageView.contentMode = .scaleAspectFit
                        self.downloadedImageView.image = self.downloadedPhoto
                    }
                }
                
            } catch let error {
                Tooltip.show("\(fileName) couldn't be downloaded.")
                self.logMessage("-> Error: \(error.localizedDescription)")
                
                self.downloadActivityIndicatorView.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            
        }
        
    }
    
    // MARK: - Logging
    
    func logMessage(_ message: String) {
        
        // replace by custom logging if you wish
        print("> \(message)")
    }
    
    // MARK: - Permissions
    
    func checkPhotoPermissions() {
        
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized: logMessage("Access is granted by user")
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                self.logMessage("status is \(newStatus)")
                if newStatus == PHAuthorizationStatus.authorized {
                    self.logMessage("success")
                    
                }
            })
        case .restricted: Tooltip.show("User do not have access to photo album.")
        case .denied: Tooltip.show("User has denied the permission.")
        default: break
        }
    }
}

// MARK: - Image Picker & Delegate

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBAction func selectPicture() {
        
        uploadActivityIndicatorView.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        checkPhotoPermissions()
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            
            present(imagePicker, animated: true, completion: nil)
        } else {
            uploadActivityIndicatorView.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedPhoto = pickedImage
            
            selectedImageView.contentMode = .scaleAspectFit
            selectedImageView.image = selectedPhoto
            
            updateControlStates()
        }
        
        uploadActivityIndicatorView.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        updateControlStates()
        
        uploadActivityIndicatorView.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
        dismiss(animated: true, completion: nil)
    }
}
