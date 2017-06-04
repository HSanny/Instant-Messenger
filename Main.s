 
.equ INPUT_GPIO, 0xFF200060 #JP1
.equ OUTPUT_GPIO, 0xFF200070 #JP2
.equ TIMER_PERIOD, 300
.equ TIMER_ADR, 0xFF202000
.equ RED_LED, 0xFF200000
.equ AUDIO_FIFO, 0xFF203040
.equ PS2Controller1, 0xFF200100
.equ ADDR_VGA,  0x08000000
.equ ADDR_CHAR, 0x09000000
 
.text
LETTER_Convertor:
#make codes for a-z
.byte 0x1c, 0x32, 0x21, 0x23, 0x24, 0x2b, 0x34, 0x33, 0x43, 0x3b, 0x42, 0x4b, 0x3a
.byte 0x31, 0x44, 0x4d, 0x15, 0x2d, 0x1b, 0x2c, 0x3c, 0x2a, 0x1d, 0x22, 0x35, 0x1a
NUMER_Convertor:
#make codes for 0-9
.byte 0x45, 0x16, 0x1e, 0x26, 0x25, 0x2e, 0x36, 0x3d, 0x3e, 0x46
SHIFT_NUM_TRANSFORM:
#ascii codes for )!@#$%^&*(
.byte 0x29, 0x21, 0x40, 0x23, 0x24, 0x25, 0x5e, 0x26, 0x2a, 0x28
SYMBOL_make_codes:
#make codes for `-=[]\;',./ (space)
.byte 0x0e, 0x4e, 0x55, 0x54, 0x5b, 0x5d, 0x4c, 0x52, 0x41, 0x49, 0x4a, 0x29
SYMBOL_ascii:
#ascii for `-=[]\;',./ (space)
.byte 0x60, 0x2d, 0x3d, 0x5b, 0x5d, 0x5c, 0x3b, 0x27, 0x2c, 0x2e, 0x2f, 0x20
SYMBOL_SHIFT_ascii:
#ascii for ~_+{}|:"<>? (space)
.byte 0x7e, 0x5f, 0x2b, 0x7b, 0x7d, 0x7c, 0x3a, 0x22, 0x3c, 0x3e, 0x3f, 0x20
 
SendVal:
.align 2
.skip 200000
EndSendVal:
.word 0x0
 
RecievedInput:
.align 2
.skip 200000
EndRecievedInput:
.word 0x0
 
.global _start
_start:
movia sp, 0x04000000 #initialize sp
mov r20, r0
mov r21, r0 #dont touch this, the number characters in text message
mov r22, r0 #cap status
mov r23, r0
 
#initialize GPIO as input and output
movia r18, OUTPUT_GPIO
movi r19, 0xffffffff
stwio r19, 4(r18)
movia r19, 0x80000000
stwio r19, 0(r18) #start idle interrupt on other machine
 
movia r18, INPUT_GPIO
stwio r0, 4(r18)
movia r19, 0x80000000 #enable interrupt on MSB
stwio r19, 8(r18)
movia r18, INPUT_GPIO
movia r19, 0xffffffff
stwio r19, 12(r18) # De-assert interrupt - write to edge capture reg
 
movia r2, ADDR_VGA
movia r3, ADDR_CHAR
movui r4, 0x0000
call DRAW_SCREEN
movi r4, 0
movi r5, 180
movi r6, 319
movi r7, 181
call DRAW_RECT
	
movi r4, 280
movi r5, 0
movi r6, 281
movi r7, 180
call DRAW_RECT
 
call RESET_TEXT_SCREEN
 
#enable interrupts
movui r18, 0x800 #set IRQ11
wrctl ctl3, r18
movi r18, 1
wrctl ctl0, r18 #enable PIE bit
 
INIT_KEYBOARD:
movia r16, PS2Controller1
	movi r17, 0xFF
	stwio r17, 0(r16)
	call GET_FA_KB
	call GET_AA_KB
 
br Main
 
