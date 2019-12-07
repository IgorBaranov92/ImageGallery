import UIKit


class ImageFetcher {
    
    var handler:  (URL,UIImage) -> Void
    
    init(url:URL,handler: @escaping (URL,UIImage) -> Void) {
        self.handler = handler
        fetch(url)
    }
    
    
    private func fetch(_ url:URL) {
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url.imageURL) { (data, response, error) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let httpResponce = response as? HTTPURLResponse  else { return }
                if error == nil,(200...299).contains(httpResponce.statusCode), let data = data,let image = UIImage(data: data) {
                    self.handler(url,image)
                }
            }
        }
        task.resume()
    }
    
    
    
}
