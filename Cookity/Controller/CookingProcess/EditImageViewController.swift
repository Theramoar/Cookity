//
//  EditImageViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 05/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class EditImageViewController: UIViewController {

    
    
    @IBOutlet weak var editedImageView: UIImageView!
    @IBOutlet weak var editedView: UIView!
    var heightConstraintInitialValure: CGFloat!
    
    
    @IBOutlet weak var viewForLayers: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    var panStartPoint = CGPoint(x: 0, y: 0)
    var panEndPoint = CGPoint(x: 0, y: 0)
    
    @IBOutlet weak var importImage: UIButton!
    @IBOutlet weak var deleteImage: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var editedImage: UIImage?
    var parentVC: CookViewController?
    
    
    
    override func viewDidLoad() {
        heightConstraintInitialValure = heightConstraint.constant
        super.viewDidLoad()
        if editedImage == nil {
            shrinkView()
        }
        
        let dismissTapGesture = UIPanGestureRecognizer(target: self, action: #selector(backgroundViewDragged))
        dismissTapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissTapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        if let image = editedImage {
            editedImageView.image = image
        }
        setCornerRadius()
    }
    
    @objc func backgroundViewDragged(sender: UITapGestureRecognizer) {
        switch sender.state {
        case .began:
            panStartPoint = sender.location(in: view)
        case .ended:
            panEndPoint = sender.location(in: view)
        default:
            break
        }
        
        guard (panEndPoint.y - panStartPoint.y) > 40, abs(panStartPoint.x - panEndPoint.x) < 40 else { return }
        
        shadow.removeFromSuperview()
        self.dismiss(animated: true, completion: nil)
    }

    
    func expandView() {
        setCornerRadius()
        editedImageView.isHidden = false
        self.heightConstraint.constant = heightConstraintInitialValure
        
        importImage.setTitle("Change Image", for: .normal)
        deleteImage.isHidden = false
        deleteImage.isEnabled = true
    }
    
    func shrinkView() {
        
        heightConstraint.constant -= editedImageView.frame.size.height
        
        self.importImage.setTitle("Add Image", for: .normal)
        self.deleteImage.isHidden = true
        self.deleteImage.isEnabled = false
        self.editedImageView.isHidden = true
        
        UIView.animate(withDuration: 0.4) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    func setCornerRadius() {
        let size = CGSize(width: 20, height: 20)

        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = UIBezierPath(roundedRect: editedView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size).cgPath
        let imageShapeLayer = CAShapeLayer()
        imageShapeLayer.path = UIBezierPath(roundedRect: editedImageView.bounds, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: size).cgPath

        self.editedView.layer.addSublayer(shapeLayer)
        self.viewForLayers.layer.mask = shapeLayer
        self.editedImageView.layer.mask = imageShapeLayer
        
    }
    
    
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        parentVC?.pickedImage = nil
        editedImage = nil
        shrinkView()
    }
    
    @IBAction func importButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let takePhotoAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .default) { _ in
                self.showImagePicker(withSourceType: .camera)
            }
            alert.addAction(takePhotoAction)
        }
        
        let chooseFromLibraryAction = UIAlertAction(title: NSLocalizedString("Choose From Library", comment: ""), style: .default) { _ in
            self.showImagePicker(withSourceType: .photoLibrary)
        }
        alert.addAction(chooseFromLibraryAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        shadow.removeFromSuperview()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        parentVC?.pickedImage = editedImage
        shadow.removeFromSuperview()
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension EditImageViewController: UIImagePickerControllerDelegate {
    
    func showImagePicker(withSourceType source: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = source
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if editedImage == nil {
            expandView()
        }
        editedImage = image
        editedImageView.image = image
        
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UINavigationControllerDelegate
extension EditImageViewController: UINavigationControllerDelegate { }