GET_FA_KB:
addi sp, sp, -16
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
GET_FA_KB_MAIN:
movia r16, PS2Controller1
ldwio r18, 0(r16)	#get the data
movi r17, 0xfa    	#ack
andi r19, r18, 0x8000	#get read data valid
srli r19, r19, 15
beq r19, r0, GET_FA_KB_MAIN
andi r18, r18, 0xff
bne r18, r17, GET_FA_KB_MAIN
 
ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
addi sp, sp, 16
Ret
 
GET_AA_KB:
addi sp, sp, -16
stw r16, 0(sp)
stw r17, 4(sp)
stw r18, 8(sp)
stw r19, 12(sp)
 
GET_AA_KB_MAIN:
movia r16, PS2Controller1
ldwio r18, 0(r16)	#get the data
movi r17, 0xaa	#ack
andi r19, r18, 0x8000	#get read data valid
srli r19, r19, 15
beq r19, r0, GET_AA_KB_MAIN
andi r18, r18, 0xff
bne r18, r17, GET_AA_KB_MAIN
 
ldw r16, 0(sp)
ldw r17, 4(sp)
ldw r18, 8(sp)
ldw r19, 12(sp)
addi sp, sp, 16
ret
 
Main:
	beq r20, r0, NOT_RECIEVED
 
 movia r18, RecievedInput
 
 ldw r19, 0(r18)
 
 beq r19, r0, CALL_AUDIO
 
	call PRINT_RECIEVED_MSG
 
 addi r23, r23, 2
 br CLEAR_RECIEVED
 
CALL_AUDIO:
 call PlayAudio
CLEAR_RECIEVED:
mov r20, r0
NOT_RECIEVED:
	movi r5, 46
	muli r5, r5, 128
 
 mov r8, r21
 movi r9, 80
CHECK_CURSOR_POSITION:
	blt r8, r9, PRINT_CURSOR
	addi r5, r5, 128
	addi r8, r8, -80
	br CHECK_CURSOR_POSITION
 
PRINT_CURSOR:
 
	add r5, r5, r8
	movi r4, 0x5f
	call WRITE_MESSAGE_CHARA
	
	movia r8, PS2Controller1
	ldwio r19, 0(r8)
	andi r18, r19, 0x8000
	srli r18, r18, 15
	beq  r18, r0, Main
	andi r4, r19, 0xff
	
	movi r16, 0xf0
	beq r4, r16, BREAK_CODE
	
	movi r16, 0x12	#Lshift
	beq r4, r16, L_SHIFT_MAKE
	
	movi r16, 0x59	#Rshift
	beq r4, r16, R_SHIFT_MAKE
	
	movi r16, 0x66 	#Backspace
	beq r4, r16, BKSP_handler
	
	movi r16, 0x5a	#enter
	beq r4, r16, ENTER_handler
 
 movi r16, 0x05  #F1 key
 
beq r4, r16, F1_handler
	
	br NOT_SPECIAL_KEY
F1_handler:
 movia r8, SendVal
 stw  r0, 0(r8)
 call ReadAudio
 call WriteOtherDevice
 br Main
	
BKSP_handler:
	beq r21, r0, Main
	movi r5, 46
	muli r5, r5, 128
	add r5, r5, r21
	movi r4, 0x20
	call WRITE_MESSAGE_CHARA
	subi r21, r21, 1
	br Main
ENTER_handler:
	beq r21, r0, Main
	movi r2, 0x7f #end of text
	movia r8, SendVal
	add r8, r8, r21
 
 addi r8, r8, 4
	stb r2, 0(r8)
	call PRINT_SENT_MSG
	call RESET_BOTTOM_SCREEN
	call WriteOtherDevice
	addi r23, r23, 2
	mov r21, r0
	br Main
	
BREAK_CODE:
	movia r8, PS2Controller1
	ldwio r19, 0(r8)
	andi r18, r19, 0x8000
	srli r18, r18, 15
	beq  r18, r0, BREAK_CODE
	andi r4, r19, 0xff
	
	#r4 is the thing to break
	movi r16, 0x12
	beq r4, r16, L_SHIFT_BREAK
	
	movi r16, 0x59
	beq r4, r16, R_SHIFT_BREAK
	
	br Main
	
L_SHIFT_BREAK:
	#set bit 1 of r22 to 0
	movia r16, 0xfffffffd
	and r22, r22, r16
	br Main
	
