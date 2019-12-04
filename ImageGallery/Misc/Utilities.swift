//
//  Utilities.swift
//
//  Created by CS193p Instructor.
//  Copyright © 2017 Stanford University. All rights reserved.
//
import UIKit

class ImageFetcher
{
    // Public API
    
    // To use, create with the closure you want called when the image is ready.
    // Example: let fetcher = ImageFetcher() { // code to execute when fetch is done }
    // Your closure is invoked OFF THE MAIN THREAD.
    // Then call fetch(url:) with the url you want to fetch.
    // And set a backup image in case the fetch fails.
    //
    // The handler will be called immediately if the fetch succeeds.
    // If the fetch fails, the handler will be called if and when the backup image is set.
    // The backup can be set at any time (i.e. before, during or after the fetch).
    // If the fetch fails and a backup image is never set, the handler will never be called.
    // Thus it would sort of be a strange use of this class to not set a backup image
    //   (because you'd never find out when the fetch failed).
    // Note that you must keep a strong pointer to this object until the fetch finishes
    //   otherwise the result of the fetch will be discarded and the handler never called.
    // In other words, keeping a strong pointer to your instance says "I'm still interested in its result."
    
    var backup: UIImage? { didSet { callHandlerIfNeeded() } }
    
    func fetch(_ url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let data = try? Data(contentsOf: url.imageURL) {
                if self != nil {
                    // yes, it's ok to create a UIImage off the main thread
                    if let image = UIImage(data: data) {
                        self?.handler(url, image)
                    } else {
                        self?.fetchFailed = true
                    }
                } else {
                    print("ImageFetcher: fetch returned but I've left the heap -- ignoring result.")
                }
            } else {
                self?.fetchFailed = true
            }
        }
    }
    
    init(handler: @escaping (URL, UIImage) -> Void) {
        self.handler = handler
    }
    
    init(fetch url: URL, handler: @escaping (URL, UIImage) -> Void) {
        self.handler = handler
        fetch(url)
    }
    
    // Private Implementation
    
    private let handler: (URL, UIImage) -> Void
    private var fetchFailed = false { didSet { callHandlerIfNeeded() } }
    private func callHandlerIfNeeded() {
        if fetchFailed, let image = backup, let url = image.storeLocallyAsJPEG(named: String(Date().timeIntervalSinceReferenceDate)) {
            handler(url, image)
        }
    }
}

extension URL {
    var imageURL: URL {
        if let url = UIImage.urlToStoreLocallyAsJPEG(named: self.path) {
            // this was created using UIImage.storeLocallyAsJPEG
            return url
        } else {
            // check to see if there is an embedded imgurl reference
            for query in query?.components(separatedBy: "&") ?? [] {
                let queryComponents = query.components(separatedBy: "=")
                if queryComponents.count == 2 {
                    if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                        return url
                    }
                }
            }
            return self.baseURL ?? self
        }
    }
}

extension UIImage
{
    private static let localImagesDirectory = "UIImage.storeLocallyAsJPEG"
    
    static func urlToStoreLocallyAsJPEG(named: String) -> URL? {
        var name = named
        let pathComponents = named.components(separatedBy: "/")
        if pathComponents.count > 1 {
            if pathComponents[pathComponents.count-2] == localImagesDirectory {
                name = pathComponents.last!
            } else {
                return nil
            }
        }
        if var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            url = url.appendingPathComponent(localImagesDirectory)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                url = url.appendingPathComponent(name)
                if url.pathExtension != "jpg" {
                    url = url.appendingPathExtension("jpg")
                }
                return url
            } catch let error {
                print("UIImage.urlToStoreLocallyAsJPEG \(error)")
            }
        }
        return nil
    }
    
    func storeLocallyAsJPEG(named name: String) -> URL? {
        if let imageData = self.jpegData(compressionQuality: 1.0) {
            if let url = UIImage.urlToStoreLocallyAsJPEG(named: name) {
                do {
                    try imageData.write(to: url)
                    return url
                } catch let error {
                    print("UIImage.storeLocallyAsJPEG \(error)")
                }
            }
        }
        return nil
    }
}


extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}

extension String {
    func madeUnique(withRespectTo otherStrings: [String]) -> String {
        var possiblyUnique = self
        var uniqueNumber = 1
        while otherStrings.contains(possiblyUnique) {
            possiblyUnique = self + " \(uniqueNumber)"
            uniqueNumber += 1
        }
        return possiblyUnique
    }
}
