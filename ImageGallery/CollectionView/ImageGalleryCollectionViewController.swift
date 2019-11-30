import UIKit


class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,
    UICollectionViewDropDelegate,
    UICollectionViewDragDelegate,
    Removeable
{
 
    // MARK: - Model
    
    var galleryName = String()
    
    private lazy var gallery = Gallery(name: galleryName)
    
    // MARK: - Private API
    
    private var imageFetcher: ImageFetcher!
    
    private var scale: CGFloat = 1 { didSet { flowLayout?.invalidateLayout() }}
    
    @IBOutlet private weak var trashView: TrashView! { didSet {
        trashView.delegate = self
        }}
    
    // MARK: - ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinching(_:))))
        navigationItem.title = galleryName
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(gallery.name)"), let jsonData = try? Data(contentsOf: url),let newValue = Gallery(json: jsonData) {
            gallery = newValue
        }
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
        if recognizer.state == .changed || recognizer.state == .ended {
            scale *= recognizer.scale
            recognizer.scale = 1.0
            print("scale = \(scale)")
        }
    }
 
    private var calculatedWidth: CGFloat {
        return (collectionView.bounds.width/2 - 2)*scale
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
                imageFetcher = ImageFetcher() { (url,image) in
                let width = image.size.width
                let height = image.size.height
                let aspectRatio = width/height
                DispatchQueue.main.async {
                    self.collectionView.performBatchUpdates({
                        self.gallery.images.append(Image(url: url, aspectRatio: Double(aspectRatio)))
                        self.collectionView.insertItems(at: [IndexPath(item: self.gallery.images.count-1, section: 0)])
                        self.saveGallery()
                    } )
                }
            }
                coordinator.session.loadObjects(ofClass: NSURL.self) { nsurls in
                if let firstURL = nsurls.first as? URL {
                    self.imageFetcher.fetch(firstURL.imageURL)
                }
            }
            }
        }
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
        session.localContext = indexPath
        return dragItems(at: indexPath)
     }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
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
    
    func remove(at indexPath: IndexPath) {
        collectionView.performBatchUpdates({
            gallery.images.remove(at: indexPath.item)
            collectionView.deleteItems(at: [indexPath])
            saveGallery()
        })
     }
    
    private func saveGallery() {
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(galleryName)"),let json = gallery.json {
            try? json.write(to: url)
        }
    }
  
}

