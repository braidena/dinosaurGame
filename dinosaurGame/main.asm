INCLUDE Irvine32.inc
MAX_OBSTACLES = 10
.data
boxTB BYTE 120 dup(61),0 ; 61 is '='

startMenu byte "Press space to start!",0 ; start menu text

; ---- Obstacle sprites ----
cactusTest BYTE "\|/",0
cactusTest2 BYTE "|||",0

bird BYTE "\/",0
bird2 BYTE "/\",0
birdFlip BYTE 0

gameLoopBit BYTE 0 ; boolean for game loop

cactusXPos BYTE 116 ; starting x position of cactus
birdXPos BYTE 116 ; starting x position of bird


currAmount dword ? ; current amount of obstacles on screen
spawnDelay DWORD ? ; frames until next spawn
obstacleX DWORD MAX_OBSTACLES DUP(116)    ; x positions
obstacleY DWORD MAX_OBSTACLES DUP(?)    ; y positions
obstacleType DWORD MAX_OBSTACLES DUP(?) ; 0=cactus, 1=bird
obstacleActive DWORD MAX_OBSTACLES DUP(0) ; 0=inactive, 1=active

jumpBool BYTE 0 ; boolean for if the dinosaur is jumping

; --- 2x4 Dino Sprite ---
dinoRow1 BYTE " ==D",0 
dinoRow2 BYTE "/l^ ",0 

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
DINO_W		EQU 4 ; 4 long
DINO_H		EQU 2 ; 2 rows tall
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

spawnNewObstacle proc
; spawns a new obstacle at random intervals
mov esi, -1
mov ecx, MAX_OBSTACLES
mov edi, OFFSET obstacleActive

findEmptySlot:
	cmp DWORD PTR [edi], 0
	je slotFound
	add edi, 4
	loop findEmptySlot
	jmp noSlotFound

slotFound:
	mov eax, MAX_OBSTACLES
	sub eax, ecx
	mov esi, eax
	jmp createObstacle

noSlotFound:
	ret

createObstacle:
    ; activate this slot
    mov eax, 1
    mov obstacleActive[esi*4], eax

    ; randomize type (0=cactus, 1=bird)
    mov eax, 2
    call RandomRange
    mov obstacleType[esi*4], eax


    ; set y position (birds higher)
    cmp obstacleType[esi*4], 0
    je cactusY

	mov eax, 3
	call RandomRange
    add eax, 24 ; bird y position range 24-26
    mov obstacleY[esi*4], eax   ; bird height

    jmp done
cactusY:
    mov obstacleY[esi*4], 26   ; cactus height
done:
	mov obstacleX[esi*4], 116 ; spawn at right edge
	ret
spawnNewObstacle endp


updateObstacles proc
; updates obstacle positions
mov ecx, MAX_OBSTACLES
mov esi, 0

updateLoop:
    cmp obstacleActive[esi*4], 0
    je skipUpdate

    ; move obstacle left by 1 pixel per frame
    mov eax, obstacleX[esi*4]
    dec eax
    mov obstacleX[esi*4], eax

    ; check if offscreen
    cmp eax, 1
    jg skipUpdate
    mov obstacleActive[esi*4], 0  ; deactivate if off left side
	.IF currAmount != 0
	dec currAmount
	.ENDIF

skipUpdate:
    inc esi
    loop updateLoop
	ret
updateObstacles endp


drawObstacles proc
; draws all active obstacles
push edi
mov edi, MAX_OBSTACLES
mov esi, 0

drawLoop:
    cmp obstacleActive[esi*4], 0
    je skipDraw

    mov eax, obstacleType[esi*4]
    cmp eax, 0
    je printCactus

    ; draw bird
    mov eax, obstacleX[esi*4]
    mov ebx, obstacleY[esi*4]
    jmp printBird
    jmp skipDraw

printCactus:
	; this block prints the cactus, top and bottom
	mov eax, lightGreen + (white * 16)
    call SetTextColor
	mov eax, obstacleX[esi*4]
	mov dl, al
	mov dh, 26
	call Gotoxy
	mov edx, OFFSET cactusTest
	call WriteString
	mov eax, obstacleX[esi*4]
	mov dl, al
	mov dh, 27
	call Gotoxy
	mov edx, OFFSET cactusTest2
	call WriteString
	mov eax, black + (white * 16)
    call SetTextColor
	jmp skipDraw


printBird:
	; this block prints the bird
	mov eax, red + (white * 16)
    call SetTextColor
	mov eax, obstacleX[esi*4]
	mov dl, al
	mov eax, obstacleY[esi*4]
	mov dh, al
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
	mov eax, black + (white * 16)
    call SetTextColor

