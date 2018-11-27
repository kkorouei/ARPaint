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
    
    @IBAction func didPressCancelButton(_ sender: UIBarButtonItem) {
        delegate.allDrawingsViewControllerDidPressCancel(self)
    }
}

extension AllDrawingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let drawing = drawings[indexPath.row]
        cell.textLabel?.text = "date: \(drawing.dateCreated)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drawings.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let drawing = drawings[indexPath.row]
        delegate.allDrawingsViewController(self, didSelectDrawing: drawing)

    }
}
