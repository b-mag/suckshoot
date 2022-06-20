	include "BasicMacros.asm"	
	
     BSS
     ORG $c880       ; well start of our ram space

;txtScoreRam DS 100


     ;ORG $c980
      ORG $c900

EnemySprite DS 1
EnemyScale DS 1
EnemySpeed DS 1
EnemySpeedb DS 9
SoundTimeOut  DS 7
EnemyX DS 2
EnemyY DS 2;

PlayerX DS 2
PlayerY DS 2


BcdHiscore DS 5
BcdScore DS 5
BcdLives DS 1



z_Regs equ $C0



; The cartridge ROM starts at address 0

     CODE     
     ORG  0 
                DB      "g GCE 2022", $80       ; 'g' is copyright sign
                DW      $FD0D                   ; music from the rom
                DB      $F8, $50, $20, -$55     ; height, width, rel y, rel x
                                                ; (from 0,0)
                DB      "VEC WAR",$80     ; some game information,
                                                ; ending with $80
                 DB      0                       ; end of game header                     ; end of game header 
	
; Switch Direct Page	
	lda #$C8
	tfr a,dp
	jsr ScreenInit
	

;z_Regs equ $C0
;EnemySprite equ $C980	
;EnemyScale equ $C981
;EnemySpeed equ $C982
;EnemySpeedb equ $C983
;SoundTimeOut  equ $C98C
;EnemyX equ $C984
;EnemyY equ $C986

;PlayerX equ $C988
;PlayerY equ $C98A


;BcdHiscore equ $C990
;BcdScore equ $C995
;BcdLives equ $C994
;txtScoreRam equ $C880 


;vars
txtScoreRam DS 100


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	;ASSUME dpr:$C8		;SETDP on other systems $D0= Hardware Regs $C8=Ram
	lda #$C8
	tfr a,dp
	
	ldd #$FC38	;Font Size ($HHWW=$F848 / $FC38)
	std $C82A	;SIZRAS (2 bytes) - Size of Raster Text
	
	
	ldu #BcdHiscore
	ldx #0
	stx ,u++				;Clear the highscore
	stx ,u++
	
	
ShowTitle:
	lda #$d0			;Need DP=$d0 for next command
	tfr a,dp
	
	jsr WaitForRelease	;Wait for fire to be released

	lda #0
	jsr ChibiSound		;Silence sound
	
;Copy Highscore message to ram
	ldx #txtHiscore
	ldy #txtScoreRam
	ldu #(txtHiscore_End-txtHiscore)
	jsr LDIR2

;Update the highscore
	ldu #txtScoreRam+(txtHiscoreB-txtHiscore)
     ;ldu #txtScoreRam
	ldb #4
	ldx #BcdHiscore
	jsr BCD_Show	
	
TitleScreen:
	jsr $F192 ; FRWAIT - Wait for Vblank
	jsr ResetPenPos	;Center 'pen' position, scale=127
	
	lda #$d0				;Need DP=$d0 for next command
	tfr a,dp
	
	ldu #txtSuckShoot		;Show Title
	jsr $F38C	;TXTPOS 
	ldu #txtScoreRam		;Show Highscore
	jsr $F38C	;TXTPOS 
	
	jsr ResetPenPos	;Center 'pen' position, scale=127
	
	lda #192
	sta EnemyScale			;Huge bat!
	
	ldx #0
	ldy #0
	jsr ShowSprite			;Center sprite
	
	jsr ReadJoystick	;Read in the Joystick	%4321UDLR
	bitb #%00010000		;Fire1 Pressed?
	bne TitleScreen		;Wait until it is!
	
	
GamePlay:				;Start a new game
	jsr RandomizeEnemy
	
;	ASSUME dpr:$d0		;SETDP on other systems $D0= Hardware Regs $C8=Ram
	lda #$d0
	tfr a,dp
	
;Copy Score message/Lives message to ram
	ldx #txtScore
	ldy #txtScoreRam
	ldu #(txtScoreEnd-txtScore)
	jsr LDIR2	
	
	lda #$04
	sta BcdLives		;Plater lives
	
	ldu #BcdScore		;Player score
	ldx #0
	stx ,u++
	stx ,u++
	
	stx PlayerX			;Center player
	stx PlayerY
	
	jsr UpdateScore		;Update Score/lives text
		
	lda #32
	sta EnemySpeed		;Bat Move speed
	
	
