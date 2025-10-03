INCLUDE Irvine32.inc
.data
boxTB BYTE 120 dup(61),0 ; 61 is '='

startMenu byte "Press space to start!",0

cactusTest BYTE "\|/",0
cactusTest2 BYTE "|||",0

bird BYTE "\/",0
bird2 BYTE "/\",0
birdFlip BYTE 0

gameLoopBit BYTE 0 ; boolean for game loop

cactusXPos BYTE 116 ; starting x position of cactus
birdXPos BYTE 100 ; starting x position of bird

jumpBool BYTE 0 ; boolean for if the dinosaur is jumping

tempDino BYTE "|o|",0 ; the dinosaur, temporary
dinoCount BYTE 0 ; counter for the dinosaur y array
dinoUp BYTE 0 ; boolean for if the dinosaur is going up or down
dinoWait BYTE 1 ; experiment to get the dinosaur to update every other frame

scoreText BYTE "Score: ",0

.code
; ---- Hitboxes ---- !change for application of adv sprites 
; ---- Player ----
DINO_X		EQU 10
DINO_W		EQU 3
DINO_H		EQU 1
DINO_BASE_Y	EQU 27

; ---- Cacti_1 ----
CACTUS_W		EQU 3
CACTUS_H		EQU 2
CACTUS_Y        EQU 27

; ---- BIRD ----
BIRD_W EQU 2
BIRD_H EQU 1
BIRD_Y EQU 24

; ---- End of Hitboxes ----



createGround proc
mov dl, 0
mov dh, 28
call Gotoxy

mov edx,OFFSET boxTB
call WriteString
ret
createGround endp

game proc
mov ecx, 0
gameLoop:
mov dl, 105
mov dh, 4
call Gotoxy
mov edx, OFFSET scoreText
call WriteString
mov eax,ecx
call WriteDec
call createGround
	.IF	gameLoopBit == 0 ; while true 
	dec [cactusXPos]
	dec [birdXPos]
	mov dl, [cactusXPos]
	; if cactus is at the left edge of the screen, reset it
	cmp dl, 1
	je resetCactus

printCactus:
	; this block prints the cactus, top and bottom
	mov dl, [cactusXPos]
	mov dh, 26
	call Gotoxy
	mov edx, OFFSET cactusTest
	call WriteString
	mov dl, [cactusXPos]
	mov dh, 27
	call Gotoxy
	mov edx, OFFSET cactusTest2
	call WriteString

	mov dl, [birdXPos]
	cmp dl, 1
	je resetBird

printBird:
	; this block prints the bird
	mov dl, [birdXPos]
	mov dh, 24
	call Gotoxy
	.IF birdFlip <= 10
	mov edx, OFFSET bird
	inc [birdFlip]
	call WriteString
	.ELSEIF birdFlip <= 20
	mov edx, OFFSET bird2
	inc [birdFlip]
	call WriteString
	.ELSE
	mov BYTE PTR [birdFlip],0
	jmp printBird
	.ENDIF

printDino:
	; this block prints the dinosaur
	mov dl, 10
	mov al, [dinoCount]
	mov dh, 27 ; get the y position from the array based on the frame count
	sub dh, al
	call Gotoxy
	mov edx, OFFSET tempDino
	call WriteString

	; this block checks if the dinosaur is in the air, if it is send to jump function
	mov dl, [jumpBool]
	cmp dl, 0
	je jumpDinosaur
	; this block checks if the dinosaur is on the ground and if the user pressed space, if so send to jump function
	call ReadKey
	cmp al, ' '
	jne readyNextFrame
	mov edi, offset jumpBool
	mov BYTE PTR [edi],0


	
readyNextFrame:
	inc ecx ; just to make it not infinite for now
	cmp ecx,5000
	je exitGameLoop

	; this block just puts the cursor at the top left
	mov dl, 0
	mov dh, 0
	call Gotoxy 
	
	; this controls how long we wait, frames per second essentially
	mov eax, 35 ; 0.035 seconds
	call Delay
	call Clrscr
	jmp gameLoop	
	.ELSE
	ret
	.ENDIF
	jumpDinosaur:
		mov dl, [dinoUp]
		cmp dl, 0
		je dinoGoingUp
	dinoGoingDown:
		mov dl, [dinoCount]
		cmp dl, 0
		jg decDino
		mov edi, offset jumpBool
		mov BYTE PTR [edi],1
		mov edi, offset dinoUp
		mov BYTE PTR [edi],0
		jmp readyNextFrame
	decDino:
		.if dinoWait == 0 ; makes it go every other frame
		mov edi, offset dinoWait
		mov byte ptr [edi],1
		dec [dinoCount]
		jmp readyNextFrame
		.else
		mov edi, offset dinoWait
		mov byte ptr [edi],0
		jmp readyNextFrame
		.endif

	dinoGoingUp:
		mov al, [dinoCount] 
		cmp al, 8
		jl incDino ; dino hasn't reached max height
		mov edi, offset dinoUp ; change direction
		mov BYTE PTR [edi],1
		jmp decDino ; start going down
	incDino:
		.if dinoWait == 0 ; makes it go every other frame
		mov edi, offset dinoWait
		mov byte ptr [edi],1
		inc [dinoCount]
		jmp readyNextFrame
		.else
		mov edi, offset dinoWait
		mov byte ptr [edi],0
		jmp readyNextFrame
		.endif
	resetCactus:
		mov [cactusXPos],116
		jmp printCactus

	resetBird:
		mov [birdXPos],105
		jmp printBird

	exitGameLoop: ; game loop false, aka = 1
		mov edi, offset gameLoopBit
		mov DWORD PTR [edi],1
		jmp gameLoop
game endp

main PROC
; write the start text and dinosaur
mov dl, 10
mov dh, 20
call Gotoxy
mov edx, OFFSET startMenu
call WriteString
mov dl, 10
mov dh, 27 ; get the y position from the array based on the frame count
call Gotoxy
mov edx, OFFSET tempDino
call WriteString

waitForSpace:
call ReadChar
cmp al, ' '
je callGame
jmp waitForSpace
callGame:
call game
exit
main ENDP
END main
