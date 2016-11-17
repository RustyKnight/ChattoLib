//
//  APIUtilities.swift
//  ChattoLib
//
//  Created by Shane Whitehead on 17/11/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

func onMainThreadDoLater(_ later: @escaping () -> Void) {
	DispatchQueue.main.async {
		later()
	}
}
