/**
 * Appcelerator Titanium Mobile - Bluetooth Low Energy (BLE) Module
 * Copyright (c) 2020 by Axway, Inc. All Rights Reserved.
 * Proprietary and Confidential - This source code is not for redistribution
 */

import UIKit
import TitaniumKit
import CoreBluetooth

/**

 Titanium Swift Module Requirements
 ---

 1. Use the @objc annotation to expose your class to Objective-C (used by the Titanium core)
 2. Use the @objc annotation to expose your method to Objective-C as well.
 3. Method arguments always have the "[Any]" type, specifying a various number of arguments.
 Unwrap them like you would do in Swift, e.g. "guard let arguments = arguments, let message = arguments.first"
 4. You can use any public Titanium API like before, e.g. TiUtils. Remember the type safety of Swift, like Int vs Int32
 and NSString vs. String.

 */

@objc(AppceleratorBleModule)
class AppceleratorBleModule: TiModule {

    // MARK: Constants
    @objc public let CENTREL_MANAGER_EVENT_STATE_UPDATED = "updated"
    @objc public let CENTREL_MANAGER_EVENT_STATE_RESTORE = "restore_state"
    @objc public let CENTREL_MANAGER_EVENT_PERIPHERAL_DISCOVERED = "peripheral_discoverd"

    //setting direct value as CBManagerState is available from ios 10 only
    @objc public let CENTREL_MANAGER_STATE_UNKNOWN = 0
    @objc public let CENTREL_MANAGER_STATE_RESETTING = 1
    @objc public let CENTREL_MANAGER_STATE_UNSUPPORTED = 2
    @objc public let CENTREL_MANAGER_STATE_UNAUTHORIZED = 3
    @objc public let CENTREL_MANAGER_STATE_POWERED_OFF = 4
    @objc public let CENTREL_MANAGER_STATE_POWERED_ON = 5

    @objc public let AUTHORISATION_STATUS_NOT_DETERMINED = 0
    @objc public let AUTHORISATION_STATUS_RESTRICTED = 1
    @objc public let AUTHORISATION_STATUS_DENIED = 2
    @objc public let AUTHORISATION_STATUS_ALLOWED_ALWAYS = 3

    @objc public let ATTRIBUTE_PERMISSION_READABLE = CBAttributePermissions.readable.rawValue
    @objc public let ATTRIBUTE_PERMISSION_WRITEABLE = CBAttributePermissions.writeable.rawValue
    @objc public let ATTRIBUTE_PERMISSION_READ_ENCRYPTION_REQUIRED = CBAttributePermissions.readEncryptionRequired.rawValue
    @objc public let ATTRIBUTE_PERMISSION_WRITE_ENCRYPTION_REQUIRED = CBAttributePermissions.writeEncryptionRequired.rawValue

    @objc public let CHARACTERISTIC_PROPERTIES_BROADCAST = CBCharacteristicProperties.broadcast.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_READ = CBCharacteristicProperties.read.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_WRITE_WITHOUT_RESPONSE = CBCharacteristicProperties.writeWithoutResponse.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_WRITE = CBCharacteristicProperties.write.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_NOTIFY = CBCharacteristicProperties.notify.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_INDICATE = CBCharacteristicProperties.indicate.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_AUTHENTICATED_SIGNED_WRITES = CBCharacteristicProperties.authenticatedSignedWrites.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_EXTENDED_PROPERTIES = CBCharacteristicProperties.extendedProperties.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_NOTIFY_ENCRYPTION_REQUIRED = CBCharacteristicProperties.notifyEncryptionRequired.rawValue
    @objc public let CHARACTERISTIC_PROPERTIES_INDICATE_ENCRYPTION_REQUIRED = CBCharacteristicProperties.indicateEncryptionRequired.rawValue
    // Descriptor UUID
    @objc public let CBUUID_CHARACTERISTIC_EXTENDED_PROPERTIES_STRING = CBUUIDCharacteristicExtendedPropertiesString
    @objc public let CBUUID_CHARACTERISTIC_USER_DESCRIPTION_STRING = CBUUIDCharacteristicUserDescriptionString
    @objc public let CBUUID_CLIENT_CHARACTERISTIC_CONFIGURATION_STRING = CBUUIDClientCharacteristicConfigurationString
    @objc public let CBUUID_SERVER_CHARACTERISTIC_CONFIGURATION_STRING = CBUUIDServerCharacteristicConfigurationString
    @objc public let CBUUID_CHARACTERISTIC_FORMAT_STRING = CBUUIDCharacteristicFormatString
    @objc public let CBUUID_CHARACTERISTIC_AGGREGATE_FORMAT_STRING = CBUUIDCharacteristicAggregateFormatString
    @objc public let CBUUID_L2CAPPSM_CHARACTERISTIC_STRING = "ABDD3056-28FA-441D-A470-55A75A52553A"

    @objc public let PERIPHERAL_STATE_CONNECTED = CBPeripheralState.connected.rawValue
    @objc public let PERIPHERAL_STATE_CONNECTING = CBPeripheralState.connecting.rawValue
    @objc public let PERIPHERAL_STATE_DISCONNECTED = CBPeripheralState.disconnected.rawValue
    @objc public let PERIPHERAL_STATE_DISCONNECTING = 3 //setting direct value as CBPeripheralState.disconnecting is available from ios 9 only