skipDraw:
    inc esi
    dec edi
	cmp edi, 0
	jne drawLoop
	pop edi
	ret

drawObstacles endp

checkCollisions proc
; checks for collisions between dino and obstacles
    push ebx
    push edi
    push esi

     mov esi, DINO_X                      ; ESI = dino left X
    mov eax, DINO_X + DINO_W - 1         ; EAX = dino right X
    movzx edx, dinoCount                 ; jump offset
    mov ebx, DINO_BASE_Y
    sub ebx, edx                         ; EBX = dino BOTTOM Y
    mov ecx, ebx
    sub ecx, DINO_H - 1                  ; ECX = dino TOP Y

    xor ebx, ebx                       ; EBX = obstacle index = 0

obstacleLoop:
    mov edx, DWORD PTR obstacleActive[ebx*4]
    cmp edx, 0
    je skipObstacle

    mov edx, DWORD PTR obstacleType[ebx*4]
    cmp edx, 0
    je checkCactus

    ; --- Bird check ---
    mov edx, DWORD PTR obstacleX[ebx*4] ; EDX = bird left
    mov edi, edx
    add edi, BIRD_W - 1                ; EDI = bird right

    cmp eax, edx                       ; if dino.right < bird.left => no overlap
    jb skipObstacle
    cmp edi, esi                       ; if bird.right < dino.left => no overlap
    jb skipObstacle

    mov edx, DWORD PTR obstacleY[ebx*4] ; EDX = bird Y
    mov edi, edx
    add edi, BIRD_H - 1                  ; EDI = birdBottom

    ; if dinoBottom < birdTop => no overlap
    cmp ebx, edx                         ; (dinoBottom vs birdTop)
    jb skipObstacle

    ; if birdBottom < dinoTop => no overlap
    cmp edi, ecx                         ; (birdBottom vs dinoTop)
    jb skipObstacle


    mov gameLoopBit, 1
    jmp collisionExit

checkCactus:
    mov edx, DWORD PTR obstacleX[ebx*4]  ; EDX = cactusLeft
    mov edi, edx
    add edi, CACTUS_W - 1                ; EDI = cactusRight

    cmp eax, edx                         ; if dinoRight < cactusLeft
    jb skipObstacle
    cmp edi, esi                         ; if cactusRight < dinoLeft
    jb skipObstacle

    mov edx, CACTUS_Y - (CACTUS_H - 1)   ; EDX = cactusTop
    mov edi, CACTUS_Y                    ; EDI = cactusBottom

    ; if dinoBottom < cactusTop => no overlap
    cmp ebx, edx                         ; (dinoBottom vs cactusTop)
    jb skipObstacle

    ; if cactusBottom < dinoTop => no overlap
    cmp edi, ecx                         ; (cactusBottom vs dinoTop)
    jb skipObstacle

    ; overlap detected
    mov gameLoopBit, 1
    jmp collisionExit

skipObstacle:
    inc ebx
    cmp ebx, MAX_OBSTACLES
    jl obstacleLoop

collisionExit:
    pop esi
    pop edi
    pop ebx
    ret
checkCollisions endp

createGround proc
mov eax, brown + (white * 16)
call SetTextColor
mov dl, 0
mov dh, 28
call Gotoxy

mov edx,OFFSET boxTB
call WriteString
mov eax, black + (white * 16)
call SetTextColor
ret
createGround endp

game proc
call Randomize
; initialize first spawn delay
mov eax, 40            ; max frames to wait before first spawn
call RandomRange       ; EAX = 0–79
add eax, 40            ; ensure at least 40 frame delay
mov spawnDelay, eax
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
	call drawObstacles	
	call updateObstacles
	call checkCollisions
	.IF gameLoopBit != 0
	jmp exitGameLoop
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
	.IF score > 1500
		mov eax, 20 ; 0.025 seconds
	.ELSEIF score > 1000
		mov eax, 27 ; 0.03 seconds
	.ELSE
		mov eax, 33 ; 0.0375 seconds
	.ENDIF
	call Delay
	call Clrscr
	dec spawnDelay
	jnz skipSpawn
    ; reset spawnDelay to new random interval
    mov eax, 30
    call RandomRange
    add eax, 30
    mov spawnDelay, eax
	.IF currAmount < 10
    call spawnNewObstacle
	inc currAmount
	.ENDIF
skipSpawn:
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
		cmp al, 6 ; max height
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
mov eax, black + (white * 16) ; Set text Black, Background White
call SetTextColor
call Clrscr
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
