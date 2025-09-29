INCLUDE Irvine32.inc
.data
boxTB BYTE 120 dup(61),0
cactusTest BYTE "\|/",0
cactusTest2 BYTE "|||",0
gameLoopBit BYTE 0
cactusXPos BYTE 116
.code
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
call createGround
	.IF	gameLoopBit == 0 ; while true 
	dec [cactusXPos]
	mov dl, [cactusXPos]
	cmp dl, 1
	je resetCactus

printCactus:
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

	inc ecx ; just to make it not infinite for now
	cmp ecx,500
	je exitGameLoop
	mov dl, 0
	mov dh, 0
	call Gotoxy ; this just makes it look better
	mov eax, 100 ; 0.1 seconds
	call Delay
	call Clrscr
	jmp gameLoop

	.ELSE
	ret
	.ENDIF
	resetCactus:
		mov [cactusXPos],116
		jmp printCactus

	exitGameLoop: ; game loop false, aka = 1
		mov edi, offset gameLoopBit
		mov DWORD PTR [edi],1
		jmp gameLoop
game endp

main PROC
 call game
 exit
 main ENDP
END main
