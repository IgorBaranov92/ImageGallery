import UIKit

class DocumentsTableViewController: UITableViewController,
    UITableViewDragDelegate,
    UITableViewDropDelegate
{

    // MARK: - Model
    var galleries = Galleries() { didSet { saveGalleries() }}
    
    private var row:Int { UserDefaults.standard.integer(forKey: Constants.lastRow) }
    private var firstLaunch = true
    private var scaledFont:UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(name: "Cochin", size: 25)!)
    }
    
    
    private var galleriesName: [String] {
        return galleries.existing.map {String($0.name) } + galleries.removed.map {String($0.name) }
    }
    
    
    
    // MARK: - ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("galleries"), let jsonData = try? Data(contentsOf: url),let newValue = Galleries(json: jsonData) {
            galleries = newValue
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if row >= 0 && firstLaunch && !galleries.existing.isEmpty {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .bottom)
            performSegue(withIdentifier: "showGallery", sender: self)
            firstLaunch = false
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if splitViewController?.preferredDisplayMode != .primaryOverlay {
            splitViewController?.preferredDisplayMode = .primaryOverlay
        }
    }
    
    // MARK: - TableViewDatasourse
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? galleries.existing.count : galleries.removed.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
          return section == 0 ? nil : galleries.removed.count == 0 ? nil : "Recently deleted"
      }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documents", for: indexPath)
        
        if let galleryCell = cell as? DocumentTableViewCell {
            if indexPath.section == 0 {
                galleryCell.textField.font = scaledFont
                galleryCell.textField.text = galleries.existing[indexPath.row].name
                galleryCell.completionHandler = { [weak self,unowned galleryCell] in
                    self?.change(cell: galleryCell, at: indexPath)
                }
                galleryCell.isUserInteractionEnabled = true
            } else {
                galleryCell.textField.text = galleries.removed[indexPath.row].name
                galleryCell.isUserInteractionEnabled = false
            }
            return galleryCell
        }
        return cell
    }
    
    // MARK: - TableViewDelegate
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.set(indexPath.row, forKey: Constants.lastRow)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return scaledFont.pointSize*2
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return scaledFont.pointSize
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                tableView.performBatchUpdates({
                    galleries.removed.append(galleries.existing[indexPath.row])
                    galleries.existing.remove(at: indexPath.row)
                    UserDefaults.standard.set(indexPath.item-1, forKey: Constants.lastRow)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.insertRows(at: [IndexPath(row: galleries.removed.count - 1, section: 1)], with: .fade)
                })
                tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
                performSegue(withIdentifier: Constants.segueID, sender: self)
            }
            else  {
                tableView.performBatchUpdates({
                    if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(galleries.removed[indexPath.row].name)"),let json = galleries.removed[indexPath.row].json {
                        galleries.removed[indexPath.row].images.removeAll()
                        try? json.write(to: url)
                    }
                    galleries.removed.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    if galleries.removed.isEmpty {
                        tableView.reloadData()
                    }
                })
                performSegue(withIdentifier: Constants.segueID, sender: self)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let undeleteAction = UIContextualAction(style: .normal, title: "Undelete") { (_, _, done) in
            self.tableView.performBatchUpdates({
                self.galleries.existing.append(self.galleries.removed[indexPath.row])
                self.galleries.removed.remove(at: indexPath.row)
                self.tableView.insertRows(at: [IndexPath(row: self.galleries.existing.count-1, section: 0)], with: .fade)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            })
            if self.galleries.removed.isEmpty {
                tableView.reloadData()
            }
            UserDefaults.standard.set(self.galleries.existing.count-1, forKey: Constants.lastRow)
            self.performSegue(withIdentifier: Constants.segueID, sender: self)
            done(true)
        }
        undeleteAction.backgroundColor = .blue
        let swipeConfig = UISwipeActionsConfiguration(actions: [undeleteAction])
        return indexPath.section == 0 ? nil : swipeConfig
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if let cell = sender as? DocumentTableViewCell,
          let indexPath = tableView.indexPath(for: cell),
          indexPath.section == 0,
          segue.identifier == Constants.segueID,
          let destination = segue.destination.contents as? ImageGalleryCollectionViewController
        {
            destination.galleryName = galleries.existing[indexPath.row].name
        } else if sender as? DocumentsTableViewController == self,
                  segue.identifier == Constants.segueID,
                  let destination = segue.destination.contents as? ImageGalleryCollectionViewController {
            if row >= 0 {
                destination.galleryName = galleries.existing[row].name
            }
        }
    }
    
    
    // MARK: - IBAction
    
    @IBAction func addNewDocument(_ sender: UIBarButtonItem) {
        let galleryName = "Untitled".madeUnique(withRespectTo: galleriesName)
        galleries.existing.append(Gallery(name: galleryName))
        tableView.insertRows(at: [IndexPath(row: galleries.existing.count - 1, section: 0)], with: .fade)
        tableView.selectRow(at: IndexPath(row: galleries.existing.count - 1, section: 0), animated: true, scrollPosition: .bottom)
        UserDefaults.standard.set(galleries.existing.count - 1, forKey: Constants.lastRow)
        performSegue(withIdentifier: Constants.segueID, sender: self)
    }

    
    // MARK: - Changing gallery name
    
    
    private func change(cell:DocumentTableViewCell,at indexPath:IndexPath) {
        if cell.textField.text == "" {
            let alert = UIAlertController(title: "Error", message: "Gallery name shouldn't be emplty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else if galleriesName.contains(cell.textField.text!) {
            let alert = UIAlertController(title: "Error", message: "You already have this gallery", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(galleries.existing[indexPath.row].name)"),let json = galleries.existing[indexPath.row].json,let newURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(cell.textField.text!)"),let newJSON = try? Data(contentsOf: url) {
                let gallery = Gallery(json: json)!
                galleries.existing.remove(at: indexPath.row)
                galleries.existing.insert(Gallery(name: cell.textField.text!, scale: gallery.scale, images: gallery.images), at: indexPath.row)
                try? newJSON.write(to: newURL)
            }
            UserDefaults.standard.set(indexPath.item, forKey: Constants.lastRow)
            performSegue(withIdentifier: Constants.segueID, sender: self)
        }
    }
    
    
    // MARK: - Drag&Drop delegates
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = indexPath
        if let text = (tableView.cellForRow(at: indexPath) as? DocumentTableViewCell)?.textField.text {
            let itemProvider = NSItemProvider(object: text as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = text
            return [dragItem]
        }
        return []
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: 0, section: 0)
        for item in coordinator.items {
            if let sourseIndexPath = item.sourceIndexPath, let text = item.dragItem.localObject as? String {
                tableView.performBatchUpdates({
                    galleries.existing.remove(at: sourseIndexPath.row)
                    galleries.existing.insert(Gallery(name: text), at: destinationIndexPath.row)
                    tableView.deleteRows(at: [sourseIndexPath], with: .fade)
                    tableView.insertRows(at: [destinationIndexPath], with: .fade)
                },completion: { completed in
                    UserDefaults.standard.set(destinationIndexPath.item, forKey: Constants.lastRow)
                    self.performSegue(withIdentifier: Constants.segueID, sender: self)
                })
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: String.self) && (session.localDragSession?.localContext as? IndexPath)!.section != 1
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: destinationIndexPath?.section == 0 ? .move : .forbidden, intent: .insertAtDestinationIndexPath)
    }
    
    private func saveGalleries () {
        if let json = galleries.json {
            if let url = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil, create: true)
                .appendingPathComponent("galleries") {
                try? json.write(to: url)
            }
        }
    }
    
}

fileprivate struct Constants {
    static let lastRow = "lastRow"
    static let segueID = "showGallery"
}
