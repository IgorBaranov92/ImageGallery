import UIKit

class BinView: UIView, UIDropInteractionDelegate {

    weak var delegate: BinViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
        let bin = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolBar = UIToolbar(frame: bounds)
        toolBar.setItems([space,bin], animated: false)
        toolBar.clipsToBounds = true
        addSubview(toolBar)
    }
    
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: session.localDragSession == nil ? .forbidden : .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        if let indexPaths = session.localDragSession?.localContext as? [IndexPath] {
            print(indexPaths)
            delegate?.remove(at: indexPaths)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, previewForDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        let preview = UIDragPreviewTarget(container: self, center: CGPoint(x: bounds.maxX-bounds.height/2, y: bounds.height/2), transform: CGAffineTransform(scaleX: 0.01, y: 0.01))
        return defaultPreview.retargetedPreview(with: preview)
    }
    
}


protocol BinViewDelegate: class {
    func remove(at indexPaths:[IndexPath])
}
