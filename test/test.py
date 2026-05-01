# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

# Register addresses
REG_PRE_L    = 0x00
REG_PRE_H    = 0x01
REG_DUTY_CH0 = 0x02
REG_DUTY_CH1 = 0x03
REG_DUTY_CH2 = 0x04
REG_DUTY_CH3 = 0x05
REG_ENABLE   = 0x0A
REG_DEADTIME = 0x0B
REG_FAULT_CLR= 0x0C
REG_STATUS   = 0x0D
REG_DEVICE_ID= 0x0E

async def reset(dut):
    dut.ena.value    = 1
    dut.ui_in.value  = 0b00001100  # CS_n=1, nFAULT=1
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value  = 1
    await ClockCycles(dut.clk, 5)

async def spi_write(dut, addr, data):
    byte1 = (0 << 7) | (addr & 0x1F)
    byte2 = data & 0xFF

    dut.ui_in.value = 0b00001000  # CS_n=0, nFAULT=1
    await Timer(100, unit="ns")

    for byte in [byte1, byte2]:
        for i in range(7, -1, -1):
            bit = (byte >> i) & 1
            mosi = bit << 1
            dut.ui_in.value = 0b00001000 | mosi
            await Timer(100, unit="ns")
            dut.ui_in.value = 0b00001001 | mosi  # SCK=1
            await Timer(100, unit="ns")
            dut.ui_in.value = 0b00001000 | mosi  # SCK=0

    await Timer(100, unit="ns")
    dut.ui_in.value = 0b00001100  # CS_n=1
    await Timer(200, unit="ns")

async def spi_read(dut, addr):
    byte1 = (1 << 7) | (addr & 0x1F)
    result = 0

    dut.ui_in.value = 0b00001000  # CS_n=0
    await Timer(100, unit="ns")

    for i in range(7, -1, -1):
        bit = (byte1 >> i) & 1
        mosi = bit << 1
        dut.ui_in.value = 0b00001000 | mosi
        await Timer(100, unit="ns")
        dut.ui_in.value = 0b00001001 | mosi  # SCK=1
        await Timer(100, unit="ns")
        dut.ui_in.value = 0b00001000 | mosi  # SCK=0

    for i in range(7, -1, -1):
        dut.ui_in.value = 0b00001000
        await Timer(100, unit="ns")
        dut.ui_in.value = 0b00001001  # SCK=1
        await Timer(100, unit="ns")
        # Cast LogicArray → int trước khi dùng bitwise
        miso = (int(dut.uio_out.value) >> 7) & 1
        result = (result << 1) | miso
        dut.ui_in.value = 0b00001000

    await Timer(100, unit="ns")
    dut.ui_in.value = 0b00001100  # CS_n=1
    await Timer(200, unit="ns")
    return result


@cocotb.test()
async def test_reset(dut):
    """Test reset — duty=0 nên out_h phải = 0"""
    dut._log.info("Test 1: Reset")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    # Sau reset duty=0 → PWM output = 0
    # Chờ 1 PWM period để counter chạy qua (prescaler=0 → 256 cycle)
    await ClockCycles(dut.clk, 300)

    out_h = int(dut.uo_out.value) & 0x0F
    dut._log.info(f"out_h after reset = 0b{out_h:04b}")
    assert out_h == 0, f"Expected out_h=0 after reset (duty=0), got {out_h:04b}"
    dut._log.info("PASS: Reset OK")


@cocotb.test()
async def test_device_id(dut):
    """Test đọc DEVICE_ID — phải trả về 0x50"""
    dut._log.info("Test 2: Device ID")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    val = await spi_read(dut, REG_DEVICE_ID)
    dut._log.info(f"DEVICE_ID = 0x{val:02X}")
    assert val == 0x50, f"Expected DEVICE_ID=0x50, got 0x{val:02X}"
    dut._log.info("PASS: Device ID OK")


@cocotb.test()
async def test_write_read_duty(dut):
    """Test ghi duty cycle CH0 rồi đọc lại"""
    dut._log.info("Test 3: Write/Read duty cycle")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    await spi_write(dut, REG_DUTY_CH0, 0x80)
    await ClockCycles(dut.clk, 5)

    val = await spi_read(dut, REG_DUTY_CH0)
    dut._log.info(f"DUTY_CH0 = 0x{val:02X}")
    assert val == 0x80, f"Expected DUTY_CH0=0x80, got 0x{val:02X}"
    dut._log.info("PASS: Write/Read duty OK")


@cocotb.test()
async def test_enable_output(dut):
    """Test enable channel và verify PWM output xuất hiện"""
    dut._log.info("Test 4: Enable output CH0")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    await spi_write(dut, REG_PRE_L,    0x01)   # prescaler=1
    await spi_write(dut, REG_DUTY_CH0, 0xFF)   # duty=255 → out_h[0] gần như luôn 1
    await spi_write(dut, REG_DEADTIME, 0x00)   # no dead-time
    await spi_write(dut, REG_ENABLE,   0x0F)   # enable 4 kênh

    await ClockCycles(dut.clk, 600)

    out_h = int(dut.uo_out.value) & 0x0F
    dut._log.info(f"out_h = 0b{out_h:04b}")
    assert out_h & 0x1, f"Expected out_h[0]=1 with duty=255, got {out_h:04b}"
    dut._log.info("PASS: Output enabled OK")


@cocotb.test()
async def test_fault(dut):
    """Test fault protection — kéo nFAULT xuống, output phải tắt"""
    dut._log.info("Test 5: Fault protection")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    await spi_write(dut, REG_PRE_L,    0x01)
    await spi_write(dut, REG_DUTY_CH0, 0xFF)
    await spi_write(dut, REG_DEADTIME, 0x00)
    await spi_write(dut, REG_ENABLE,   0x0F)
    await ClockCycles(dut.clk, 600)

    # Kéo nFAULT xuống 0
    dut.ui_in.value = 0b00000100  # nFAULT=0, CS_n=1
    await ClockCycles(dut.clk, 10)

    out = int(dut.uo_out.value)
    dut._log.info(f"uo_out after fault = 0b{out:08b}")
    assert out == 0, f"Expected uo_out=0 during fault, got {out:08b}"
    dut._log.info("PASS: Fault protection OK")
