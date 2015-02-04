CreditCardReader
================

Utility to demonstrate reading of HID credit card swipers.

Assembles for 32-bit Windows with MASM32 (http://www.masm32.com/) and is thus governed by the MASM32 license/requirements.

TODO:

- Detects device, but fails to actually read data from the card swiper with Error #5 "Access Denied".  Same issue found with the Java/JNA version of the code.  Yet, the VB version works.  Possibly try serial mode instead, if supported?

Bug reports from adeyblue:
- Fix memory leak - DeviceInterfaceDetailData released just before return from DetectDevice, but is allocated multiple times in a loop inside DetectDevice.
- Magic number that might already exist as a variable - Line 106 "mov eax, 5" to set the device path length perhaps should be using "ReqLength"?  Code functions fine, so perhaps ReqLength is always 5 on Win32?  Or perhaps code is correct this way and can't actually use ReqLength?