;Main Game Loop	
InfLoop:				
	lda SoundTimeOut		;Time till silenced
	deca
	bne ChibiSoundUpdated
	jsr ChibiSound			;Make sound A
ChibiSoundUpdated:
	sta SoundTimeOut	
		
	jsr $F192 				; FRWAIT - Wait for Vblank
	
	ldu #txtScoreRam		;Screen Text Buffer (Score / Lives)
	jsr $F38C				;TXTPOS 
	
	jsr ResetPenPos	;Center 'pen' position, scale=127
	
	ldx EnemyX
	ldy EnemyY
	jsr ShowSprite			;Show enemy bat
	
	jsr ResetPenPos	;Center 'pen' position, scale=127
	ldx PlayerX
	ldY PlayerY
	lda #32					;Scale
	jsr ShowTarget			;Show our cursor

	
	
	jsr ReadJoystick	;Read in the Joystick	%4321UDLR
	
	lda #2				;Slow move speed
	bitb #%00100000		;Fire2 Pressed?
	bne JoyNotF2		;Fast Move speed
	lda #8
JoyNotF2:	

	bitb #%00000001
	bne JoyNotUp		;Up Pressed?
	cmpY #120			;At top of screen?
	bge	JoyNotUp
	leay a,y			;Y=Y+1
JoyNotUp:	
	bitb #%00001000	
	bne JoyNotRight		;Right Pressed?
	cmpX #120			;At Right of screen
	bge	JoyNotRight
	leax a,x			;X=X+1
JoyNotRight:		
	nega				;Negative movement
	bitb #%00000010
	bne JoyNotDown		;Down Pressed?
	cmpY #-120			;At bottom of screen?
	blt	JoyNotDown
	leay a,y			;Y=Y-1
JoyNotDown:	
	bitb #%00000100
	bne JoyNotLeft		;Left Pressed?
	cmpX #-120			;At left of screen
	blt	JoyNotLeft
	leax a,x			;X=X-1
JoyNotLeft:	
	
	bitb #%00010000		;Fire1 Pressed?
	bne JoyNotF1
	
	pshs x,y
		lda #%11000001
		jsr ChibiSound		;Make sound A
		lda #8
		sta SoundTimeOut
	
		lda #$C8
		tfr a,dp
	
		jsr rangetestPlayer	;1=Collided
		beq RangeTestDone	;Has player missed?
		
		lda #%11010000
		jsr ChibiSound		;Make sound A
		
		lda EnemySpeed		;Speed up enemy
		adda #1
		sta EnemySpeed
		jsr RandomizeEnemy	;Reposition enemy
		
		ldb #4
		ldx #bcdScoreAdd	;$05 00 00 00
		ldy #BcdScore		;BCD Dest
		jsr BCD_Add			;Add 5 BCD points
		
		jsr UpdateScore
RangeTestDone:
		lda #$d0
		tfr a,dp
	puls x,y
JoyNotF1:		
	
	stX PlayerX				;Update player pos
	stY PlayerY
	
	lda #$C8
	tfr a,dp
	
	lda EnemySpeedb
	adda EnemySpeed			;Enemy move time
	sta EnemySpeedb
	bcc NoEnemyHit
	
	lda EnemyScale
	adda #1					;Make enemy bigger
	sta EnemyScale
	cmpa #64				;Biggest?
	bcs NoEnemyHit
		jsr RandomizeEnemy	;Bat bit us!
		
		lda #%01111000
		jsr ChibiSound		;Make sound A
		lda #8
		sta SoundTimeOut
		
		dec BcdLives		;Player lost a life
		beq GameOver		;No lives left?
		
		jsr UpdateScore		;Update Life count text
NoEnemyHit:	
	
	lda #$d0
	tfr a,dp
	jmp InfLoop
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
GameOver:
	jsr WaitForRelease
	lda #0
	jsr ChibiSound			;Silence sound

	ldb #4					;4 bcd bytes
	ldx #BcdScore			;This score
	ldy #BcdHiscore			;Higest score
	jsr BCD_Cp				;Compare the two
	bcs GameOver_NoScore	;New score higher

	ldx #BcdScore 			;We got a new highscore
	ldy #BcdHiscore 
	ldu #4
	jsr LDIR2	
		
