/*
*  Copyright (c) 2011-2019, Zingaya, Inc. All rights reserved.
*/

import UIKit

protocol PermissionsViewInput: AnyObject, HUDShowable {
    func showSaveButton(_ show: Bool)
    var canWrite: Bool { get set }
    var canEdit: Bool { get set }
    var canEditAll: Bool { get set }
    var canRemove: Bool { get set }
    var canRemoveAll: Bool { get set }
    var canManage: Bool { get set }
}

protocol PermissionsViewOutput: AnyObject, ControllerLifeCycleObserver {
    func permissionsChanged()
    func barButtonPressed()
}

final class PermissionsViewController: UIViewController, PermissionsViewInput, UITableViewDelegate {
    var output: PermissionsViewOutput! // DI
    
    @IBOutlet private weak var saveButton: BarButtonItem!
    @IBOutlet private weak var canWritePermissionView: PermissionView!
    @IBOutlet private weak var canEditPermissionView: PermissionView!
    @IBOutlet private weak var canEditAllPermissionView: PermissionView!
    @IBOutlet private weak var canRemovePermissionView: PermissionView!
    @IBOutlet private weak var canRemoveAllPermissionView: PermissionView!
    @IBOutlet private weak var canManagePermissionView: PermissionView!
    
    var canWrite: Bool {
        get { canWritePermissionView.isAllowed }
        set { canWritePermissionView.isAllowed = newValue }
    }
    var canEdit: Bool {
        get { canEditPermissionView.isAllowed }
        set { canEditPermissionView.isAllowed = newValue }
    }
    var canEditAll: Bool {
        get { canEditAllPermissionView.isAllowed }
        set { canEditAllPermissionView.isAllowed = newValue }
    }
    var canRemove: Bool {
        get { canRemovePermissionView.isAllowed }
        set { canRemovePermissionView.isAllowed = newValue }
    }
    var canRemoveAll: Bool {
        get { canRemoveAllPermissionView.isAllowed }
        set { canRemoveAllPermissionView.isAllowed = newValue }
    }
    var canManage: Bool {
        get { canManagePermissionView.isAllowed }
        set { canManagePermissionView.isAllowed = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.buttonAction = .none
        canWritePermissionView.isAllowedChangedObserver = { [weak self] in
            self?.output.permissionsChanged()
        }
        canEditPermissionView.isAllowedChangedObserver = { [weak self] in
            self?.output.permissionsChanged()
        }
        canEditAllPermissionView.isAllowedChangedObserver = { [weak self] in
            self?.output.permissionsChanged()
        }
        canRemovePermissionView.isAllowedChangedObserver = { [weak self] in
            self?.output.permissionsChanged()
        }
        canRemoveAllPermissionView.isAllowedChangedObserver = { [weak self] in
            self?.output.permissionsChanged()
        }
        canManagePermissionView.isAllowedChangedObserver = { [weak self] in
            self?.output.permissionsChanged()
        }
        output.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        output.viewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output.viewWillDisappear()
    }
    
    @IBAction func saveButtonPressed(_ sender: BarButtonItem) {
        output.barButtonPressed()
    }
    
    // MARK: - PermissionsViewInput
    func showSaveButton(_ show: Bool) {
        saveButton.buttonAction = show ? .save : .none
    }
}
