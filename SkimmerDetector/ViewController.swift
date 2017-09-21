//
//  ViewController.swift
//  SkimmerDetector
//
//  Created by Craig Hughes on 9/20/17.
//  Copyright © 2017 Rungie.com. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet weak var versionNumber: UILabel!
    @IBOutlet weak var buildNumber: UILabel!
    @IBOutlet weak var mainTextDisplay: UITextView!

    let bluetoothQueue: DispatchQueue = DispatchQueue(label: "Bluetooth")
    var bluetoothManager: CBCentralManager?
    var peripherals: [String: CBPeripheral] = [:]

    override func viewWillAppear(_ animated: Bool) {
        versionNumber.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        buildNumber.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        mainTextDisplay.text = "Initializing..."
        bluetoothManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func appendMainTextLine(line: String) {
        DispatchQueue.main.async {
            self.mainTextDisplay.text = self.mainTextDisplay.text + "\n" + line
            self.mainTextDisplay.scrollRangeToVisible(NSMakeRange(self.mainTextDisplay.text.count-1, 1))
            print(line)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        appendMainTextLine(line: "Searching for bluetooth devices...")
        bluetoothManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
        appendMainTextLine(line: "\(peripheral.name ?? peripheral.identifier.uuidString): found")
        guard let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? Bool, connectable == true else { return }
        peripherals[peripheral.identifier.uuidString] = peripheral
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error { debugPrint(error); return }

        appendMainTextLine(line: "\(peripheral.name ?? peripheral.identifier.uuidString): connect fail")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error { debugPrint(error); return }

        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error { debugPrint(error); return }

        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) && characteristic.uuid.uuidString.count == 4 {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { debugPrint(error); return }

        guard let value = characteristic.value else { return }
        guard let valueStr = String(data: value, encoding: .utf8) else { return }

        appendMainTextLine(line: "\(peripheral.name ?? peripheral.identifier.uuidString): \(characteristic.uuid) \(valueStr.debugDescription)")
    }
}