GameOver_HiScore:			;We got a highscore!
	jsr $F192 
	jsr ResetPenPos	
	ldu #txtGotHiScore		;Screen Text Buffer
	jsr $F38C	;TXTPOS 
	jsr ReadJoystick		;Read in the Joystick	%4321UDLR
	bitb #%00010000			;Fire1 Pressed?
	bne GameOver_HiScore
	jmp ShowTitle

txtGotHiScore:	
	DB 32,-48					;Ypos,Xpos (TopLeft)
	DB "GAME OVER",$80
	DB -32,-56				;Ypos,Xpos (TopLeft)
	DB "NEW HISCORE",$80
	
	DB 0	;$80=newline, $0=Strings End

		

GameOver_NoScore:			;No highscore, we officially suck!
	jsr $F192 
	jsr ResetPenPos	
	ldu #txtNoHiScore		;Screen Text Buffer
	jsr $F38C	;TXTPOS 
	jsr ReadJoystick		;Read in the Joystick	%4321UDLR
	bitb #%00010000			;Fire1 Pressed?
	bne GameOver_NoScore
	jmp ShowTitle
	
WaitForRelease:	
	lda #$d0
	tfr a,dp
	jsr ReadJoystick	;Read in the Joystick	%4321UDLR
	bitb #%00010000		;Fire1 Pressed?
	beq WaitForRelease
	rts
	
txtNoHiScore:				;Test string (Ucase only)
	DB 32,-48					;Ypos,Xpos (TopLeft)
	DB "GAME OVER",$80
	DB -32,-48				;Ypos,Xpos (TopLeft)
	DB "YOU SUCK!",$80
	
	DB 0	;$80=newline, $0=Strings End

	
UpdateScore:
	;Update the score
	ldu #txtScoreRam+(txtScoreb-txtScore)
	ldb #4
	ldx #BcdScore
	jsr BCD_Show	
	
	;Update the Lives
	ldu #txtScoreRam+(txtScorec-txtScore)
	ldb #1
	ldx #BcdLives
	jmp BCD_Show	

	
	
	;Title message
txtSuckShoot:						;Test string (Ucase only)
	DB 96,-48					;Ypos,Xpos (TopLeft)
	DB "SUCK SHOOT!",$80,0	;$80=newline, $0=Strings End
	
	
	;Template highscore text
txtHiscore:						;Test string (Ucase only)
	DB -96,-72				;Ypos,Xpos (TopLeft)
	DB "HISCORE:"
txtHiscoreB: DB "12345678",$80,0	;$80=newline, $0=Strings End
txtHiscore_End:	
	
	
	;Ingame HUD
txtScore:
	DB 127,-128				;Ypos,Xpos (TopLeft)
txtScoreb:
	DB "00000000",$80
	DB 127,102				;Ypos,Xpos (TopLeft)
txtScorec:
	DB "01",$80
	DB 0	;$80=newline, $0=Strings End	
txtScoreEnd:	


	;Copy a character to U (in ram)
PrintChar:
	sta ,u+
	rts
	
	
bcdScoreAdd:	;5 points in BCD
	DB $05,$00,$00,$00
	
PacketBat1:			;Bat Frame 1
		;CMD,YYY,XXX
    DB $00,$1C,$00
    DB $FF,$F7,$ED
    DB $FF,$E3,$00
    DB $FF,$01,$00
    DB $FF,$F5,$1C
    DB $FF,$15,$16
    DB $FF,$1C,$F1
    DB $FF,$00,$F2
    DB $00,$F6,$14
    DB $00,$01,$00
    DB $FF,$13,$11
    DB $FF,$F5,$0A
    DB $FF,$06,$0B
    DB $FF,$E1,$02
    DB $FF,$13,$E9
    DB $FF,$F9,$F1
    DB $00,$00,$D4
    DB $FF,$10,$EE
    DB $FF,$F3,$F7
    DB $FF,$08,$F5
    DB $FF,$E0,$FC
    DB $FF,$0E,$16
    DB $FF,$00,$14
    DB $00,$0A,$0F
    DB $FF,$FB,$FB
    DB $FF,$FD,$02
    DB $FF,$00,$01
    DB $FF,$05,$06
    DB $FF,$03,$FB
    DB $00,$02,$0C
    DB $00,$FF,$00
    DB $00,$00,$01
    DB $FF,$00,$07
    DB $FF,$FB,$05
    DB $FF,$FE,$F8
    DB $FF,$07,$FB
    DB $00,$EF,$F2
    DB $00,$FC,$FE
    DB $00,$00,$01
    DB $FF,$06,$21
    DB $01
	
