IDEAL
MODEL small
STACK 100h

DATASEG

Ukey equ 'w'  ;77
Dkey equ 's'  ;75
Zkey equ 'z'	  ;2ch
key equ  20h  ;32   ;keys

Ukey2 equ 48h
Dkey2 equ 50h

bb equ 't'
rr equ 'y'

firstY1 dw 116
x_racket1 dw 10
y_racket1 dw 116
color_racket1 db 12

color db 9

clock equ es:6Ch

rackets_size dw 35

firstY2 dw 116
x_racket2 dw 310
y_racket2 dw 116
color_racket2 db 12

boarder_x dw 0

x_ball dw 160
y_ball dw 100
side dw 0
up_down dw 0 

Scroe_text db 'blue score:                 red score:','$'
Bscore db 0
Rscore db 0

;נעלאת תמונה מסך פ	תיחה
OpenScreen db 'op.bmp',0 			;להלחיף לתמונת פתיחה
WinScreen1 db 'rd.bmp',0			;להחליף לניצחון של אדום
WinScreen2 db 'bl.bmp',0			;להחליף ךניצחון של כחול
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10 ,'$'

speed dw 0250ch
note dw 2394h ; 1193180 / 131 -> (hex)


CODESEG
;--------------------------------------
proc reset_position
mov [x_ball], 160
mov [y_ball], 100
mov [Bscore], 0 
mov [Rscore], 0
mov [y_racket1], 116
mov [y_racket2], 116
ret
endp reset_position
;--------------------------------------
;העלאת תמונת פתיחה
;--------------------------------------
image equ [bp+6]
    proc OpenFile
	push bp
	mov bp, sp
    ; Open file
    mov ah, 3Dh
    xor al, al
    mov dx, image
    int 21h
    jc openerror
    mov [filehandle], ax
	pop bp
    ret 6
    openerror :
    mov dx, offset ErrorMsg
    mov ah, 9h
    int 21h
	pop bp
    ret 6
    endp OpenFile
    proc ReadHeader
    ; Read BMP file header, 54 bytes
    mov ah,3fh
    mov bx, [filehandle]
    mov cx,54
    mov dx,offset Header
    int 21h
    ret 
    endp ReadHeader
    proc ReadPalette
; Read BMP file color palette, 256 colors * 4 bytes (400h)
    mov ah,3fh
    mov cx,400h
    mov dx,offset Palette
    int 21h 
    ret
    endp ReadPalette
    proc CopyPal
    ; Copy the colors palette to the video memory
    ; The number of the first color should be sent to port 3C8h
    ; The palette is sent to port 3C9h
    mov si,offset Palette
    mov cx,256
    mov dx,3C8h
    mov al,0
    ; Copy starting color to port 3C8h
    out dx,al
    ; Copy palette itself to port 3C9h
    inc dx
    PalLoop:
    ; Note: Colors in a BMP file are saved as BGR values rather than RGB .
    mov al,[si+2] ; Get red value .
    shr al,2 ; Max. is 255, but video palette maximal
    ; value is 63. Therefore dividing by 4.
    out dx,al ; Send it .
    mov al,[si+1] ; Get green value .
    shr al,2
    out dx,al ; Send it .
    mov al,[si] ; Get blue value .
    shr al,2
    out dx,al ; Send it .
    add si,4 ; Point to next color .
; (There is a null chr. after every color.)
    loop PalLoop
ret
    endp CopyPal
    proc CopyBitmap
; BMP graphics are saved upside-down .
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
    mov ax, 0A000h
    mov es, ax
    mov cx,200
    PrintBMPLoop:
    push cx
; di = cx*320, point to the correct screen line
    mov di,cx
    shl cx,6
    shl di,8
    add di,cx
; Read one line
    mov ah,3fh
    mov cx,320
    mov dx,offset ScrLine
    int 21h
; Copy one line into video memory
    cld ; Clear direction flag, for movsb
    mov cx,320
    mov si,offset ScrLine
    rep movsb ; Copy line to the screen
 ;rep movsb is same as the following code :
 ;mov es:di, ds:si
 ;inc si
 ;inc di
 ;dec cx
  ;loop until cx=0
    pop cx
    loop PrintBMPLoop
ret
    endp CopyBitmap

proc display_image

	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	mov ah,08    
	fgh:
	int 21h		 
		cmp al, key
		jne fgh
	jmp start_game
	
	ret 
endp display_image
;--------------------------------------

proc sound

; open speaker
in al, 61h
or al, 00000011b
out 61h, al
; send control word to change frequency
mov al, 0B6h
out 43h, al
; play frequency 131Hz
mov ax, [note]
out 42h, al ; Sending lower byte
mov al, ah
out 42h, al ; Sending upper byte
; close the speaker
in al, 61h
and al, 11111100b
out 61h, al

ret 
endp sound


;--------------------------------------
;דיסקית 1
proc dot
	mov bh, 0h
	mov cx, [x_racket1]
	mov dx , [y_racket1]
	mov al,[color]
	mov ah,0ch
	int 10h
	ret
