import UIKit

class ImageGalleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var url: URL? { didSet { updateUI() }}
    
    private func updateUI() {
        if let imageURL = url {
            imageView.backgroundColor = .clear
            imageView.image = nil
            indicator.startAnimating()
            DispatchQueue.global(qos: .userInteractive).async {
                let urlContents = try? Data(contentsOf: imageURL)
                if let data = urlContents, imageURL == self.url {
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(data: data)
                        self.indicator.stopAnimating()
                    }
                }
            }
        }
    }
    
}
