# Libcrc API Reference

### `update_crc_ccitt32( crc, c );`

### Parameters

| Parameter | Type | Description |
| :--- | :--- | :--- |
|**`crc`**|`uint32_t`|The CRC value calculated from the byte stream upto but not including the current byte|
|**`c`**|`unsigned char`|The next byte from the byte stream to be used in the CRC calculation|

### Return Value

| Type | Description |
| :--- | :--- |
|**`uint32_t`**|The new CRC value of the byte stream including the current byte|

### Description

The function `update_crc_ccitt()` can be used to calculate the CRC value in a stream of bytes where it is not possible to first buffer the stream completely to calculate the CRC when all data is received. The parameters are the previous CRC value and the current byte which must be used to calculate the new CRC value.

In order for this function to work properly, the CRC value must be initialized before the first call to `update_crc_ccitt32()`. The most common initialization values are `CRC_START_CCITT32_FFFFFFFF` to perform the CRC calculation according to CCITT32 implementations like Terminal Reality POD files.

### See Also

* [`crc_ccitt32_ffffffff();`](crc_ccitt32_ffffffff.md)
* [CRC start values](crc_start.md)
