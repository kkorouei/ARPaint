//
//  DrawingsViewController.swift
//  ARPaint
//
//  Created by Koushan Korouei on 27/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

protocol AllDrawingsViewControllerDelegate: class {
    func allDrawingsViewController(_ controller: AllDrawingsViewController, didSelectDrawing drawing: Drawing)
    func allDrawingsViewControllerDidPressCancel(_ controller: AllDrawingsViewController)
}

class AllDrawingsViewController: UIViewController {
    
    var drawings: [Drawing]!
    weak var delegate: AllDrawingsViewControllerDelegate!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func didPressCancelButton(_ sender: UIBarButtonItem) {
        delegate.allDrawingsViewControllerDidPressCancel(self)
    }
}

extension AllDrawingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let drawing = drawings[indexPath.row]
        cell.textLabel?.text = drawing.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drawings.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let drawing = drawings[indexPath.row]
        delegate.allDrawingsViewController(self, didSelectDrawing: drawing)

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let drawing = drawings[indexPath.row]
            PersistenceManager.shared.deleteDrawingFromCoreData(drawing: drawing) { (success, message) in
                if success {
                    print(message)
                    // Remove the drawing from the drawings array
                    drawings.remove(at: indexPath.row)
                    tableView.reloadData()
                } else {
                    // TODO:- Add error
                    print(message)
                }
            }
        }
    }
}
