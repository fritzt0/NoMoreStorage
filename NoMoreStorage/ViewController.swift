//
//  ViewController.swift
//  NoMoreStorage
//
//  Created by Lukas Böhler on 01/08/16.
//  Copyright © 2016 Lukas Böhler. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var freeStorageLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var flushButton: UIButton!
    @IBOutlet weak var aimedFreeStorage: UITextField!
    
    var writeBullshit = false {
        didSet {
            let title = writeBullshit ? "🛑" : "💩"
            self.startButton.setTitle(title, for: UIControlState())
        }
    }

    var flushBullshit = false {
        didSet {
            let title = flushBullshit ? "🛑" : "🚽"
            self.flushButton.setTitle(title, for: UIControlState())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startButton.layer.cornerRadius = 3.0
        flushButton.layer.cornerRadius = 3.0
        aimedFreeStorage.layer.cornerRadius = 3.0
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
    }
    
    @objc func update() {
        // Check diskstorage.
        let freeSpaceInGBytes = deviceRemainingFreeSpaceInGBytes()
        freeStorageLabel.text = "\(freeSpaceInGBytes!)"
        
        if let aimedFreeSpace = Int(aimedFreeStorage.text!) {
            if(freeSpaceInGBytes! < aimedFreeSpace) {
                self.writeBullshit = false
            }
        }
    }
    
    @IBAction func hideKeyboard(_ sender: AnyObject) {
        _ = sender.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func fillSpace(_ data: Data = Data(bytes:Array<UInt8>(repeating: 1, count: 1_000_000_000))) {
        guard data.count > 0, self.writeBullshit else { return }
        print("Writing \(data.count) bytes...")
        let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0]
        let destPath = (docsDir as NSString).appendingPathComponent("/alotof_\(NSUUID().uuidString).shit")

        if FileManager.default.createFile(atPath: destPath, contents: data, attributes: nil) {
            destPath.excludeFromBackup()
            fillSpace(data)
        } else {
            fillSpace(Data(bytes:Array<UInt8>(repeating: 1, count: data.count / 2)))
        }
    }

    func deviceRemainingFreeSpaceInGBytes() -> Int? {
        if var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let values = try? documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let capacity = values.volumeAvailableCapacityForImportantUsage {
            // Prevent reuse of a cached value
            documentsURL.removeCachedResourceValue(forKey: .volumeAvailableCapacityForImportantUsageKey)
            return Int(Double(capacity) / 1_000_000_000.0)
        }
        // something failed
        return nil
    }
    
    @IBAction func startWrittingBullshit() {
        self.flushBullshit = false
        self.writeBullshit = !self.writeBullshit

        DispatchQueue.global(qos: .default).async {
            self.fillSpace()
        }
    }

    @IBAction func startFlushingBullshit() {
        self.writeBullshit = false
        self.flushBullshit = !self.flushBullshit

        DispatchQueue.global(qos: .default).async {
            let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0]
            let fileMgr = FileManager.default
            if let dirEnum = fileMgr.enumerator(atPath: docsDir) {
                while let file = dirEnum.nextObject() as? String, self.flushBullshit {
                    if file.hasSuffix("shit") && file.contains("alotof_") {
                        let filePath = docsDir + "/\(file)"
                        do {
                            try fileMgr.removeItem(atPath: filePath)
                        } catch _ {

                        }

                        usleep(500000)
                    }
                }

                DispatchQueue.main.async(execute: {
                    self.flushBullshit = false
                })
            }

        }
    }
}

extension OutputStream {
    /// http://stackoverflow.com/questions/26989493/how-to-open-file-and-append-a-string-in-it-swift
    /// Write String to outputStream
    ///
    /// - parameter string:                The string to write.
    /// - parameter encoding:              The NSStringEncoding to use when writing the string. This will default to UTF8.
    /// - parameter allowLossyConversion:  Whether to permit lossy conversion when writing the string.
    ///
    /// - returns:                         Return total number of bytes written upon success. Return -1 upon failure.
    
    func write(_ string: String, encoding: String.Encoding = String.Encoding.utf8, allowLossyConversion: Bool = true) -> Int {
        if let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) {
            var bytes = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
            var bytesRemaining = data.count
            var totalBytesWritten = 0
            
            while bytesRemaining > 0 {
                let bytesWritten = self.write(bytes, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    return -1
                }
                
                bytesRemaining -= bytesWritten
                bytes += bytesWritten
                totalBytesWritten += bytesWritten
            }
            
            return totalBytesWritten
        }
        
        return -1
    }
    
}

private extension String {
    func excludeFromBackup() {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var destURL = URL(fileURLWithPath: self)
        try! destURL.setResourceValues(resourceValues)
    }
}

