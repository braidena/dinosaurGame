INCLUDE Irvine32.inc
.data
boxTB BYTE "===========================================================",13,10,0
boxLR BYTE "|                                                         |",13,10,0
cactusTest BYTE "\|/",13,10,0
cactusTest2 BYTE "|||",13,10,0
gameLoopBit BYTE 0
cactusXPos BYTE 5
cactusYPos BYTE 5
space BYTE "              ",0
.code
createBox proc
mov edi,OFFSET boxTB
mov esi,OFFSET boxLR

mov dl, 39
mov dh, 11
call Gotoxy

mov edx,edi
call WriteString

mov ecx,8
mov al,12


printSides:
	mov dl, 39
	mov dh, al
	inc al
	call Gotoxy
	mov edx,esi
	call WriteString
	loop printSides


mov dl, 39
mov dh, al
call Gotoxy
mov edx,edi
call WriteString

mov dl, 44
mov dh, 18
call Gotoxy
mov edx, OFFSET cactusTest
call WriteString
mov dl, 44
mov dh, 19
call Gotoxy
mov edx, OFFSET cactusTest2
call WriteString
ret
createBox endp

game proc
mov ecx, 0
gameLoop:
	.IF	gameLoopBit == 0 ; while true
	mov dl, [cactusXPos]
	mov dh, [cactusYPos]
	call Gotoxy 
	inc [cactusXPos]
	mov dl, [cactusXPos]
	cmp dl, 11
	je resetCactus

printCactus:
	mov dl, [cactusXPos-1]
	mov dh, [cactusYPos]
	call Gotoxy
	mov edx,OFFSET space
	call WriteString
	mov dl, [cactusXPos]
	mov dh, [cactusYPos]
	call Gotoxy
	mov edx, OFFSET cactusTest
	call WriteString

	


	inc ecx ; just to make it not infinite for now
	cmp ecx,50
	je exitGameLoop
	mov eax, 100 ; 0.1 seconds
	call Delay
	jmp gameLoop

	.ELSE
	ret
	.ENDIF
	resetCactus:
		mov [cactusXPos],5
		jmp printCactus

	exitGameLoop: ; game loop false, aka = 1
		mov edi, offset gameLoopBit
		mov DWORD PTR [edi],1
		jmp gameLoop
game endp

main PROC
 call createBox
 call game
 exit
 main ENDP
END main
