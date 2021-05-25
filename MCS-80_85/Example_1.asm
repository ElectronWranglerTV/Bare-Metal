;* MCS-80/85 BARE METAL BOOTSTRAP EXAMPLE #1
;* Copyright (CF) DeRemee Systems, IXE Electronics LLC
;* Portions copyright IXE Electronics LLC, Republic Robotics, FemtoLaunch, FemtoSat, FemtoTrack, Weland
;* This work is made available under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
;* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

;Required hardware:
;Breadboard and a whole mess of wires
;1x Intel 8085 or equivalent
;2x Intel 8155 or equivalent
;3x 8-position DIP switches
;3x 74244 or equivalent OR 24x 1k ohm resistors (used for DIP switches)
;1x 74139 or equivalent (not needed if slightly different addressing scheme is used)
;1x 7414 or equivalent (not needed if clock is supplied by external source)
;1x 10uF capacitor (not needed if clock is supplied by external source)
;1x 10 ohm resistor (not needed if clock is supplied by external source)
;Capacitor & resistor values may vary based on desired clock period

;This code serves as a nice first step in bringing up a system having only volatile memory such as RAM.
;Using this short program, additional code can be loaded into RAM easier than direct manipulation of
;the system address, data, and control busses.

;The first step is to load this program into system RAM using front-panel style switches and LEDs.
;After this is complete, the switches and LEDs can be disconnected from the system busses then connected
;to the relevant ports on the PIO ICs.

;Six commands are implemented:
;1 = Load address LSB
;2 = Load address MSB
;3 = Decrement address
;4 = Increment address
;5 = Data write
;6 = Execute code

;Each time the address is changed, the data at the new address is displayed.
;The 'Execute code' command transfers control to the currently displayed address via the equivalent of a CALL.

;I/O MAP
;0x00	= PIO 0 C/S
;0x01	= PIO 0 PA		- DATA IN
;0x02	= PIO 0 PB		- DATA OUT
;0x03	= PIO 0 PC		- COMMAND IN
;0x04	= PIO 0 TMRL
;0x05	= PIO 0 TMRH

;0x40	= PIO 1 C/S
;0x41	= PIO 1 PA		- ADDRESS LOW OUT
;0x42	= PIO 1 PB		- ADDRESS HIGH OUT
;0x43	= PIO 1 PC		- STATUS OUT
;0x44	= PIO 1 TMRL
;0x45	= PIO 1 TMRH

			;INITIALIZE STACK POINTER
	0x0000	LXI		SP, 0x0000			0x31
										0x00
										0x00
			;CONFIGURE PIO 0
	0x0003	MVI		A, 0x02				0x3E
										0x02
	0x0005	OUT		0x00				0xD3
										0x00
			;CONFIGURE PIO 1
	0x0007	MVI		A, 0x0F				0x3E
										0x0F
	0x0009	OUT		0x40				0xD3
										0x40
MAINLOOP:
				;TURN COMMAND LOCK LED ON
	0x000B	IN		0x43				0xDB
										0x43
	0x000D	ORI		0x01				0xF6
										0x01
	0x000F	OUT		0x43				0xD3
										0x43
			;ZEROIZE ADDRESS
	0x0011	LXI		H, 0x0000			0x21
										0x00
										0x00
			;DISPLAY ADDRESS
	0x0014	MOV		A, L				0x7D
	0x0015	OUT		0x41				0xD3
										0x41
	0x0017	MOV		A, H				0x7C
	0x0018	OUT		0x42				0xD3
										0x42
			;READ DATA FROM ADDRESS
	0x001A	MOV		A, M				0x7E
			;DISPLAY DATA
	0x001B	OUT		0x02				0xD3
										0x02
