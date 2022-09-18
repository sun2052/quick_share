// broadcast address
const String BROADCAST = '255.255.255.255';

// broadcast type
const int BROADCAST_DISCOVER = 1;
const int BROADCAST_RESPONSE = 2;
const int BROADCAST_QUIT = 3;

// message type
const int MESSAGE_UNKNOWN = 0;
const int MESSAGE_TEXT = 1;
const int MESSAGE_DATA = 2;
const int MESSAGE_REQUEST_DATA = 3;
const int MESSAGE_SEND_DATA = 4;
const int MESSAGE_NOT_SUPPORTED = 5;

// message status
const int STATUS_UNKNOWN = 0;
const int STATUS_COMPLETED = 1;
const int STATUS_EXPIRED = 2;
const int STATUS_PENDING = 3;
const int STATUS_TRANSFERRING = 4;

// device type
const int DEVICE_UNKNOWN = 0;
const int DEVICE_DESKTOP = 1;
const int DEVICE_MOBILE = 2;

// uuid string length
const int UUID_LENGTH = 16 * 2 + 4;
