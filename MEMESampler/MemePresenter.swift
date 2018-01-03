//
//  MemePresenter.swift
//  MEMESampler
//
//  Created by tanaka.takaaki on 2016/12/08.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import MEMELib

typealias DidDisconnectedHandler = ((Void) -> (Void))
typealias DidReceiveMemeRealTimeDataHandler = ((MEMERealTimeData) -> (Void))

final class MEMEPresenter {
    
    var didDisconnected: DidDisconnectedHandler?
    var didReceiveMemeRealTimeData: DidReceiveMemeRealTimeDataHandler?
    
    func disconnected(peripheral: CBPeripheral) {
        didDisconnected?()
    }
    
    func memeRealTimeDataReceived(_ data : MEMERealTimeData) {
        didReceiveMemeRealTimeData?(data)
    }
}