R_SHIFT_BREAK:
	#set bit 0 of r22 to 0
	movia r16, 0xfffffffe
	and r22, r22, r16
	br Main
	
NOT_SPECIAL_KEY:
	call CONVERTTOASCII
	#store ascii in r2
	movi r5, 46
	muli r5, r5, 128
 
	mov r8, r21
	movi r9, 80
CHECK_INPUT_MESSAGE_LENGTH:
	blt r8, r9, PRINT_SAME_LINE
	addi r5, r5, 128
	addi r8, r8, -80
	br CHECK_INPUT_MESSAGE_LENGTH
 
PRINT_SAME_LINE:
	add r5, r5, r8
	mov r4, r2
	call WRITE_MESSAGE_CHARA
	beq r2, r0, Main
 
STORE_MESSAGE:
	bne r21, r0, STORE_TEXT
	movia r8, SendVal
	movi r9, 0x01
	stw r9, 0(r8)
STORE_TEXT:
	movia r8, SendVal
	addi r8, r8, 4
	add r8, r8, r21
	stb r2, 0(r8)
   addi r21, r21, 1
	mov r2, r0
	
	br Main
	
	
L_SHIFT_MAKE:
	ori r22, r22, 2
	br Main
	
R_SHIFT_MAKE:
	ori r22, r22, 1
	br Main
 
CONVERTTOASCII:
movia r8, LETTER_Convertor
mov r9, r0
movi r11, 26
KEEPCHECKLETTER:
ldb r10, 0(r8)
beq r10, r4, GETASCII
#not equal
addi r9,r9,1
addi r8,r8,1
beq r9, r11, ASCII_NUM
br KEEPCHECKLETTER
GETASCII:
#check if shift is pressed
bgt r22, r0, GET_SHIFT_LETTER
addi r2, r9, 0x61
ret
GET_SHIFT_LETTER:
addi r2, r9, 0x41
ret
 
ASCII_NUM:
movia r8, NUMER_Convertor
mov r9, r0
movi r11, 10
KEEPCHECKNUM:
ldb r10, 0(r8)
beq r10, r4, GETASCII_NUM
#not equal
addi r9, r9, 1
addi r8, r8, 1
beq r9, r11, ASCII_SYMBOL
br KEEPCHECKNUM
GETASCII_NUM:
bgt r22, r0, GET_SHIFT_NUM
addi r2, r9, 0x30
ret
GET_SHIFT_NUM:
movia r8, SHIFT_NUM_TRANSFORM
add r8, r8, r9
ldb r2, 0(r8)
ret
 
ASCII_SYMBOL:
movia r8, SYMBOL_make_codes
mov r9, r0
movi r11, 12
KEEP_CHECK_SYMBOL:
ldb r10, 0(r8)
beq r10, r4, GETASCII_SYMBOL
#not equal
addi r9, r9, 1
addi r8, r8, 1
beq r9, r11, RETURN_NULL
br KEEP_CHECK_SYMBOL
GETASCII_SYMBOL:
bgt r22, r0, GET_SHIFT_SYMBOL
movia r8, SYMBOL_ascii
add r8, r8, r9
ldb r2, 0(r8)
ret
GET_SHIFT_SYMBOL:
movia r8, SYMBOL_SHIFT_ascii
add r8, r8, r9
ldb r2, 0(r8)
ret
 
RETURN_NULL:
mov r2, r0
ret
RESET_TOP_SCREEN:
   movia r8, ADDR_CHAR
	mov r9, r0   #x
	mov r10, r0  #y
	movi r11, 70	#x limit
	movi r12, 45	#y limit
	movi r13, 0x20 #set to space
	br LOOP_TEXT
 
RESET_BOTTOM_SCREEN:
   movia r8, ADDR_CHAR
	mov r9, r0   #x
	movi r10, 46  #y
	movi r11, 80	#x limit
	movi r12, 60	#y limit
	movi r13, 0x20 #set to space
	br LOOP_TEXT
 
RESET_TEXT_SCREEN:
 
  	movia r8, ADDR_CHAR
  	mov r9, r0   #x
	mov r10, r0  #y
	movi r11, 80	#x limit
	movi r12, 60	#y limit
	movi r13, 0x20 #set to space
 
