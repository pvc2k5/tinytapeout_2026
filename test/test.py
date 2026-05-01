# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

REG_PRE_L    = 0x00
REG_DUTY_CH0 = 0x02
REG_ENABLE   = 0x0A
REG_DEADTIME = 0x0B

async def reset(dut):
    dut.ena.value    = 1
    dut.ui_in.value  = 0b00001100  # CS_n=1, nFAULT=1
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value  = 1
    await ClockCycles(dut.clk, 10)

async def spi_write(dut, addr, data):
    """Ghi 1 byte vào register"""
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


@cocotb.test()
async def test_reset(dut):
    """Test reset — duty=0 nen out_h phai = 0"""
    dut._log.info("Test 1: Reset")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)
    await ClockCycles(dut.clk, 300)

    out_h = int(dut.uo_out.value) & 0x0F
    assert out_h == 0, f"Expected out_h=0 after reset, got {out_h:04b}"
    dut._log.info("PASS: Reset OK")


@cocotb.test()
async def test_spi_write(dut):
    """Test SPI write khong bi timeout"""
    dut._log.info("Test 2: SPI write")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    # Chi test write khong loi — khong check ket qua
    await spi_write(dut, REG_PRE_L,    0x01)
    await spi_write(dut, REG_DUTY_CH0, 0x80)
    await spi_write(dut, REG_DEADTIME, 0x00)
    await spi_write(dut, REG_ENABLE,   0x0F)
    await ClockCycles(dut.clk, 10)
    dut._log.info("PASS: SPI write OK")


@cocotb.test()
async def test_fault(dut):
    """Test fault protection"""
    dut._log.info("Test 3: Fault protection")
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())
    await reset(dut)

    await spi_write(dut, REG_PRE_L,    0x01)
    await spi_write(dut, REG_DUTY_CH0, 0xFF)
    await spi_write(dut, REG_DEADTIME, 0x00)
    await spi_write(dut, REG_ENABLE,   0x0F)
    await ClockCycles(dut.clk, 600)

    # Keo nFAULT xuong 0
    dut.ui_in.value = 0b00000100  # nFAULT=0, CS_n=1
    await ClockCycles(dut.clk, 10)

    out = int(dut.uo_out.value)
    assert out == 0, f"Expected uo_out=0 during fault, got {out:08b}"
    dut._log.info("PASS: Fault protection OK")
