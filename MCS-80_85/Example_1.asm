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
	0x0000	LXI		SP, 0x9000		0x31
							0x00
							0x90
		;ZEROIZE ADDRESS
	0x0003	LXI		H, 0x0000		0x21
							0x00
							0x00
		;CONFIGURE PIO 0
	0x0006	MVI		A, 0x02			0x3E
							0x02
	0x0008	OUT		0x00			0xD3
							0x00
		;CONFIGURE PIO 1
	0x000A	MVI		A, 0x0F			0x3E
							0x0F
	0x000C	OUT		0x40			0xD3
							0x40
MAINLOOP:
	0x000E	CALL	CMDLOCKON			0xCD
							0x66
							0x00
		;DISPLAY ADDRESS
	0x0011	CALL	DISPHL				0xCD
							0x49
							0x00
		;READ DATA FROM ADDRESS
	0x0014	MOV		A, M			0x7E
		;DISPLAY DATA
	0x0015	OUT		0x02			0xD3
							0x02
		;WAIT FOR COMMAND SWITCHES TO ALL BE LOW
	0x0017	CALL	CMDREADZERO			0xCD
							0x75
							0x00
		;TURN COMMAND LOCK LED OFF
	0x001A	CALL	CMDLOCKOFF			0xCD
							0x5F
							0x00
		;WAIT FOR ANY COMMAND SWITCH TO GO HIGH
	0x001D	CALL	CMDREADNONZERO			0xCD
							0x6D
							0x00
CMDLOOP:
		;SAVE COMMAND
	0x0020	MOV		B, A			0x47
		;READ DATA
	0x0021	IN		0x01			0xDB
							0x01
		;DISPLAY DATA
	0x0023	OUT		0x02			0xD3
							0x02
		;SAVE DATA
	0x0025	MOV		C, A			0x4F
		;READ COMMAND
	0x0026	IN		0x03			0xDB
							0x03
		;COMMAND == ZERO?
	0x0028	CPI		0xC0			0xFE
							0xC0
	0x002A	JNZ		CMDLOOP			0xC2
							0x20
							0x00
		;TURN COMMAND LOCK LED ON
	0x002D	CALL	CMDLOCKON			0xCD
							0x66
							0x00
		;GET COMMAND INDEX
	0x0030	MOV		A, B			0x78
	0x0031	CALL	CMDINDEX			0xCD
							0x7D
							0x00
		;INVALID COMMAND?
	0x0034	JC		MAINLOOP		0xDA
							0x0E
							0x00
		;SAVE RETURN ADDRESS ON STACK
	0x0037	LXI		D, MAINLOOP		0x11
							0x0E
							0x00
	0x003A	PUSH	D				0xD5
		;CALCULATE ADDRESS OF COMMAND'S COMMAND TABLE ENTRY
	0x003B	PUSH	H				0xE5
	0x003C	LXI		H, CMDTABLE		0x21
							0x8F
							0x00
	0x003F	MVI		D, 0x00			0x16
							0x00
	0x0041	MOV		E, A			0x5F
	0x0042	DAD		D			0x19
		;LOAD COMMAND'S ADDRESS FROM COMMAND TALBE
	0x0043	MOV		E, M			0x5E
	0x0044	INX		H			0x23
	0x0045	MOV		D, M			0x56
		;
	0x0046	POP		H			0xE1
		;SAVE COMMAND'S ADDRESS ON STACK
	0x0047	PUSH	D				0xD5
		;"CALL" COMMAND
	0x0048	RET					0xC9
	
DISPHL:
	;DISPLAY VALUE IN HL
	0x0049	MOV		A, L			0x7D
	0x004A	OUT		0x41			0xD3
							0x41
	0x004C	MOV		A, H			0x7C
	0x004D	OUT		0x42			0xD3
							0x42
	0x004F	RET					0xC9

CMDADDRDEC:
	;DECREMENT THE ADDRESS IN HL
	0x0050	DCX		H			0x2B
	0x0051	RET					0xC9
	
CMDADDRHIGHSET:
	;SET THE HIGH-ORDER BYTE OF THE ADDRESS
	0x0052	MOV		H, C			0x61
	0x0053	RET					0xC9
			
CMDADDRINC:
	;INCREMENTS THE ADDRESS IN HL
	0x0054	INX		H			0x23
	0x0055	RET					0xC9

CMDADDRLOWSET:
	;SET THE LOW-ORDER BYTE OF THE ADDRESS
	0x0056	MOV		L, C			0x69
	0x0057	RET					0xC9
			
CMDDATASET:
	;WRITE THE VALUE IN C TO THE ADDRESS IN RAM SPECIFIED BY HL
	0x0058	MOV		M, C			0x71
	0x0059	RET					0xC9
			
CMDEXEC:
	;TRANSFERS CONTROL TO THE ADDRESS IN HL
		;PLACE RETURN ADDRESS ONTO STACK
	0x005A	LXI		D, MAINLOOP		0x11
							0x0E
							0x00
	0x005D	PUSH	D				0xD5
		;TRANSFER CONTROL TO ADDRESS IN HL
	0x005E	PCHL					0xE9

CMDLOCKOFF:
	;TURN COMMAND LOCK LED OFF
	0x005F	IN		0x43			0xDB
							0x43
	0x0061	ANI		0xFE			0xE6
							0xFE
	0x0063	OUT		0x43			0xD3
							0x43
	0x0065	RET					0xC9

CMDLOCKON:
	;TURN COMMAND LOCK LED ON
	0x0066	IN		0x43			0xDB
							0x43
	0x0068	ORI		0x01			0xF6
							0x01
	0x006A	OUT		0x43			0xD3
							0x43
	0x006C	RET					0xC9

CMDREADNONZERO:
		;READ COMMAND
	0x006D	IN		0x03			0xDB
							0x03
		;COMMAND == ZERO?
	0x006F	CPI		0xC0			0xFE
							0xC0
	0x0071	JZ		CMDREADNONZERO		0xCA
							0x6D
							0x00
	0x0074	RET					0xC9

CMDREADZERO:
	;WAITS FOR THE COMMAND SWITCHES TO ALL GO INACTIVE
		;READ COMMAND
	0x0075	IN		0x03			0xDB
							0x03
		;COMMAND == ZERO?
	0x0077	CPI					0xFE
							0xC0
		;COMMAND ZERO?
	0x0079	JNZ		CMDREADZERO		0xC2
							0x75
							0x00
	0x007C	RET					0xC9
	
CMDINDEX:
	;RETURNS THE INDEX OF THE COMMAND IN A
	0x007D	MVI		B, 0x06			0x06
							0x06
CMDINDEXA:
	0x007F	RAR					0x1F
	0x0080	JC		CMDINDEXB		0xDA
							0x8A
							0x00
	0x0083	DCR		B			0x05
	0x0084	JNZ		CMDINDEXA		0xC2
							0x7F
							0x00
	0x0087	STC					0x37
	0x0088	MOV		A, B			0x78
	0x0089	RET					0xC9
CMDINDEXB:
	0x008A	MVI		A, 0x06			0x3E
							0x06
	0x008C	SUB		B			0x90
	0x008D	RAL					0x17
	0x008E	RET					0xC9
			
BASECMDTABLE:
	0x008F	DW		CMDADDRLOWSET		0x56
							0x00
	0x0091	DW		CMDADDRHIGHSET		0x52
							0x00
	0x0093	DW		CMDADDRDEC		0x50
							0x00
	0x0095	DW		CMDADDRINC		0x54
							0x00
	0x0097	DW		CMDDATASET		0x58
							0x00
	0x0099	DW		CMDEXEC			0x5A
							0x00
