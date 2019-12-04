import UIKit


class ImageFetcherr {
    
    var handler:  (URL,UIImage) -> Void
    
    init(url:URL,handler: @escaping (URL,UIImage) -> Void) {
        self.handler = handler
        fetch(url)
    }
    
    
    private func fetch(_ url:URL) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url) { (data, response, erro) in
            
        }
        task.resume()
    }
    
    
    
}