    var _peripheralManager: CBPeripheralManager?

    func moduleGUID() -> String {
        return "8d0b486f-27ff-4029-a989-56e4a6755e6f"
    }

    override func moduleId() -> String! {
        return "appcelerator.ble"
    }

    override func startup() {
        super.startup()
        debugPrint("[DEBUG] \(self) loaded")
    }

    @objc
    func authorizationState() -> NSNumber {
        if #available(iOS 13.1, *) {
            return NSNumber(value: CBCentralManager.authorization.rawValue)
        } else {
            return NSNumber(value: AUTHORISATION_STATUS_NOT_DETERMINED)
        }
    }

    @objc(addService:)
    func addService(arg: Any?) -> TiBLEServiceProxy? {
        guard let values = arg as? [Any],
            let options = values.first as? [String: Any],
            let primary = options["primary"] as? Bool,
            let uuid = options["uuid"] as? String else {
                return nil
        }
        let cbUUID = CBUUID(string: uuid)

        let service = CBMutableService(type: cbUUID, primary: primary)
        var characteristicArray = [CBCharacteristic]()

        if let data = options["data"] as? TiBuffer,
            let properties = options["properties"] as? NSNumber,
            let permission = options["permissions"] as? NSNumber {
            let characteristicData = data.data as Data
            let characteristicPermission: CBAttributePermissions = CBAttributePermissions(rawValue: permission.uintValue)
            let characteristicProperties = CBCharacteristicProperties(rawValue: properties.uintValue)
            let characteristic = CBMutableCharacteristic(type: cbUUID, properties: characteristicProperties, value: characteristicData, permissions: characteristicPermission)
            characteristicArray.append(characteristic)
        }
        if let characteristics = options["characteristics"] as? [TiBLECharacteristicProxy] {
            for object in characteristics {
                characteristicArray.append(object.characteristic())
            }
        }

        service.characteristics = characteristicArray

        _peripheralManager?.add(service)
        return TiBLEServiceProxy(pageContext: self.pageContext, service: service)
    }

    @objc(removeAllServices:)
    func removeAllServices(arg: Any?) {
        _peripheralManager?.removeAllServices()
    }

    @objc(removeServices:)
    func removeServices(arg: Any?) {
        guard let options = arg as? [String: Any],
            let service = options["service"] as? TiBLEServiceProxy else {
                return
        }
        _peripheralManager?.remove(service.mutableService())
    }
    // temp method needed for UT's
    @objc(addDescriptor:)
    func addDescriptor(arg: Any?) -> TiBLEDescriptorProxy? {
        guard let values = arg as? [Any],
            let options = values.first as? [String: Any],
            let value = options["value"],
            let uuid = options["uuid"] as? String else {
                return nil
        }
        var descriptorValue: Any?
        if value is TiBuffer, let data = (value as? TiBuffer)?.data {
            descriptorValue = data
        } else {
            descriptorValue = value
        }
        let cbUUID = CBUUID(string: uuid)
        let mutableDescriptor = CBMutableDescriptor(type: cbUUID, value: descriptorValue)
        return TiBLEDescriptorProxy(pageContext: pageContext, descriptor: mutableDescriptor)
    }

    @objc(addCharacteristic:)
    func addCharacteristic(arg: Any?) -> TiBLEMutableCharacteristicProxy? {
        guard let values = arg as? [Any],
            let options = values.first as? [String: Any],
            let value = options["value"] as? String,
            let properties = options["properties"] as? NSNumber,
            let permission = options["permissions"] as? NSNumber,
            let uuid = options["uuid"] as? String else {
                return nil
        }
        let cbUUID = CBUUID(string: uuid)
        var descriptorArray = [CBDescriptor]()
        let characteristicData = value.data(using: .utf8)
        let characteristicPermission: CBAttributePermissions = CBAttributePermissions(rawValue: permission.uintValue)
        let characteristicProperties = CBCharacteristicProperties(rawValue: properties.uintValue)
        let mutablecharacteristic = CBMutableCharacteristic(type: cbUUID, properties: characteristicProperties, value: characteristicData, permissions: characteristicPermission)
        let descriptor = CBMutableDescriptor(type: cbUUID, value: value)
        descriptorArray.append(descriptor)
        if let descriptor = options["descriptor"] as? [TiBLEDescriptorProxy] {
            for object in descriptor {
                descriptorArray.append(object.descriptor())
            }
        }
        mutablecharacteristic.descriptors = descriptorArray
        return TiBLEMutableCharacteristicProxy(pageContext: pageContext, characteristic: mutablecharacteristic)
    }
    @objc(initCentralManager:)
    func initCentralManager(arg: Any?) -> TiBLECentralManagerProxy? {
        let options = arg as? [String: Any]
        let showPowerAlert = options?["showPowerAlert"] as? Bool
        let restoreIdentifier = options?["restoreIdentifier"] as? String
        let centralManager = TiBLECentralManagerProxy(pageContext: self.pageContext, showPowerAlert: showPowerAlert, restoreIdentifier: restoreIdentifier)
        return centralManager
    }

}