LOOP_TEXT:
bge r9, r11, NEXT_ROW_TEXT
 
DRAW_TEXT:
muli r14, r10, 128
add r14, r14, r9
add r14, r14, r8    	#address of the character
stbio r13, 0(r14)
addi r9, r9, 1
br LOOP_TEXT
 
NEXT_ROW_TEXT:
bge r10, r12, RETURN
mov r9, r0
addi r10, r10, 1
br  DRAW_TEXT
 
RETURN:
ret
 
DRAW_SCREEN:
#r4 is the color for the screen
movia r8, ADDR_VGA
mov r9, r0  #x
mov r10, r0  #y
movi r13, 320
movi r14, 240
 
LOOP:
bge r9, r13, NEXT_ROW
 
DRAW:
muli r11, r9, 2
muli r12, r10, 1024
add r11, r11, r12
add r12, r8, r11
sthio r4, 0(r12)
addi r9,r9,1
br LOOP
 
NEXT_ROW:
bge r10, r14, RETURN
mov r9, r0
addi r10, r10, 1
br DRAW
 
DRAW_RECT:
movia r8, ADDR_VGA
mov r9, r4   #x-left
mov r10, r5   #y-top
addi r13, r6, 1   #x-right
addi r14, r7, 1   #y-bottom
movui r15, 0x8410  	#colour is grey
 
DRAW_RECT_LOOP:
bge r9, r13, DRAW_RECT_NEXT_ROW
 
DRAW_RECT_DRAW:
muli r11, r9, 2
muli r12, r10, 1024
add r11, r11, r12
add r12, r8, r11
sthio r15, 0(r12)
addi r9,r9,1
br DRAW_RECT_LOOP
 
DRAW_RECT_NEXT_ROW:
bge r10, r14, RETURN
mov r9, r4
addi r10, r10, 1
br DRAW_RECT_DRAW
 
WRITE_MESSAGE_CHARA:
	#r4 has the ascii code want to print, r5 is the position of the character (x + 128 * y)
	movia r8, ADDR_CHAR
	add r8, r8, r5    	# r8 stores the address to print the character on the VGA
	stbio r4, 0(r8)
	Ret
 
PRINT_SENT_MSG:
 
 movi r10, 43
 
 ble r23, r10, SENT_MSG_ENOUGH_SPACE
 
 addi sp, sp, -4
 
 stw ra, 0(sp)
 
 call RESET_TEXT_SCREEN
 
 ldw ra, 0(sp)
 
 addi sp, sp, 4
 
 mov r23, r0
 
SENT_MSG_ENOUGH_SPACE:
 movia r8, ADDR_CHAR
	movia r9, SendVal
 addi r9, r9, 4
	mov r5, r23
	muli r5, r5, 128
	add r8, r8, r5
 
 movi r4, 0x4d
 
 stbio r4, 0(r8)
 
 movi r4, 0x45
 
 stbio r4, 1(r8)
 
 movi r4, 0x3a
 
 stbio r4, 2(r8)
	mov r10, r0
 
 addi r10, r10, 4
 
 addi r8, r8, 4
	movi r12, 70
 movi r11, 0x7f
PRINT_SENT_MSG_LOOP:
	ldb r4, 0(r9)
	beq r4, r11, DONE_PRINT_SENT_MSG
	blt r10, r12, PRINT_SENT_MSG_SAME_LINE
	mov r10, r0
 
 addi r10, r10, 1
	addi r8, r8, 59
	addi r23, r23, 1
	
PRINT_SENT_MSG_SAME_LINE:
	stbio r4, 0(r8)
	addi r8, r8, 1
	addi r9, r9, 1
	addi r10, r10, 1
	br PRINT_SENT_MSG_LOOP
	
DONE_PRINT_SENT_MSG:
	ret
 
PRINT_RECIEVED_MSG:
 movi r10, 43
 
 ble r23, r10, RECIEVED_MSG_ENOUGH_SPACE
 
 addi sp, sp, -4
 
 stw ra, 0(sp)
 
 call RESET_TEXT_SCREEN
 
 ldw ra, 0(sp)
 
 addi sp, sp, 4
 
 mov r23, r0
 
