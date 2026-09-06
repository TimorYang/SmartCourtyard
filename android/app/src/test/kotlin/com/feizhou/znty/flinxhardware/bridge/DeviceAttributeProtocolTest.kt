package com.feizhou.znty.flinxhardware.bridge

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class DeviceAttributeProtocolTest {
  @Test
  fun `parses new auto close attribute with its one-byte wire width`() {
    val attributes = DeviceAttributeProtocol.parse(
      byteArrayOf(
        0x27, 0x12, 0x29,
        0x27, 0x25, 0x00, 0x09,
      ),
    )

    assertEquals(2, attributes.size)
    assertEquals(0x2712L, attributes[0].id)
    assertArrayEquals(byteArrayOf(0x29), attributes[0].value)
    assertEquals(0x2725L, attributes[1].id)
    assertArrayEquals(byteArrayOf(0x00, 0x09), attributes[1].value)
  }

  @Test
  fun `parses legacy one-byte 0x2712 before a following attribute`() {
    val attributes = DeviceAttributeProtocol.parse(
      byteArrayOf(
        0x27, 0x12, 0x09,
        0x27, 0x25, 0x00, 0x09,
      ),
    )

    assertEquals(2, attributes.size)
    assertEquals(0x2712L, attributes[0].id)
    assertArrayEquals(byteArrayOf(0x09), attributes[0].value)
    assertEquals(0x2725L, attributes[1].id)
    assertArrayEquals(byteArrayOf(0x00, 0x09), attributes[1].value)
  }

  @Test
  fun `encodes auto close attribute 0x2712 as one byte`() {
    val payload = DeviceAttributeProtocol.encode(
      listOf(DeviceAttributeDto(0x2712, byteArrayOf(0x29))),
    )

    assertArrayEquals(byteArrayOf(0x27, 0x12, 0x29), payload)
  }

  @Test
  fun `rejects legacy and read-only auto close writes`() {
    assertThrows(IllegalArgumentException::class.java) {
      DeviceAttributeProtocol.encode(
        listOf(DeviceAttributeDto(0x2725, byteArrayOf(0x00, 0x09))),
      )
    }
    assertThrows(IllegalArgumentException::class.java) {
      DeviceAttributeProtocol.encode(
        listOf(DeviceAttributeDto(0x2712, byteArrayOf(0x01, 0x09))),
      )
    }
    assertThrows(IllegalArgumentException::class.java) {
      DeviceAttributeProtocol.encode(
        listOf(DeviceAttributeDto(0x2714, byteArrayOf(0x01))),
      )
    }
    assertThrows(IllegalArgumentException::class.java) {
      DeviceAttributeProtocol.encode(
        listOf(DeviceAttributeDto(0x2728, byteArrayOf(0x0A))),
      )
    }
  }
}
