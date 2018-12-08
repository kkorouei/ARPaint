//
//  Drawing+CoreDataProperties.swift
//  ARPaint
//
//  Created by Koushan Korouei on 26/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//
//

import Foundation
import CoreData


extension Drawing {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Drawing> {
        return NSFetchRequest<Drawing>(entityName: "Drawing")
    }

    @NSManaged public var worldMap: NSData
    @NSManaged public var screenShot: NSData
    @NSManaged public var dateCreated: NSDate
    @NSManaged public var name: String

}