endp dot


proc line
	
	mov cx,[rackets_size]
	drawline:
	push cx
	call dot
	pop cx
	dec[y_racket1]
	loop drawline
	mov ax, [rackets_size]
	add [y_racket1], ax
	ret
endp line

proc Ddot
	mov bh, 0h
	mov cx, [x_racket1]
	mov dx , [y_racket1]
	mov al,0
	mov ah,0ch
	int 10h
	ret
endp Ddot

proc Dline
	
	mov cx,[rackets_size]
	Ddrawline:
	push cx
	call Ddot
	pop cx
	dec[y_racket1]
	loop Ddrawline
	mov ax, [rackets_size]
	add [y_racket1], ax
	ret
endp Dline


;דיסקית 2
proc dot2
	mov bh, 0h
	mov cx, [x_racket2]
	mov dx , [y_racket2]
	mov al,12
	mov ah,0ch
	int 10h
	ret
endp dot2

proc line2
	
	mov cx,[rackets_size]
	drawline2:
	push cx
	call dot2
	pop cx
	dec[y_racket2]
	loop drawline2
	mov ax, [rackets_size]
	add [y_racket2], ax
	ret
endp line2

proc Ddot2
	mov bh, 0h
	mov cx, [x_racket2]
	mov dx , [y_racket2]
	mov al,0
	mov ah,0ch
	int 10h
	ret
endp Ddot2

proc Dline2
	
	mov cx,[rackets_size]
	Ddrawline2:
	push cx
	call Ddot2
	pop cx
	dec[y_racket2]
	loop Ddrawline2
	mov ax, [rackets_size]
	add [y_racket2], ax
	ret
endp Dline2

;--------------------------------------
;כדור
proc ball
	mov bh, 0h
	mov cx, [x_ball]
	mov dx , [y_ball]
	mov al,15
	mov ah,0ch
	int 10h
	inc cx
	mov ah,0ch
	int 10h
	inc dx
	mov ah,0ch
	int 10h
	dec cx
	mov ah,0ch
	int 10h
	ret
endp ball

proc dball
	mov bh, 0h
	mov cx, [x_ball]
	mov dx , [y_ball]
	mov al,0
	mov ah,0ch
	int 10h
	inc cx
	mov ah,0ch
	int 10h
	inc dx
	mov ah,0ch
	int 10h
	dec cx
	mov ah,0ch
	int 10h
	ret
endp dball


proc mov_ball
	
	cmp [y_ball],12
	jbe t
	jmp j
t:
call sound
jmp turn_down
j:
	cmp [y_ball],198
	jae tt
	jmp jj
tt:
call sound
jmp turn_up
jj:
	jmp o 
	
turn_down:

	mov [up_down],0
	jmp o
	
turn_up:

	mov [up_down],1
	
o:	
	call  check_color
	cmp al, 12
	je ttt
	jmp jjj
ttt:
call sound
jmp left
jjj:
	call check_color
	
	cmp al, 9 
	je tttt
	jmp jjjj
tttt:
call sound
jmp right
jjjj:

	cmp [side],0
	je left

right:
	
	mov [side],1
	call dball
	add [x_ball], 2
	cmp [up_down],0
	je downn
	dec [y_ball]
	jmp fff

left:
	
	mov [side],0
	call dball
	sub [x_ball], 2
	cmp [up_down],0
	je downn
	dec [y_ball]
	jmp fff
	
	downn:
	inc [y_ball]


fff:
call ball

	ret
endp mov_ball

;--------------------------------------
;גבול עליון  ירוק
proc Bdot
	mov bh, 0h
	mov cx, [boarder_x]
	mov dx , 9
	mov al,10
	mov ah,0ch
	int 10h
	ret
endp Bdot

proc border
	
	mov cx,320
	Bdrawline:
	push cx
	call Bdot
	pop cx
	inc [boarder_x]
	loop Bdrawline
	ret
endp border

;------------------------------
;ניקוד
ink equ [bp+4]
proc printScoreB
	push bp
	mov bp, sp
	mov  dl, 38   ;Column
	mov  dh, 0   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, ink
	add al,30h
	mov  bl, 12  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	pop bp
	ret
endp printScoreB


text equ [bp+4]
proc printText
	push bp
	mov bp, sp
	mov dx, text
	mov ah, 9h
	int 21h
	mov ah,08 	
	pop bp
	ret 6
endp printText


ink equ [bp+4]
proc printScoreR
	push bp
	mov bp, sp
	mov  dl, 11   ;Column
	mov  dh, 0  ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, ink
	add al,30h
	mov  bl, 9  ;Color is blue
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	pop bp
	ret

endp printScoreR





;-------------------------------------
proc randd_x


mov ax, 40h
mov es, ax
mov ax, [clock]
and al, 00000001b 

cmp al, 0h
je set_zero

mov [side], 1
jmp ffff

set_zero:
mov [side], 0

ffff:

endp randd_x

proc randd_y
mov ax, 40h
mov es, ax
mov ax, [clock]
and al, 00000001b 

