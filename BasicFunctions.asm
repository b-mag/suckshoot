
z_hl equ z_Regs
z_l  equ z_Regs+1
z_h  equ z_Regs+0

z_bc equ z_Regs+2
z_c  equ z_Regs+3
z_b  equ z_Regs+2

z_de equ z_Regs+4
z_e  equ z_Regs+5
z_d  equ z_Regs+4

z_As equ z_Regs+6
z_Hs equ z_Regs+7

z_ixl equ z_Regs+9
z_ixh equ z_Regs+8
z_ix equ z_Regs+8

z_iyl equ z_Regs+11
z_iyh equ z_Regs+10
z_iy  equ z_Regs+10

z_spec equ z_Regs+12 ; Used for D during Z80 emu routines


t_SP     	equ z_Regs+8
t_RetAddr 	equ z_Regs+9
t_RetAddrL 	equ z_Regs+10
t_RetAddrH 	equ z_Regs+9
t_A     	equ z_Regs+11
t_X     	equ z_Regs+12
t_Y     	equ z_Regs+14

t_MemdumpL     	equ z_Regs+14
t_MemdumpH     	equ z_Regs+15

t_MemdumpBL     	equ z_Regs+16
t_MemdumpBH     	equ z_Regs+17

CLDIR0:		
		lda #0	
CLDIR:	;Clear LDIR
		ldy z_hl
		STA ,y
		
		leay 1,y		;INCY
		sty z_de
	
		
LDIR:		
		ldu z_bc
		ldx z_hl
		ldy z_de
LDIR2:			
        LDA ,X+;lda ,X+
        STA ,Y+;sta ,Y+
		leau -1,u		;Dec U
		BNE LDIR2
		rts
		
		
		
		
IncBC:
	INC z_c
	BNE	IncBC_Done
	INC	z_b
IncBC_Done:
	rts
	
IncDE:
	INC z_e
	BNE	IncDE_Done
	INC	z_d
IncDE_Done:
	rts
	
IncHL:
	INC z_l
	BNE	IncHL_Done
	INC	z_h
IncHL_Done:
	rts
				
DecBC:	
	
	tst z_c
	bne DecBC_b
	DEC z_b
DecBC_b:	
	DEC z_c
	
	rts
				
DecHL:		
	tst z_l
	bne DecHL_h
	DEC z_h
DecHL_h:	
	DEC z_l
	rts
	
DecDE:		
	tst z_e
	bne DecDE_D
	DEC z_d
DecDE_D:	
	DEC z_e
	rts
	
AddHL_DE:				;Add DE to HL
	; clc
;AdcHL_DE				;Add DE to HL
	ldd z_hl
	addd z_de
	std z_hl
	rts
		
AddHL_0C:		
		clr z_b
AddHL_BC:			;Add BC to HL
		; clc
		ldd z_hl
		addd z_bc
		std z_hl
		rts
		
SubHL_BC:			;Subtract BC to HL
		; sec
		ldd z_hl
		subd z_bc
		std z_hl
		rts
SubHL_DE:			;Subtract BC to HL
		ldd z_hl
		subd z_de
		std z_hl
		rts
		
AddDE_BC:			;Add DE to HL
	ldd z_de
	addd z_bc
	std z_de
		rts
		
SwapNibbles:		;$AB -> $BA
		ASLa 		;(shift left - bottom bit zero)
		ADCa #$80 	;(pop top bit off - add carry)
		ROLa 		;(shift carry in)
		;2 bits moved
		ASLa 		;(shift left - bottom bit zero)
		ADCa #$80 	;(pop top bit off - add carry)
		ROLa 		;(shift carry in)
		;4 bits moved
		rts
		
		
		
		
		