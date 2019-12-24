import UIKit


class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,
    UICollectionViewDropDelegate,
    UICollectionViewDragDelegate,
    BinViewDelegate
{
 
    // MARK: - Model
    
    var galleryName = String()

    // MARK: - Private API
    
    private lazy var gallery = Gallery(name: galleryName)
    
    private var imageURL: URL?
    private var imageAspectRatio:Double?
    
    @IBOutlet private weak var trashView: BinView! { didSet { trashView.delegate = self }}
    
    // MARK: - ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinching(_:))))
        navigationItem.title = galleryName
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(gallery.name)"), let jsonData = try? Data(contentsOf: url),let newValue = Gallery(json: jsonData) {
            gallery = newValue
            saveGallery()
            collectionView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveGallery()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        flowLayout?.invalidateLayout()
    }
    
    // MARK: - CollectionView datasourse
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gallery.images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageGallery", for: indexPath)
        if let imageGalleryCell = cell as? ImageGalleryCollectionViewCell {
            imageGalleryCell.url = gallery.images[indexPath.item].url
            return imageGalleryCell
        }
        return cell
    }

    
    // MARK: - CollectionViewFlowLayout delegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let ratio = CGFloat(gallery.images[indexPath.item].aspectRatio)
        return CGSize(width: calculatedWidth,
                     height: calculatedWidth/ratio)
    }

    
    private var flowLayout: UICollectionViewFlowLayout? {
        collectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    // MARK: - Gestures
    
    @objc private func pinching(_ recognizer:UIPinchGestureRecognizer) {
        if recognizer.state == .changed  {
            gallery.scale *= Double(recognizer.scale)
            recognizer.scale = 1.0
            flowLayout?.invalidateLayout()
            if gallery.scale <= Constants.lowerBound { gallery.scale = Constants.lowerBound }
            if gallery.scale >= Constants.upperBound { gallery.scale = Constants.upperBound}
        } else if recognizer.state == .ended {
            saveGallery()
        }
    }
    
    private var calculatedWidth: CGFloat {
        let itemsCount = CGFloat(round(Constants.upperBound/gallery.scale))
        return (collectionView.bounds.width/itemsCount-4)
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "image",
            let destination = segue.destination as? ImageViewController,
            let currentCell = sender as? ImageGalleryCollectionViewCell,
            let index = collectionView.indexPath(for: currentCell)
        {
            destination.url = gallery.images[index.item].url
        }
    }
    
    
    // MARK: - UIDropInteraction delegate

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourseIndexPath = item.sourceIndexPath { // local case
                if let image = item.dragItem.localObject as? Image {
                    collectionView.performBatchUpdates({
                        gallery.images.remove(at: sourseIndexPath.item)
                        gallery.images.insert(image, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourseIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                        saveGallery()
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else {//outer case
                let placeholder = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "placeholder"))
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            self.imageAspectRatio = Double(image.size.width/image.size.height)
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider,error) in
                    DispatchQueue.main.async {
                        if let url = provider as? URL {
                            self.imageURL = url.imageURL
                        }
                        if self.imageAspectRatio != nil && self.imageURL != nil {
                            placeholder.commitInsertion { indexPath in
                                self.gallery.images.insert(Image(url: self.imageURL!, aspectRatio: self.imageAspectRatio!), at: indexPath.item)
                                self.saveGallery()
                            }
                        } else {
                            placeholder.deletePlaceholder()
                        }
                    }
            }
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = session.localDragSession?.localContext == nil
        return UICollectionViewDropProposal(operation:isSelf ? .copy : .move,intent: .insertAtDestinationIndexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if session.localDragSession?.localContext == nil { // outside
            return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self) && !galleryName.isEmpty
        } else { // local
            return session.canLoadObjects(ofClass: UIImage.self)
        }
    }
  
    
    // MARK: - UIDragInteractionDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = [indexPath]
        return dragItems(at: indexPath)
     }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        if var paths = session.localContext as? [IndexPath] {
            paths.append(indexPath)
            session.localContext = paths
        }
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath:IndexPath) -> [UIDragItem] {
        if let image = (collectionView.cellForItem(at: indexPath) as? ImageGalleryCollectionViewCell)?.imageView.image {
            let itemProvider = NSItemProvider(object: image)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = gallery.images[indexPath.item]
            return [dragItem]
        } else {
        return []
        }
    }
    
     // MARK: - Protocol
    
    func remove(at indexPaths: [IndexPath]) {
        let indexes = indexPaths.map { Int($0.item)}
        collectionView.performBatchUpdates({
            gallery.images = gallery.images.enumerated().filter { !indexes.contains($0.offset)}.map { $0.element}
            indexPaths.forEach {
                collectionView.deleteItems(at: [$0])
            }
        },completion:{ completed in
            self.saveGallery()
        })
     }
    
    private func saveGallery() {
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(galleryName)"),let json = gallery.json {
            try? json.write(to: url)
        }
    }
  
}

fileprivate struct Constants {
    static let upperBound = 2.0
    static let lowerBound = 0.4
}
