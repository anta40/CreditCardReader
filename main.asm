; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
    include \masm32\include\masm32rt.inc
; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

comment * -----------------------------------------------------
                     Build this console app with
                  "MAKEIT.BAT" on the PROJECT menu.
        ----------------------------------------------------- *

include     \masm32\include\hid.inc
include     \masm32\include\setupapi.inc

includelib  \masm32\lib\hid.lib
includelib  \masm32\lib\setupapi.lib

VendorID    EQU 0801h
ProductID   EQU 0002h

SP_DEVICE_INTERFACE_DATA struct
    CbSize      DWORD   ?
    ClassGuid   GUID    <>
    Flags       DWORD   ?
    Reserved    ULONG   ?
SP_DEVICE_INTERFACE_DATA ends

HIDD_ATTRIBUTES         struct
    HSize       DWORD   ?
    VendorID    WORD    ?
    ProductID   WORD    ?
    VersionNumber   WORD	?
HIDD_ATTRIBUTES         ends

HIDP_CAPS               struct
    Usagea      USHORT  ?
    UsagePage   USHORT  ?
    InputReportByteLength   USHORT  ?
    OutputReportByteLength  USHORT  ?
    FeatureReportByteLength USHORT  ?
    Reserved    USHORT  17 dup (?)
    NumberLinkCollectionNodes   USHORT  ?
    NumberInputButtonCaps   USHORT  ?
    NumberInputValueCaps    USHORT  ?
    NumberInputDataIndices  USHORT  ?
    NumberOutputButtonCaps  USHORT  ?
    NumberOutputValueCaps   USHORT  ?
    NumberOutputDataIndices USHORT  ?
    NumberFeatureButtonCaps USHORT  ?
    NumberFeatureValueCaps  USHORT  ?
    NumberFeatureDataIndices    USHORT  ?
HIDP_CAPS               ends

.data    

    ReportBuffer    DWORD   ?
    HandleToDevice  HANDLE  ?
    HDevInfo        HANDLE  ?
    HIDHandle       HANDLE  ?
    HID_GUID        GUID   <>
    DeviceInterfaceData SP_DEVICE_INTERFACE_DATA <>
    HIDAttributes   HIDD_ATTRIBUTES <>
    HIDCapabilities HIDP_CAPS <>
    OverlappedBuffer    OVERLAPPED  <>

.code

start:
   
; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

    call    DetectDevice
    xor     ebx, ebx
    mov     bx, HIDCapabilities.InputReportByteLength
    mov     ReportBuffer, halloc(ebx)                                    
    invoke  ReadFile, HIDHandle, ReportBuffer, ebx, NULL, ADDR OverlappedBuffer ; TODO ERROR #5 - Access Denied
    hfree   ReportBuffer
    invoke  CloseHandle, HIDHandle
    exit

; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

DetectDevice    proc

    local   index:dword
    local   DeviceInterfaceDetailData:dword
    local   ReqLength:dword
    local   HIDPreparsedData:dword

    invoke  HidD_GetHidGuid, ADDR HID_GUID                                  ; Get the GUID for all system USB HID devices
    invoke  SetupDiGetClassDevs, ADDR HID_GUID, NULL, NULL, 12h                   ; Receive a handle to the device information set for all installed devices
                                                                            ; 12h = DIGCF_DEVICEINTERFACE (10h) | DIGCF_PRESENT (02h)    
    mov     HDevInfo, eax
    .if     eax == INVALID_HANDLE_VALUE
    print   "Unable to get device information set handle",13,10,0
    exit
    .endif
    mov     index, 0
detection_start:
    mov     HandleToDevice, INVALID_HANDLE_VALUE
    mov     DeviceInterfaceData.CbSize, SIZEOF DeviceInterfaceData
    invoke  SetupDiEnumDeviceInterfaces, HDevInfo, NULL, ADDR HID_GUID, index, ADDR DeviceInterfaceData ; Query the device using the index to get the interface data
    .if     eax == 0                                                        ; If no more HID devices at the root hub - LastError = ERROR_NO_MORE_ITEMS
    jmp     search_loop_exit                                                ; Go out from the device search loop
    .endif
    invoke  SetupDiGetDeviceInterfaceDetail, HDevInfo, ADDR DeviceInterfaceData, NULL, 0, ADDR ReqLength, NULL ; Obtain the length of the detailed data structure                
    mov     DeviceInterfaceDetailData, halloc(ReqLength)                    ; Allocate memory for SP_DEVICE_INTERFACE_DETAIL_DATA structure
    mov     eax, 5                                                          ; and set appropriate length for each device path
    mov     ebx, DeviceInterfaceDetailData
    mov     [ebx], eax
    invoke  SetupDiGetDeviceInterfaceDetail, HDevInfo, ADDR DeviceInterfaceData, DeviceInterfaceDetailData, ReqLength, ADDR ReqLength, NULL
    .if     eax == 0
    print   "Possible ERROR_INVALID_USER_BUFFER (cbSize/OS conflict)?",13,10,0
    .endif
    mov     eax, DeviceInterfaceDetailData
    add     eax, 4
    mov     ebx, FILE_SHARE_READ
    or      ebx, FILE_SHARE_WRITE
    invoke  CreateFile, eax, 0, ebx, NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL
    mov     HandleToDevice, eax
    .if     eax == INVALID_HANDLE_VALUE
    print   "Bad handle on create file",13,10,0
    .endif
    mov     HIDAttributes.HSize, SIZEOF HIDAttributes                       ; Create HIDD_ATTRIBUTES structure
    invoke  HidD_GetAttributes, HandleToDevice, ADDR HIDAttributes          ; Fill HIDD_ATTRIBUTES structure
    .if     eax == 0
    print   "Unable to build HIDD_ATTRIBUTES",13,10,0
    .endif
    .if     HIDAttributes.VendorID == VendorID && HIDAttributes.ProductID == ProductID
    print   "Device found",13,10,0
    jmp     search_loop_exit
    .else
    invoke  CloseHandle, HandleToDevice
    .endif
    inc     index                                                           ; Check the next HID device for the valid VID and PID
    jmp     detection_start
search_loop_exit:    
    invoke  SetupDiDestroyDeviceInfoList, HDevInfo
    mov     eax, HandleToDevice                                             ; Save Handle to the opened device
    mov     HIDHandle, eax
    .if     eax == INVALID_HANDLE_VALUE
    print   "Device not found",13,10,0
    .else
    invoke  HidD_GetPreparsedData, HandleToDevice, ADDR HIDPreparsedData
    invoke  HidP_GetCaps, HIDPreparsedData, ADDR HIDCapabilities
    .endif
    hfree   DeviceInterfaceDetailData
    ret

DetectDevice    endp


; ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

end start
