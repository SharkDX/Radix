;
; A simple boot sector program that demonstrates addressing.
;
[BITS 16]
[ORG 0x7c00]

jmp start
; ------------------------------------------
; Data initializing
; ------------------------------------------
	boot_drive			db 0
	boot_msg			db 'Booting RadixOS (c) 2016',13,10,0
	reboot_msg			db 'Press any key to reboot...',13,10,0
	bit16_msg			db 'Running in 16 bit Real-Mode',13,10,0
	load_disk_msg 		db 'Loading disk...',13,10,0
	load_disk_error_msg	db 'Error loading sectors from drive',13,10,0
	hex_num_prefix		db '0x',0
	newline_str			db 13,10,0

; ------------------------------------------
; Functions
; ------------------------------------------
	; Loads DH sectors to ES:BX from drive DL
	load_disk:
		; al - Sectors to be read
		; ch - Cylinder
		; cl - Sector
		; dh - Head
		; dl - Drive
		; es:bx - Buffer address pointer

		push dx
		mov ah, 0x02
		mov al, dh
		mov ch, 0x00
		mov cl, 0x00
		mov dh, 0x00

		int 0x13

		jc load_disk_error

		pop dx
		cmp dh, al
		jne load_disk_error
		ret

	; ------------------------------------------
	load_disk_error:
		mov si, load_disk_error_msg
		call print

		mov dx, bx
		call print_hex
	; ------------------------------------------
	; Print the hex value of DX.
	; If in the end DX != 0, someting is wrong.
	print_hex:
		; Push used registers & setup registers for printing
		push bx
		push ax
		push cx
		; cx = characters count to be printed.
		mov cx, 4
		mov ah, 0x0e
		xor bx, bx

		mov si, hex_num_prefix
		call print

		inner_print_hex:
			; If cx == 0 -> we are done printing
			or cx, cx
			jz end

			; Rotate dx a byte left (msb is printed first)
			; Then move the last byte (to be printed) to ax, and decrease cx (characters left)
			rol dx, 4
			mov al, dl
			and al, 0x0f
			dec cx

			; If the character to print is NOT a letter, skip the added ascii diff for letters
			cmp al, 0x0a
			jb add_if_number
			add al, 39
			add_if_number:
				add al, 48
			int 0x10
			jmp inner_print_hex
		end:
			mov si, newline_str
			call print
			pop cx
			pop ax
			pop bx
			ret
	; ------------------------------------------
	print:
		lodsb
		or al, al
		jz function_end
		mov ah, 0x0e
		mov bx,0x01
		int 0x10
		jmp print
	; ------------------------------------------
	wait_for_key:
	    mov ah, 0
	    int 016h
	    ret
	; ------------------------------------------
	reboot:
	    mov si, reboot_msg
	    call print
	    call wait_for_key

	    db 0EAh         ; machine language to jump to FFFF:0000 (reboot)
	    dw 0000h
	    dw 0FFFFh
	    ; no ret required; we're rebooting! (Hey, I just saved a byte :)
	; ------------------------------------------
	function_end:
		ret
; ------------------------------------------
; Boot Loader Code
; ------------------------------------------
	start:
		; Save the booted drive
		mov [boot_drive], dl

		; ZERO our address registers (remove any unexpected values passed from the BIOS)
		xor ax, ax
		mov ds, ax
		mov es, ax

		; Init the stack
		mov bp , 0x8000 ; Set the base of the stack a little above where the BIOS
		mov sp , bp 
		
		mov si, boot_msg
		call print

		mov si, bit16_msg
		call print

		mov si, load_disk_msg
		call print

		mov bx, 0x9000
		mov dh, 2
		mov dl, [boot_drive]
		call load_disk

		mov dx, [0x9000]
		call print_hex

		; Jump forever.
		call reboot



	; Padding and magic BIOS number.
	times 510 -( $ - $$ ) db 0
	dw 0xaa55

; ------------------------------------------
; Sector 1 Code
; ------------------------------------------
sector_2:
	times 256 dw 0xdead
	times 256 dw 0xbeef



