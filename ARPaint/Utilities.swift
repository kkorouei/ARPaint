//
//  Utilities.swift
//  ARPaint
//
//  Created by Koushan Korouei on 25/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

func getDocumentsDirectory() -> URL {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                    .userDomainMask,
                                                    true) as [String]
    return URL(fileURLWithPath: paths.first!)
}
