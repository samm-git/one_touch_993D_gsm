one_touch_993D_gsm
==================
android_manager_client.pl - Prototype of the Open Source client for the Android
Manager Agent by Mobile Action Technology Inc. Based on packet inspection.

Currently it is prototype only and now it is possible only to connect to device,
fetch some phone and contacts information. Sample output provided below:

<pre>
./android_manager_client.pl
TCP Connection Success.
logging in...
Sending information packet...
  TAG_DEVICE_BRAND               TCT
  TAG_DEVICE_MANFR               TCT
  TAG_DEVICE_MODEL               ALCATEL ONE TOUCH 993D
  TAG_DEVICE_IDESIGN             one_touch_993D_gsm
  TAG_DEVICE_DID                 1234567890
  TAG_DEVICE_BUILDNUM            ICECREAM
  TAG_DEVICE_OS_VERNAME          4.0.4
  TAG_DEVICE_OS_VERCODE          15
  TAG_DEVICE_RADIO_VERNAME       unknown
  TAG_DEVICE_KERNEL_VERNAME      3.0.8-perf-00122-g1a5196c android-bld@50718-1 #1 Thu Nov 8 12:34:53 CST 2012
  TAG_AGENT_CID                  0
  TAG_AGENT_VERNAME              2.2.1202.355
  TAG_AGENT_VERCODE              20
Contact Accounts:
  id: 92B59E86, name: '', type: 'com.android.phone'
  id: E67E0EAB, name: 'xxxx@gmail.com', type: 'com.google'
  id: 3938B7DE, name: 'xxxx', type: 'com.skype.contacts.sync'
  id: 3EE079BD, name: 'PHONE', type: 'com.android.localphone'
</pre>