cmp al, 0h
je set_zeroo

mov [up_down], 1
jmp fffff

set_zeroo:
mov [up_down], 0

fffff:
RET 

endp randd_y



;דיליי לכדור
proc delay
	   mov     cx, 003H
    delRep: push    cx
            mov     cx, [speed]
    delDec: dec     cx
            jnz     delDec
            pop     cx
            dec     cx
            jnz     delRep
            ret
endp delay


proc check_color
	cmp [side], 0 
	je lfr
	mov bh,0h
	mov cx,[x_ball]
	add cx, 2
	mov dx,[y_ball]
	mov ah,0Dh
	int 10h
	jmp d
	
	lfr:
	mov bh,0h
	mov cx,[x_ball]
	sub cx, 2
	mov dx,[y_ball]
	mov ah,0Dh
	int 10h
	
	d:
	ret
endp check_color

;--------------------------------------
start:
	mov ax, @data
	mov ds, ax
	
	
	

; ----Graphic mode--------
	mov ax, 13h
	int 10h
 ;-----------------------
 
push offset OpenScreen
call display_image ;מראה תמונה ומחכה לרווח בשביל להתקדם

; -------------------------- opening screen^
start_game:
	mov ax, 0dh
	int 10h
 
call reset_position

 ; הקוד כאן
;mov ah,0h ; מחכה לקלט ממקלדנ בשביל להתחיל משחק
;int 16h	
call randd_x
call line ; ציור דסקית 1
call line2;ציור דסקית2
call border;הגבול העליון
call ball
push offset Scroe_text
call printText
call randd_y

mov ah,0h ; מחכה לקלט ממקלדנ בשביל להתחיל משחק
int 16h	




gamee1:

call delay

push [word ptr Bscore]
 call printScoreB

push [word ptr Rscore]
 call printScoreR
 
cmp [Rscore], 9
jne co
jmp red_win

co:

cmp [Bscore], 9
jne con
jmp blue_win
con:

cmp [x_ball],315   ; בדיקת פגיעה מימין
jb connn
jmp point_blue

connn:

cmp [x_ball],5  ;בדיקת בדיקה משמשאל
ja conn
jmp point_red

conn:



call mov_ball




mov ah,1h
int 16h		;קולט קלט ממקלדת אבל לא מחכה
jnz here

jmp gamee1
here:
mov ah,0h				;ף מחכה לקלט ממקלדת
int 16h		

;~~~~checking scan codes- key pressed~~~
;הלחיצות על המלקדת ותנועת הדסקיות בהתאם
	cmp al, Ukey
	je Up
	
	cmp al, Dkey
	je Down
	
	cmp ah, 48h
	je Up2
	
	cmp ah, 50h
	je Down2	
	
	cmp al,Zkey
	je NoOneShellBeHere
	
	cmp al,bb
	jne x 
	jmp point_blue

x:

	cmp al,rr
	jne xx
	jmp point_red
	

xx:


	cmp al, 'p'
	jne xxx
	jmp sound_test
	
xxx:
jmp gamee1


;-------------
gamee:
jmp gamee1
;-------------	

;תנועת מקלדת 1s
Up:
mov ax, [rackets_size]
add ax, 12
cmp [y_racket1], ax ; 12+35
jbe gamee ;
call Dline
sub [y_racket1], 4
call line
jmp gamee

Down:
cmp [y_racket1],200
jae gamee
call Dline
add [y_racket1], 4
call line
jmp gamee

;תנועת מקלדת 2
Up2:
mov ax, [rackets_size]
add ax, 12
cmp [y_racket2],ax
jbe gamee
call Dline2
sub [y_racket2], 4
call line2
jmp gamee


Down2:
cmp [y_racket2],200
jae gamee
call Dline2
add [y_racket2], 4
call line2
jmp gamee

NoOneShellBeHere:	
jmp exit


jmp gamee


point_blue:
inc [Rscore]
call dball
mov [x_ball],160
mov [y_ball],100
mov [side],0
call randd_y
call ball
push [word ptr Rscore]
 call printScoreR
mov ah,0h ; מחכה לקלט ממקלדנ בשביל להתחיל משחק
int 16h	
jmp gamee

point_red:
inc [Bscore]
call dball
mov [x_ball],160
mov [y_ball],100
mov [side],1
call randd_y
call ball
push [word ptr Bscore]
 call printScoreB
mov ah,0h ; מחכה לקלט ממקלדנ בשביל להתחיל משחק
int 16h	
jmp gamee

sound_test:
call sound 

jmp gamee
blue_win:
	

	mov ax, 0dh
	int 10h
	
		mov ax, 13h
	int 10h
	
	push offset WinScreen1
	call display_image;מציג כחול ניצח
	
red_win:

	mov ax, 0dh
	int 10h
	
		mov ax, 13h
	int 10h
	
	push offset WinScreen2
	call display_image; מציג אדום ניצח	
exit:


	mov ax, 4c00h
	int 21h
END start