RECIEVED_MSG_ENOUGH_SPACE:
	movia r8, ADDR_CHAR
	movia r9, RecievedInput
	addi r9, r9, 4
	mov r5, r23
	muli r5, r5, 128
	add r8, r8, r5
 
 addi r8, r8, 12
 
 movi r11, 0x46
 stbio r11, 0(r8)
 
 movi r11, 0x52
 stbio r11, 1(r8)
 
 movi r11, 0x49
 stbio r11, 2(r8)
 
 movi r11, 0x45
 stbio r11, 3(r8)
 
 movi r11, 0x4e
 stbio r11, 4(r8)
 
 movi r11, 0x44
 stbio r11, 5(r8)
 
 movi r11, 0x3a
 stbio r11, 6(r8)
 addi r8, r8, 8
	mov r10, r0
 
 addi r10, r10, 20
	movi r11, 0x7f
	movi r12, 70
PRINT_RECIEVED_MSG_LOOP:
	ldb r4, 0(r9)
	beq r4, r11, DONE_PRINT_RECIEVED_MSG
	blt r10, r12, PRINT_RECIEVED_MSG_SAME_LINE
	mov r10, r0
 
addi r10, r10, 20
	addi r8, r8, 78
addi r23, r23, 1
PRINT_RECIEVED_MSG_SAME_LINE:
	
	stbio r4, 0(r8)
	addi r8, r8, 1
	addi r9, r9, 1
 
 addi r10, r10, 1
	br PRINT_RECIEVED_MSG_LOOP
	
DONE_PRINT_RECIEVED_MSG:
	ret
 
#function to read audio
ReadAudio:
addi sp, sp, -4 #save return address
stw ra, 0(sp)
movia r8, AUDIO_FIFO
movia r10, SendVal
addi r10, r10, 4
movia r11, EndSendVal #see if match end of space
 
#check if overflowed reserved space
addi r12, r10, 12
bge r12, r11, ExitAudioRead
 
KeepReading:
ldwio r9,4(r8)  	# Read fifospace register
andi  r9,r9,0xff	# Extract # of samples in Input Right Channel FIFO
beq   r9,r0, KeepReading # If no samples in FIFO, go back to start
#check if overflowed reserved space
addi r12, r10, 4
bge r12, r11, ExitAudioRead
 
#otherwise read audio and store it
ldwio r9,8(r8)
stw r9, 0(r10)#left is in first
ldwio r9,12(r8)
addi r10, r10, 4
br KeepReading
 
ExitAudioRead:
ldw ra, 0(sp)
addi sp, sp, 4
ret
 
PlayAudio:
movia r8, AUDIO_FIFO
movia r10, RecievedInput
addi r10, r10, 4
movia r11, EndRecievedInput
 
KeepPlaying:
#check if space in channel
ldwio r9, 4(r8)
srli r9, r9, 16
andi r12, r9, 0xff
beq r12, r0, KeepPlaying
andi r12, r9, 0xff00
beq r12, r0, KeepPlaying
 
ldw r9,0(r10)  	# audio info
stwio r9, 8(r8)
stwio r9, 12(r8)
addi r10, r10, 4
#check if overflowed reserved space
bge r10, r11, FinishPlaying
br KeepPlaying
 
FinishPlaying:
ret
 
WriteOtherDevice:
movui r14, 0x000 #STOP INTERUPT FROM READ
wrctl ctl3, r14
 
movia r9, OUTPUT_GPIO
stwio r0, 0(r9) #enables interrupt on other machine
 
addi sp, sp, -28
stw ra, 0(sp)
stw r9, 4(sp)
stw r10, 8(sp)
stw r11, 12(sp)
stw r12, 16(sp)
stw r13, 20(sp)
stw r14, 24(sp)
 
mov r12, r0 #initialize counter, permanent variable in interrupt
movia r13, SendVal #set up registers to write from
 
#enable timer
#initialize TIMER
movia r9, TIMER_ADR
movia r10, TIMER_PERIOD
stwio r10, 8(r9) #set period
stwio r0, 12(r9)
stwio r0, 0(r9) #clear time out
movui r10, 0b0110 #start and continue
stwio r10, 4(r9)
 
