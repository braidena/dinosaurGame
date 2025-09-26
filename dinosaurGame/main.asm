INCLUDE Irvine32.inc
.data
boxTB BYTE "===========================================================",13,10,0
boxLR BYTE "|                                                         |",13,10,0
cactusTest BYTE "\|/",13,10,0
cactusTest2 BYTE "|||",13,10,0
gameLoop BYTE 0
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

loopTest proc
mov ecx, 0
textLoop:
	.IF	gameLoop == 0
	mov edx, OFFSET cactusTest
	call WriteString
	inc ecx
	cmp ecx,2
	je changeGameLoop
	jmp textLoop
	.ELSE
	ret
	.ENDIF
	changeGameLoop:
		mov edi, offset gameLoop
		mov DWORD PTR [edi],1
		jmp textLoop
loopTest endp

main PROC
 call createBox
 call loopTest
 exit
 main ENDP
END main
