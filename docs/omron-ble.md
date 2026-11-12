# Omron BLE support

Fjelia reads stored blood-pressure records from model profiles adapted from
[userx14/omblepy](https://github.com/userx14/omblepy), revision
`7e502b71c8a152767e452affb243e4cb442c34d3`. The upstream author granted the
Fjelia maintainer permission to adopt the implementation. Keep this attribution
with future ports and changes.

The current profiles are HEM-6232T, HEM-7143T, HEM-7150T, HEM-7155T,
HEM-7156T, HEM-7280T, HEM-7322T, HEM-7342T, HEM-7361T, HEM-7377T,
HEM-7380T, HEM-7381T, HEM-7530T and HEM-7600T. Two model families described
as encrypted by omblepy (HEM-7188T and HEM-7196T) are not decoded. The model
must be selected accurately because many Omron monitors share BLE services but
use different EEPROM layouts.

The import reads all configured user record slots and deduplicates them in the
local blood-pressure table. It deliberately does not set the device clock or
reset its unread-record counter. First pairing on classic profiles writes a
random 128-bit key through the Omron unlock characteristic; the app asks for
confirmation and stores the key in platform secure storage. Pairing may replace
the monitor's existing phone pairing. Newer OS-bond-only profiles rely on the
platform's native Bluetooth pairing flow.

The BLE search also supports the Bluetooth SIG Blood Pressure service
(`1810`) and its Blood Pressure Measurement characteristic (`2A35`). When the
OMRON optional service (`5DF5…`) is present, Fjelia follows the vendor app's
Telehealth transfer: enable `2A35` notifications and receive the monitor's
saved records. This path deliberately does not write RACP; doing so made the
HEM-7361T-ESL reject the count request with an ATT error. Generic BP monitors
without the OMRON optional service use the standard RACP count (`04 01`) and
report (`01 01`) sequence. Neither path deletes records or starts a cuff
measurement. Records
without a device timestamp are skipped so historic values are never assigned
the import time. The database requires a pulse field; records without pulse
are retained with heart rate `0`, which is treated as unavailable in summaries.
Scan results are ranked by advertised service UUID, but advertising is only a
hint: compatibility is verified against the connected device's GATT services.
Devices that do not advertise their services appear as unverified until the
user tries to read them.

The scanner and record parsers have been checked statically. The notification
transfer still needs confirmation on the physical HEM-7361T-ESL; generic RACP,
pairing and device-specific layouts also need physical verification. Do not
advertise every listed model as device-tested until each profile has been
validated with a real device.
