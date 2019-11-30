import UIKit

class DocumentsTableViewController: UITableViewController,
    UITableViewDragDelegate,
    UITableViewDropDelegate
{

    // MARK: - Model
    var galleries = Galleries() { didSet {
        if let json = galleries.json {
            if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("galleries") {
                try? json.write(to: url)
            }
        }
        }}
    
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documents", for: indexPath)
        
        if let galleryCell = cell as? DocumentTableViewCell {
            if indexPath.section == 0 {
                galleryCell.textField.text = galleries.existing[indexPath.row].name
                galleryCell.completionHandler = {
                    self.change(cell: galleryCell, at: indexPath)
                }
            } else {
                galleryCell.textField.text = galleries.removed[indexPath.row].name
            }
            return galleryCell
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Documents" : "Recently deleted"
    }
  
    // MARK: - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                tableView.performBatchUpdates({
                    galleries.removed.append(galleries.existing[indexPath.row])
                    galleries.existing.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.insertRows(at: [IndexPath(row: galleries.removed.count - 1, section: 1)], with: .fade)
                })
            }
            else  {
                tableView.performBatchUpdates({
                    galleries.removed.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                })
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
          segue.identifier == "showGallery",
          let destination = segue.destination.contents as? ImageGalleryCollectionViewController
        {
            destination.galleryName = galleries.existing[indexPath.row].name
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let cell = sender as? DocumentTableViewCell,
           let indexPath = tableView.indexPath(for: cell),
           indexPath.section == 1 {
            return false
        }
        return true
    }
    
    // MARK: - IBAction
    
    @IBAction func addNewDocument(_ sender: UIBarButtonItem) {
        if galleries.existing.isEmpty { galleries.existing.append(Gallery(name: "Untitled"))}
        else {
            galleries.existing.append(Gallery(name:"Untitled \(galleriesName.count)"))
        }
        
        tableView.insertRows(at: [IndexPath(row: galleries.existing.count - 1, section: 0)], with: .fade)
        tableView.selectRow(at: IndexPath(row: galleries.existing.count - 1, section: 0), animated: true, scrollPosition: .none)
//        if UserDefaults.standard.value(forKey: Constants.lastIndexPath) == nil {
//            UserDefaults.standard.setValue(IndexPath(row: 0, section: 0), forKey: Constants.lastIndexPath)
//        } else {
//            UserDefaults.standard.setValue(IndexPath(row: galleries.existing.count-1, section: 0), forKey: Constants.lastIndexPath)
//        }
        
    }

    // MARK: - Changing gallery name
    
    private func change(cell:DocumentTableViewCell,at indexPath:IndexPath) {
        
        func showErrorAlert(message:String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true) {
            cell.textField.text = self.galleries.existing[indexPath.row].name
            }
        }
            if cell.textField.text == "" {
                showErrorAlert(message: "Gallery name shouldn't be empty")
            } else if galleriesName.contains(cell.textField.text!) {
                showErrorAlert(message: "You alreay have this gallery")
            }
            else {
                galleries.existing[indexPath.row].name = cell.textField.text!
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
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: String.self) && (session.localDragSession?.localContext as? IndexPath)!.section != 1
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: destinationIndexPath?.section == 0 ? .move : .forbidden, intent: .insertAtDestinationIndexPath)
    }
    
}

fileprivate struct Constants {
    static let lastIndexPath = "lastIndexPath"
}
