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
score DWORD 0 ; holds player's current score
scoreText BYTE "Score: ",0

gameOverMsg BYTE "GAME OVER!", 0
pressAnyMsg BYTE "Press any key to exit...",0

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
mov dl, 112
mov dh, 4; changing the score counter so that it does not rely on ECX
call Gotoxy 
mov eax, [score]
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
	; ---- Collisions ----
	movzx eax, dinoCount ; The player character's vertical offset
	mov ecx, DINO_BASE_Y ; Load the base Y pos of player character (dino)
	sub ecx, eax         ; subtracting the jump offset to find current y pos

	; --- AABB vs CACTUS ---
	mov esi, DINO_X                ; ESI => left X coord of player
	mov edi, DINO_X + DINO_W - 1   ; EDI => right X coord of player
	movzx ebx, cactusXPos          ; EBX = current X pos of cactus
	mov edx, ebx                   ; copy cactus left X into EDX
	add edx, CACTUS_W - 1          ; EDX => right X coord of the cactus

	cmp edi, ebx    ; If dino.right < cactus.left then => no collision
	jb noCactusX    
	cmp edx, esi    ; If cactus.right < dino.left then => no collision
	jb noCactusX
	 
	; --- Vertical Overlap checking ---
	mov ebx, CACTUS_Y - (CACTUS_H - 1)    ; EBX => cactus top y coord
	mov edx, CACTUS_Y                     ; EDX => cactus bottom y coord
	cmp ecx, ebx                          ; If dino.bottom < catcus.top then => no collision
	jb noCactusX
	cmp edx, ecx                          ; If cactus.bottom < dino.top then => no collision
	jb noCactusX

	; if both X and Y overlap => collision
	mov gameLoopBit, 1 ; sets flag to break game loop
	jmp exitGameLoop   ; Jump to Game Over

noCactusX:
    ; --- Bird ---
	mov esi, DINO_X                 ; ESI => dino left X
	mov edi, DINO_X + DINO_W - 1    ; EDI => dino right X
	movzx ebx, birdXPos             ; EBX => bird left X
	mov edx, ebx                    
	add edx, BIRD_W - 1             ; EDX => bird right X

	cmp edi, ebx                    ; If dino.right < bird.left then => no overlap
	jb noBirdX
	cmp edx, esi                    ; If bird.right < dino.left then => no overlap
	jb noBirdX

	mov ebx, BIRD_Y                 ; EBX => bird Y coord 1x1(for now)
	mov edx, BIRD_Y                 
	cmp ecx, ebx                    ; If dino.bottom < bird.top then => no overlap
	jb noBirdX
	cmp edx, ecx                    ; If bird.bottom < dino.top then => no overlap
	jb noBirdX

	; overlap = game over
	mov gameLoopBit, 1
	jmp exitGameLoop

noBirdX:
	cmp jumpBool,  1 ; Is the dino already jumping
	je jumpDinosaur  ; If then continue jump arc
	; --- keyboard check ---
	call ReadKey    ; Try to read from buff
	jz noKeyPressed ; ZF = 1 then no key pressed, therefore skip
	cmp al, ' '     ; Compare key to ' '
	jne noKeyPressed; if not ' ' skip

	; space pressed
	mov jumpBool, 1    ; Dino jumping state
	mov dinoUp, 0      ; jump direction up
	jmp jumpDinosaur   ; begin logic
	noKeyPressed:
	; if no key or wrong key move on

readyNextFrame:
	inc [score] ; just to make it not infinite for now
	
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
		mov al, [dinoCount]
		cmp al, 0
		jg decDino
		mov jumpBool, 0
		mov dinoUp, 0
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
		mov BYTE PTR [edi],1
		
		call Clrscr
		mov dl, 50 
		mov dh, 12
		call Gotoxy
		mov edx, OFFSET gameOverMsg
		call WriteString

		mov dl, 50 
		mov dh, 13
		call Gotoxy
		mov edx, OFFSET scoreText
		call WriteString
		; number for score
		mov dl, 58 ; 50 + "Score: "
		mov dh, 13
		call Gotoxy
		mov eax, [score]
		call WriteDec
		; press any key
		mov dl, 48 
		mov dh, 15
		call Gotoxy
		mov edx, OFFSET pressAnyMsg
		call WriteString

		call ReadChar
		call Clrscr
		ret
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