CMDLOOPA:
			;READ COMMAND
	0x001D	IN		0x03				0xDB
										0x03
			;COMMAND == ZERO?
	0x001F	CPI							0xFE
										0xC0
			;COMMAND ZERO?
	0x0021	JNZ		CMDLOOPA			0xC2
										0x1D
										0x00
			;TURN COMMAND LOCK LED OFF
	0x0024	IN		0x43				0xDB
										0x43
	0x0026	ANI		0xFE				0xE6
										0xFE
	0x0028	OUT		0x43				0xD3
										0x43
CMDLOOPB:
			;READ COMMAND
	0x002A	IN		0x03				0xDB
										0x03
			;COMMAND == ZERO?
	0x002C	CPI		0xC0				0xFE
										0xC0
	0x002E	JZ		CMDLOOPB			0xCA
										0x2A
										0x00
CMDLOOPC:
			;SAVE COMMAND
	0x0031	MOV		B, A				0x47
			;READ DATA
	0x0032	IN		0x01				0xDB
										0x01
			;DISPLAY DATA
	0x0034	OUT		0x02				0xD3
										0x02
			;SAVE DATA
	0x0036	MOV		C, A				0x4F
			;READ COMMAND
	0x0037	IN		0x03				0xDB
										0x03
			;COMMAND == ZERO?
	0x0039	CPI		0xC0				0xFE
										0xC0
	0x003B	JNZ		CMDLOOPC			0xC2
										0x31
										0x00
			;TURN COMMAND LOCK LED ON
	0x003E	IN		0x43				0xDB
										0x43
	0x0040	ORI		0x01				0xF6
										0x01
	0x0042	OUT		0x43				0xD3
										0x43
			;COMMAND == ADDRESS LOW SET?
	0x0044	MOV		A, B				0x78
	0x0045	RAR							0x1F
	0x0046	JNC		CMDLOOPD			0xD2
										0x4D
										0x00
			;COPY DATA TO ADDRESS LOW
	0x0049	MOV		L, C				0x69
	0x004A	JMP		MAINLOOP			0xC3
										0x0B
										0x00
CMDLOOPD:
			;COMMAND == ADDRESS HIGH SET?
	0x004D	RAR							0x1F
	0x004E	JNC		CMDLOOPE			0xD2
										0x55
										0x00
			;COPY DATA TO ADDRESS HIGH
	0x0051	MOV		H, C				0x61
	0x0052	JMP		MAINLOOP			0xC3
										0x0B
										0x00
CMDLOOPE:
			;COMMAND == ADDRESS DECREMENT?
	0x0055	RAR							0x1F
	0x0056	JNC		CMDLOOPF			0xD2
										0x5D
										0x00
			;DECREMENT ADDRESS
	0x0059	DCX		H					0x2B
	0x005A	JMP		MAINLOOP			0xC3
										0x0B
										0x00
CMDLOOPF:
		;COMMAND == ADDRESS INCREMENT?
	0x005D	RAR							0x1F
	0x005E	JNC		CMDLOOPG			0xD2
										0x65
										0x00
		;INCREMENT ADDRESS
	0x0061	INX		H					0x23
	0x0062	JMP		MAINLOOP			0xC3
										0x0B
										0x00
CMDLOOPG:
		;COMMAND == DATA WRITE?
	0x0065	RAR							0x1F
	0x0066	JNC		CMDLOOPH			0xD2
										0x6E
										0x00
	
	0x0069	MOV		A, C				0x79
	0x006A	MOV		M, A				0x77
	0x006B	JMP		MAINLOOP			0xC3
										0x0B
										0x00
CMDLOOPH:
		;COMMAND == EXECUTE?
	0x006E	RAR							0x1F
	0x006F	JNC		MAINLOOP			0xD2
										0x0B
										0x00
		;SAVE RETURN ADDRESS
	0x0072	LXI		D, MAINLOOP			0x11
										0x0B
										0x00
	0x0075	PUSH	D					0xD5
		;TRANSFER CONTROL TO ADDRESS
	0x0076	PCHL						0xE9
