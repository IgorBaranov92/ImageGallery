import UIKit

class DocumentsTableViewController: UITableViewController {

    var galleries = [Gallery]()
    var removedGalleries = [Gallery]()
    
    private var galleriesName: [String] {
        return galleries.map { String($0.name) } + removedGalleries.map { String($0.name) }
    }
    
    // MARK: - ViewController lifecycle
    
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
        return section == 0 ? galleries.count : removedGalleries.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documents", for: indexPath)
        
        if let galleryCell = cell as? DocumentTableViewCell {
            if indexPath.section == 0 {
                galleryCell.textField.text = galleries[indexPath.row].name
                galleryCell.completionHandler = {
                    self.change(cell: galleryCell, at: indexPath)
                }
            } else {
                galleryCell.textField.text = removedGalleries[indexPath.row].name
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                tableView.performBatchUpdates({
                    removedGalleries.append(galleries[indexPath.row])
                    galleries.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.insertRows(at: [IndexPath(row: removedGalleries.count - 1, section: 1)], with: .fade)
                })
            }
            else  {
                tableView.performBatchUpdates({
                    removedGalleries.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                })
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let undeleteAction = UIContextualAction(style: .normal, title: "Undelete") { (_, _, done) in
            self.tableView.performBatchUpdates({
                self.galleries.append(self.removedGalleries[indexPath.row])
                self.removedGalleries.remove(at: indexPath.row)
                self.tableView.insertRows(at: [IndexPath(row: self.galleries.count-1, section: 0)], with: .fade)
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
            destination.galleryName = galleries[indexPath.row].name
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
        if galleries.isEmpty { galleries.append(Gallery(name: "Untitled"))}
        else {
            galleries.append(Gallery(name: "Untitled \(galleries.count)"))
        }
        tableView.insertRows(at: [IndexPath(row: galleries.count - 1, section: 0)], with: .fade)
    }

    // MARK: - Changing gallery name
    
    private func change(cell:DocumentTableViewCell,at indexPath:IndexPath) {
        
        func showErrorAlert(message:String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true) {
            cell.textField.text = self.galleries[indexPath.row].name
            }
        }
            if cell.textField.text == "" {
                showErrorAlert(message: "Gallery name shouldn't be empty")
            } else if galleriesName.contains(cell.textField.text!) {
                showErrorAlert(message: "You alreay have this gallery")
            }
            else {
                galleries[indexPath.row].name = cell.textField.text!
                }
        }
    
}
