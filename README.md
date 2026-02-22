CAD Project (VGA Display Controller)
Overview

This project implements a VGA display controller using FPGA. It is designed to work with a 24 MHz clock signal, and it provides outputs to control the VGA's red, green, blue color channels, horizontal, and vertical synchronization signals. Additionally, it provides input for controlling keys, switches, LEDs, and 7-segment displays.

This project is based on the VHDL language and is intended for educational and practical use in FPGA-based systems.

Features

VGA Display Controller: Provides color and sync signals for VGA display.

Key & Switch Inputs: Allows interaction with the system via keys and switches.

LED Control: Outputs to control LEDs based on user inputs.

7-Segment Display: Outputs for driving a 7-segment display for visual representation.

Hardware Requirements

FPGA (e.g., Xilinx, Altera)

VGA display

7-segment display

LEDs and switches

24 MHz clock signal

Software Requirements

Xilinx Vivado or any VHDL-compatible simulator

FPGA development board

VHDL Components
CAD Entity

The main entity of the project is CAD. This entity has the following ports:

CLOCK_24: 24 MHz clock input

RESET_N: Active-low reset signal

VGA_R, VGA_G, VGA_B: RGB color output for VGA display

VGA_HS, VGA_VS: Horizontal and Vertical sync signals for VGA

Key: 4-bit input for keys (used for interaction)

SW: 8-bit input for switches

Leds: 8-bit output for LEDs

outseg: Output for 7-segment display segments

sevensegments: 7-segment display output

VGA Controller Component

This component is responsible for controlling the VGA output based on the inputs and clock signals. It generates the necessary color and sync signals for displaying images on the screen.

How to Use

Setup FPGA: Load the VHDL code onto the FPGA development board.

Connect VGA: Connect the VGA cable to the VGA output pins.

Input Devices: Connect switches and keys for user input.

LEDs: Connect LEDs to indicate various statuses.

7-Segment Display: Connect a 7-segment display to visualize output values.

Pin Assignment Example
VGA_R <= VGA_R_port;
VGA_G <= VGA_G_port;
VGA_B <= VGA_B_port;
VGA_HS <= VGA_HS_port;
VGA_VS <= VGA_VS_port;
