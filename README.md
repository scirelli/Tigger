# CCK Door Sensor


## Notes
```
dfu-util --alt 0 --dfuse-address 0x08000000:leave --download your_firmware.bin
```
**Flags**
--alt 0 (short form -a):
Specifies the alternate setting of the DFU interface. For STM32 chips, the internal flash is typically mapped to alternate setting 0. You can verify this by running dfu-util --list.

--dfuse-address 0x08000000:leave (short form -s):
This is a DfuSe-specific flag used for devices (like STMicroelectronics) that require the host to specify the target memory address.
    0x08000000: The starting memory address for internal flash on the STM32F405.
    :leave: An optional modifier that tells the device to exit DFU mode and start running the new firmware immediately after the flash is finished.

--download your_firmware.bin (short form -D):
Instructs the tool to write (download from the computer to the device) the specified firmware file. 

Additional Useful Long-Form Flags:
    --list (-l): Shows all currently connected DFU-capable devices.
    --device VENDOR:PRODUCT (-d): Targets a specific device by its USB IDs (e.g., --device 0483:df11). This is helpful if you have multiple DFU devices connected.
    --reset (-R): Issues a USB reset signal after the operation is complete. 