PacketBat2:			;Bat Frame 2	
    DB $00,$1C,$00
    DB $FF,$F7,$ED
    DB $FF,$E3,$00
    DB $FF,$01,$00
    DB $FF,$F5,$1C
    DB $FF,$15,$16
    DB $FF,$1C,$F1
    DB $FF,$00,$F2
    DB $00,$F6,$14
    DB $00,$01,$00
    DB $00,$F1,$DB
    DB $FF,$04,$25
    DB $FF,$EB,$F3
    DB $FF,$12,$E8
    DB $00,$07,$04
    DB $FF,$07,$05
    DB $FF,$FC,$07
    DB $00,$00,$07
    DB $FF,$06,$04
    DB $FF,$FC,$06
    DB $00,$05,$02
    DB $FF,$00,$13
    DB $FF,$E9,$08
    DB $FF,$06,$0F
    DB $FF,$D6,$F8
    DB $FF,$2D,$F0
    DB $FF,$0B,$ED
    DB $00,$F8,$D9
    DB $FF,$08,$F0
    DB $FF,$E4,$F9
    DB $FF,$0C,$ED
    DB $FF,$CF,$0E
    DB $FF,$30,$0E
    DB $FF,$09,$0E
Packet:
    DB $01
	
	
PacketTarget:			;Crosshair
		;CMD,YYY,XXX
    DB $00,$3F,$FA
    DB $FF,$86,$01
    DB $00,$40,$43
    DB $FF,$00,$84
    DB $00,$01,$10
    DB $FF,$1E,$0A
    DB $FF,$0C,$1D
    DB $FF,$00,$01
    DB $FF,$F6,$23
    DB $FF,$E0,$09
    DB $FF,$DE,$F7
    DB $FF,$F4,$DE
    DB $FF,$0B,$DF
    DB $FF,$22,$F8
    DB $01
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPenPos:
	pshs x,d
;Zero the integrators only 		
		jsr $F36B	;ZERO - Zero the integrators only
;Reset Pos /Scale 
		ldx #PositionList	;Position Vector (Y,X)
		ldb #127	;Scale (127=normal 64=half 255=double)
		jsr $F30E	;POSITB - Release integrators and position beam
	puls x,d,pc

PositionList:
	DB 0,0				

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowTarget:		;Draw our Crosshair at (X,Y) size A
	pshs x,y,a
		pshs a
			tfr y,d
			tfr b,a		;Ypos->A
			pshs A
				tfr x,d	;Xpos->B
			puls A
		
			jsr $F312 	;POSITN - Set beam pos to (Y,X) A,B
		puls b

		;B=Scale (127=normal 0=dott 255=double)
		LDX     #PacketTarget     ;Packet address
		jsr $F40E 	;Tpack - Draw according to ‘Packet’ style list

	puls x,y,a
ScreenInit:
	rts
	
ShowSprite:		;Draw our bat at (X,Y) 
	pshs x,y,a
		tfr y,d
		tfr b,a		;Ypos->A
		pshs A
			tfr x,d	;Xpos->B
		puls A
	
		jsr $F312 	;POSITN - Set beam pos to (Y,X) A,B
	
		ldb EnemyScale		;Size
		LDX #PacketBat1     ;Packet address
		
		inc EnemySprite
		lda EnemySprite
		anda #%00010000
		beq Frame1
			LDX #PacketBat2     ;Packet address
Frame1:		
		jsr $F40E 	;Tpack - Draw according to ‘Packet’ style list

	puls x,y,a
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

