import UIKit


class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,
    UICollectionViewDropDelegate,
    UICollectionViewDragDelegate
{

    var gallery = [Image]()
    var galleryName = String()
    
    private var imageFetcher: ImageFetcher!
    
    private var scale: CGFloat = 1 { didSet { flowLayout?.invalidateLayout() }}
    
    // MARK: - ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
         let im1 = Image(url: URL(string:
        "http://www.planetware.com/photos-large/F/france-paris-eiffel-tower.jpg")!,
        aspectRatio: 0.67)
        gallery.append(im1)
        let im2 = Image(url: URL(string:
        "https://adriatic-lines.com/wp-content/uploads/2015/04/canal-of-Venice.jpg")!,
        aspectRatio: 1.5)
        gallery.append(im2)
        let im3 = Image(url: URL(string:
        "http://www.picture-newsletter.com/arctic/arctic-12.jpg")!,
        aspectRatio: 0.8)
        gallery.append(im3)
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinching(_:))))
        navigationItem.title = galleryName
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        flowLayout?.invalidateLayout()
    }
    
    // MARK: - CollectionView datasourse
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gallery.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageGallery", for: indexPath)
        if let imageGalleryCell = cell as? ImageGalleryCollectionViewCell {
            imageGalleryCell.url = gallery[indexPath.item].url
            
        }
    
        return cell
    }

    
    // MARK: - CollectionViewFlowLayout delegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        print(calculatedWidth/CGFloat(gallery[indexPath.item].aspectRatio))
        return CGSize(width: calculatedWidth,
                     height: calculatedWidth/CGFloat(gallery[indexPath.item].aspectRatio))
    }

    
    private var flowLayout: UICollectionViewFlowLayout? {
        collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    // MARK: - Gestures
    
    @objc private func pinching(_ recognizer:UIPinchGestureRecognizer) {
        if recognizer.state == .changed || recognizer.state == .ended {
            scale *= recognizer.scale
            recognizer.scale = 1.0
        }
    }
 
    private var calculatedWidth: CGFloat {
        collectionView.bounds.width/3*scale
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "image", let destination = segue.destination as? ImageViewController, let currentCell = sender as? ImageGalleryCollectionViewCell, let index = collectionView.indexPath(for: currentCell) {
                destination.url = gallery[index.item].url
        }
    }
    
    
    // MARK: - UIDropInteraction delegate

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
//        if coordinator.session.localDragSession == nil { // outside
//            imageFetcher = ImageFetcher() { (url,image) in
//                let width = image.size.width
//                let height = image.size.height
//                let aspectRatio = width/height
//                self.gallery.append(Image(url: url, aspectRatio: Double(aspectRatio)))
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
//            }
//            coordinator.session.loadObjects(ofClass: NSURL.self) { nsurls in
//                if let firstURL = nsurls.first as? URL {
//                    self.imageFetcher.fetch(firstURL.imageURL)
//                }
//            }
//      } else { // local
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourseIndexPath = item.sourceIndexPath { // local case
                if let image = item.dragItem.localObject as? Image {
                    collectionView.performBatchUpdates({
                        gallery.remove(at: sourseIndexPath.item)
                        gallery.insert(image, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourseIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {//outer case
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(
                        insertionIndexPath: destinationIndexPath,
                        reuseIdentifier: "placeholder"))
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    DispatchQueue.main.async {
                        placeholderContext.commitInsertion { insertionIndexPath in
                            if let image = provider as? UIImage,let url = provider as? URL {
                                let imageWidth = Double(image.size.width)
                                let imageHeight = Double(image.size.height)
                                let aspectRatio =  imageWidth/imageHeight
                                self.collectionView.performBatchUpdates({
                                    self.gallery.insert(Image(url: url, aspectRatio: aspectRatio), at: insertionIndexPath.item)
                                    self.collectionView.insertItems(at: [insertionIndexPath])
                                })
                                
                            } else {
                                placeholderContext.deletePlaceholder()
                            }
                        }
                    }
                }
            }
        }
      //  }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation:isSelf ? .move : .copy,intent: .insertAtDestinationIndexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if session.localDragSession?.localContext == nil { // outside
            return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
        } else { // local
            return session.canLoadObjects(ofClass: UIImage.self)
        }
    }
  
    
    // MARK: - UIDragInteractionDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
     }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath:IndexPath) -> [UIDragItem] {
        if let image = (collectionView.cellForItem(at: indexPath) as? ImageGalleryCollectionViewCell)?.imageView.image {
            let itemProvider = NSItemProvider(object: image)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = gallery[indexPath.item]
            return [dragItem]
        } else {
        return []
        }
    }
        
}

