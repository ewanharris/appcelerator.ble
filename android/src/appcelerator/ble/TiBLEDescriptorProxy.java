/**
 * Appcelerator Titanium Mobile - Bluetooth Low Energy (BLE) Module
 * Copyright (c) 2020 by Axway, Inc. All Rights Reserved.
 * Proprietary and Confidential - This source code is not for redistribution
 */
package appcelerator.ble;

import android.bluetooth.BluetoothGattDescriptor;
import java.util.UUID;
import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import ti.modules.titanium.BufferProxy;

@Kroll.proxy
public class TiBLEDescriptorProxy extends KrollProxy
{
	private BluetoothGattDescriptor descriptor;
	private TiBLECharacteristicProxy characteristicProxy;

	public TiBLEDescriptorProxy(BluetoothGattDescriptor descriptor, TiBLECharacteristicProxy characteristicProxy)
	{
		this.descriptor = descriptor;
		this.characteristicProxy = characteristicProxy;
	}

	//temporary method for descriptor UT.
	//TODO Address or remove this temp method in MOD-2689.
	public static TiBLEDescriptorProxy mockDescriptorForUT(KrollDict dict, TiBLECharacteristicProxy characteristicProxy)
	{
		if (dict.containsKey("permission") && dict.containsKey("uuid")) {
			int permission = (int) dict.get("permission");
			String uuid = (String) dict.get("uuid");

			return new TiBLEDescriptorProxy(new BluetoothGattDescriptor(UUID.fromString(uuid), permission),
											characteristicProxy);
		}
		return null;
	}

	@Kroll.getProperty
	public String uuid()
	{
		return descriptor.getUuid().toString();
	}

	@Kroll.getProperty
	public BufferProxy value()
	{
		return new BufferProxy(descriptor.getValue());
	}

	@Kroll.getProperty
	public TiBLECharacteristicProxy characteristic()
	{
		return characteristicProxy;
	}
}