ReadJoystick:
	pshs x,y,a			
	;Set up Joystick setting
		ldd #$0103 		;Enable Joy 1
		std $C81F		;Epot0/1	
		
		ldd #$0000		;Disable Joy 2 (Doesn't work?)
		std $C821		;Epot2/3
		
		jsr $F1F8		;JOYBIT - Read Up, Down, Left, Right

		lda #255		;Direct response mask
		jsr $F1B4		;DBNCE - Read Buttons 1234 (A=Response mask)
		
	;Convert to 1 bit per button digital (in B)
		ldb $C80F		;4 Fire buttons %----4321
		
		;$C81B - Controller #1: Right / left joystick pot value
		lda $C81B		;LR
		jsr TestOneAxis	
		
		;$C81C - Controller #1: Up / down joystick pot value
		lda $C81C		;UD
		nega			;Flip Y axis so our test works
		jsr TestOneAxis
		
		comb			;Flip bits of B
		tfr b,a
	puls x,y,a
	rts
	
TestOneAxis:	;Test an Axis, and convert to two bits in B
	lslb
	lslb
	cmpa #$40
	bcs TestOneDone
	cmpa #$C0
	bcs TestOneDoneB
	orb #%00000001
	rts
TestOneDoneB:
	orb #%00000010
TestOneDone:	
	rts
	
	
	
;	ASSUME dpr:$C8		;SETDP on other systems $D0= Hardware Regs $C8=Ram
	

	

RandomSeed equ $C900
	
	align 16
;Random number Lookup tables
Randoms1:
	DB $0A,$9F,$F0,$1B,$69,$3D,$E8,$52,$C6,$41,$B7,$74,$23,$AC,$8E,$D5
Randoms2:
	DB $9C,$EE,$B5,$CA,$AF,$F0,$DB,$69,$3D,$58,$22,$06,$41,$17,$74,$83

	
	
RandomizeEnemy:
	pshs dp
		lda #$C8		;Need $C8 Zeropage for DoRandom
		tfr a,dp
		
		jsr DoRandom
		tfr a,b
		clra
		std EnemyX		;AB

		jsr DoRandom
		tfr a,b				
		clra
		std EnemyY		;AB
		
		lda #8			;Default Enemy scale
		sta EnemyScale	
	
	puls dp
	rts	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;The 'RangeTest' function works with unsigned numbers, but our code uses
;Signed ones - we'll convert them to fix the problem

rangetestPlayer:
	ldd PlayerX
	addb #$80		;Convert to unsigned
	stb z_d
	ldd PlayerY
	addb #$80		;Convert to unsigned
	stb z_e
	
	
	ldd EnemyX
	addb #$80		;Convert to unsigned
	stb z_b
	ldd EnemyY
	addb #$80		;Convert to unsigned
	stb z_c
	
	lda #18			;Width
	ldB #8			;Height
	jmp rangetest
	
	
;See if object XY pos zD,zE hits object zB,zC in range zH,zL
;Return A=1 Collision... A!=1 means no collision
rangetest:			
	sta z_h				;Width of range
	stb z_l      		;Height of range
	
	lda z_b				;Pos1 Xpos
	suba z_h			;Shift Pos1 by 'range' to the Left
	bcs rangetestb		;<0
	cmpa z_d			;Does it match Pos2?
	bcc rangetestoutofrange
rangetestb:
	adda z_h			;Shift Pos1 by 'range' to the Right
	adda z_h
	bcs rangetestd		;>255
	cmpa z_d			;Does it match Pos2?
	bcs rangetestoutofrange
	
rangetestd:				;Y Axis Check
	lda z_c				;Pos1 Ypos
	suba z_l			;Shift Pos1 by 'range' Up
	bcs rangetestc		;<0
	cmpa z_e			;Does it match Pos2?
	bcc rangetestoutofrange
rangetestc:
	adda z_l			;Shift Pos1 by 'range' Down
	adda z_l
	bcs rangeteste		;>255
	cmpa z_e			;Does it match Pos2?
	bcs rangetestoutofrange			
rangeteste:
	lda #1				;1=Collided
	rts
rangetestoutofrange:		
	clra				;0=No Collision
	rts
	

	
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include "V1_Random.asm"
	include "BasicFunctions.asm"
	include "AY_V1_ChibiSound.asm"
	
	include "v1_BCD.asm"