CheckTimerWrite:
movia r10, TIMER_ADR
ldwio r11, 0(r10)
andi r11, r11, 0b01
beq r0, r11, CheckTimerWrite #not done
stwio r0, 0(r10) #clear timeout flag 	??do this before or after?
 
#Write at 0 - negative edge
CheckIfWrite:
bne r12, r0, NotTimeWrite
br WriteInput
 
NotTimeWrite:
call ChangeClock
br CheckTimerWrite
 
WriteInput:
movia r10, OUTPUT_GPIO
ldhu r11, 0(r13)  # Read port input data
#otherwise write the half word
sthio r11, 0(r10)
addi r13, r13, 2 #add halfword to the address
#check if end bit
movia r14, EndSendVal
bge r13, r14, ReturnI
call ChangeClock
br CheckTimerWrite
 
ReturnI:
movia r10, OUTPUT_GPIO
movia r11, 0x80000000
stwio r11, 0(r10) #start idle interrupt on other machine
 
#stop the timer
movia r10, TIMER_ADR
movi r11, 0b1000
stwio r11, 0(r10)
 
ldw ra, 0(sp)
ldw r9, 4(sp)
ldw r10, 8(sp)
ldw r11, 12(sp)
ldw r12, 16(sp)
ldw r13, 20(sp)
ldw r14, 24(sp)
addi sp, sp, 28
movui r18, 0x800 #Reinitiate interrupt for read
wrctl ctl3, r18
ret
 
.section .exceptions, "ax"
IHANDLER:
rdctl et, ctl4      	# Check if an external interrupt has occurred
beq et, r0, InterruptExit
 
#save variables
addi sp, sp, -20
stw ra, 0(sp)
stw r10, 4(sp)
stw r11, 8(sp)
stw r12, 12(sp)
stw r13, 16(sp)
  	
 
rdctl et, ctl4      	# Check if an external interrupt has occurred
andi et, et, 0x00800
beq et, r0, EXIT_IHANDLER     	
 
mov r12, r0 #initialize counter, permanent variable in interrupt
movia r13, RecievedInput #set up read registers
 
#enable timer
#initialize TIMER
movia et, TIMER_ADR
movia r10, TIMER_PERIOD
stwio r10, 8(et)#set period
stwio r0, 12(et)
stwio r0, 0(et)#clear time out
movui r10, 0b0110 #start and continue
stwio r10, 4(et)
 
CheckTimerRead:
movia r10, TIMER_ADR
ldwio r11, 0(r10)
andi r11, r11, 0b01
beq r0, r11, CheckTimerRead #not done
stwio r0, 0(r10) #clear timeout flag 	??do this before or after?
 
#Read at 1 - positive edge
CheckIfRead:
beq r12, r0, NotReadTime
br InitializeInput
 
NotReadTime:
call ChangeClock
br CheckTimerRead
 
InitializeInput:
movia et, INPUT_GPIO
 
ReadInput:
movia r10, EndRecievedInput
bge r13, r10, EXIT_IHANDLER
#otherwise store the halfword
ldhio r11, 0(et)  # Read port input data
sth r11, 0(r13)
addi r13, r13, 2
call ChangeClock
br CheckTimerRead
 
EXIT_IHANDLER:
movi r20, 0b1
movia et, INPUT_GPIO
movia r10, 0xffffffff
stwio r10, 12(et) # De-assert interrupt - write to edge capture reg
 
movia et, TIMER_ADR
movui r10, 0b1000 #stop the timer
stwio r10, 4(et)
 
#restore variables
ldw ra, 0(sp)
ldw r10, 4(sp)
ldw r11, 8(sp)
ldw r12, 12(sp)
ldw r13, 16(sp)
addi sp, sp, 20
subi ea,ea,4	# Replay interrupted instruction for hw interrupts
InterruptExit:
eret
 
ChangeClock:
beq r12, r0, PositiveEdge
movi r12, 0b0 #It is one here, so Negative edge
ret
 
PositiveEdge:
movi r12, 0b1
ret