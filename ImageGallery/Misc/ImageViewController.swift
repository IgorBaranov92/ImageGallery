import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {

    var url: URL? { didSet {
        if view.window != nil {
            fetchImage() }
    }}
    
    @IBOutlet private weak var scrollView: UIScrollView! { didSet {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5.0
        }}
    
    @IBOutlet private weak var imageView:  UIImageView!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.contentSize = imageView.bounds.size
        fetchImage()
    }
    
    private func fetchImage() {
         if let imageURL = url {
            indicator.startAnimating()
            _ = ImageFetcher(url: imageURL) { (url, image) in
                DispatchQueue.main.async { [weak self] in
                    self?.imageView.image = image
                    self?.indicator.stopAnimating()
                }
            }
       }

    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        widthConstraint.constant = scrollView.contentSize.width
        heightConstraint.constant = scrollView.contentSize.height
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
