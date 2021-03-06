.equ BALL, 0x1000 ; ball state (its position and velocity)
.equ PADDLES, 0x1010 ; paddles position
.equ SCORES, 0x1018 ; game scores
.equ LEDS, 0x2000 ; LED addresses
.equ BUTTONS, 0x2030 ; Button addresses


; BEGIN:main
main:
call init
stw  zero, SCORES(zero) ;init scores
stw  zero, SCORES+4(zero)
call game
ret


init: 
	addi t0, zero, 7 ; init_position_x
	addi t1, zero, 4 ; init_position_y
	addi t2, zero, 1 ; init_velocity_x
	addi t3, zero, 1 ; init_velocity_y

	stw t0, BALL(zero)
	stw t1, BALL+4(zero)
	stw t2, BALL+8(zero)
	stw t3, BALL+12(zero)

	addi sp, zero, LEDS
	addi t2, zero, 5

	stw t2, PADDLES(zero)
	stw t2, PADDLES+4(zero)
ret


game:
call hit_test
call move_paddles
call move_ball
call clear_leds
ldw a0, BALL(zero)
ldw a1, BALL+4(zero)
call set_pixel 
call draw_paddles
cmpeqi t4, v0, 1
cmpeqi t5, v0, 2
bne t4, zero, player1won
bne t5, zero, player2won
call wait
ret

wait:
addi t0, zero, 1
slli t0, t0, 7

call wait_loop

wait_loop:
beq  t0, zero, wait_ret
addi t0, t0, -1
br   wait_loop

wait_ret:
br game
ret


player1won:
addi a3, zero, 4 ;
add v0, zero, zero
addi t0, zero, 4
ldw t1, SCORES(zero) 
add t0, t0, t1
stw t0, SCORES(zero)
addi t3, zero, 40

beq t0, t3, end_game
call display_score
call init
call wait
ret

player2won:
addi a3, zero, 8 ;
add v0, zero, zero
addi t0, zero, 4
ldw t1, SCORES+4(zero)
add t0, t0, t1
stw t0, SCORES+4(zero)

addi t3, zero, 40
beq t0, t3, end_game
call display_score
call init
call wait
ret

end_game:
call clear_leds

add t0, a3, zero ; 

ldw t0, font_data(t0)
stw t0, LEDS+4(zero)

call loop
ret

loop: 
call loop


; END:main




; BEGIN:clear_leds
clear_leds:
stw zero, LEDS(zero)
stw zero, LEDS+4(zero)
stw zero, LEDS+8(zero)

ret
; END:clear_leds

 

; BEGIN:set_pixel
set_pixel: ; parametres : a0 = x et a1 = y

addi t4, zero, 8
addi t5, zero, 4
add t2, zero, zero
addi t6, zero, 1

bge a0, t4, load_sup8
bge a0, t5, load_sup4_inf8

ldw t0, LEDS(zero)  ; load_inf4
add t1, a0, zero

br set_leds

ret

; stoque l'adresse de la led concernee dans a2(t0) et le nouveau x dans a3(t1) et le bit (a 32 valeur) dans t2
set_leds: ; stoque l'adresse de la led concernee dans t0 , le nouveau x dans 
bne t1, zero, decr_x
add t2, a1, t2
bge a0, t4, store_sup8
bge a0, t5, store_sup4_inf8

sll t2, t6, t2
ldw t7, LEDS(zero)
or t2, t2, t7
stw t2, LEDS(zero)

ret

decr_x:
addi t2, t2, 8
addi t1, t1, -1
br set_leds
ret

load_sup4_inf8:
ldw t0, LEDS+4(zero)
addi t1, a0, -4

br set_leds
ret

load_sup8:
ldw t0, LEDS+8(zero)
addi t1, a0, -8

br set_leds
ret

store_sup4_inf8:
sll t2, t6, t2
ldw t7, LEDS+4(zero)
or t2, t2, t7
stw t2, LEDS+4(zero)
ret

store_sup8:
sll t2, t6, t2
ldw t7, LEDS+8(zero)
or t2, t2, t7
stw t2, LEDS+8(zero)
ret


; END:set_pixel



;BEGIN:hit_test
hit_test:
addi v0, zero, 0
ldw t1, BALL+4 (zero) #ypos in t1
ldw t4, BALL(zero) #xpos in t4

addi t2, zero, 7
addi t5, zero, 11

beq t1, t2, inverty
beq t1, zero, inverty
	
afterY:
beq t4, t5, invertx
beq t4, zero, invertx

afterX:
ldw t0, BALL(zero) #xpos in t0
cmpeqi t1, t0, 1 #true if at full left
cmpeqi t2, t0, 10 #true if at full right

ldw t3, BALL+8(zero)
cmpeqi t4, t3, -1 #true if goes to the left
cmpeqi t5, t3, 1 #true if goes to the right

and t4, t4, t1 #true if goes to the left and is at the left
and t5, t5, t2 #true if goes to the right and is at the right
	
bne t4, zero, testHitAtLeft
bne t5, zero, testHitAtRight
br exit
	
prexit:
#re-do the check wall
ldw t1, BALL+4 (zero) #ypos in t1
ldw t4, BALL(zero) #xpos in t4

addi t2, zero, 7
addi t5, zero, 11

beq t1, t2, inverty2
beq t1, zero, inverty2
	
afterY2:
beq t4, t5, invertx
beq t4, zero, invertx

exit:

ret

inverty2: 
ldw t3, BALL+12(zero)
sub t3, zero, t3
stw t3, BALL+12(zero)
br afterY2
	
inverty: 
ldw t3, BALL+12(zero)
sub t3, zero, t3
stw t3, BALL+12(zero)
br afterY

invertx: 
ldw t6, BALL+8(zero)
sub t6, zero, t6
stw t6, BALL+8(zero)
br afterX

invertx2: 
ldw t6, BALL+8(zero)
sub t6, zero, t6
stw t6, BALL+8(zero)
br exit

testHitAtLeft:
ldw t0, PADDLES(zero) 
ldw t2, BALL+4(zero)
addi t0, t0, -1
addi t1, t0, 3
cmplt t3, t2, t1
cmpge t4, t2, t0
and t4, t4, t3 #true if is at the same level of the paddle i.e normal collision
bne t4, zero, invertSpeedNormal
#here we're sure no normal collision happened
ldw t4, BALL+12(zero)
add t4, t4, t2
cmpge t5, t4, t0
cmplt t6, t4, t1
and t4, t5, t6
bne t4, zero, invertSpeedCorner
addi v0, zero, 2
br exit

testHitAtRight:
ldw t0, PADDLES+4(zero) 
ldw t2, BALL+4(zero)
addi t0, t0, -1
addi t1, t0, 3
cmplt t3, t2, t1
cmpge t4, t2, t0
and t4, t4, t3 #true if is at the same level of the paddle i.e normal collision
bne t4, zero, invertSpeedNormal
#here we're sure no normal collision happened
ldw t4, BALL+12(zero)
add t4, t4, t2
cmpge t5, t4, t0
cmplt t6, t4, t1
and t4, t5, t6
bne t4, zero, invertSpeedCorner
addi v0, zero, 1
br exit

invertSpeedNormal: 
ldw t6, BALL+8(zero)
sub t6, zero, t6
stw t6, BALL+8(zero)
addi v0, zero, 0
br exit

invertSpeedCorner:
ldw t6, BALL+8(zero)
ldw t7, BALL+12(zero)
sub t6, zero, t6
sub t7, zero, t7
stw t6, BALL+8(zero)
stw t7, BALL+12(zero)
addi v0, zero, 0
br prexit
	
;END:hit_test

; BEGIN:move_ball
move_ball:
ldw t0, BALL(zero) ; load_position_x
ldw t1, BALL+4(zero); load_position_y
ldw t2, BALL+8(zero) ; load_velocity_x
ldw t3, BALL+12(zero); load_velocity_y

add t0, t0, t2
add t1, t1, t3

stw t0, BALL(zero)
stw t1, BALL+4(zero)
ret
; END: move_ball

; BEGIN:move_paddles
move_paddles:

ldw t0, BUTTONS+4(zero)

addi t1, zero, 1
addi t2, zero, 2
addi t3, zero, 4
addi t4, zero, 8

andi t5, t0, 1
beq t5, t1, left_up
 
andi t5, t0, 2
beq t5, t2,left_down
 
andi t5, t0, 4
beq t5, t3, right_down

andi t5, t0, 8
beq t5, t4,right_up

ret

left_up:
addi t6, zero, 1
ldw t7, PADDLES(zero)
beq t6, t7 , end_move
addi t7, t7, -1
stw t7, PADDLES(zero)
br end_move
ret

left_down:
addi t6, zero, 6
ldw t7, PADDLES(zero)
beq t6, t7 , end_move
addi t7, t7, 1
stw t7, PADDLES(zero)
br end_move
ret

right_up:
addi t6, zero, 1
ldw t7, PADDLES+4(zero)
beq t6, t7 , end_move
addi t7, t7, -1
stw t7, PADDLES+4(zero)
br end_move
ret

right_down:
addi t6, zero, 6
ldw t7, PADDLES+4(zero)
beq t6, t7 , end_move
addi t7, t7, 1
stw t7, PADDLES+4(zero)
br end_move
ret

end_move: 
xor t6, t0, t5
stw t6, BUTTONS+4(zero)
br move_paddles
ret 

; END:move_paddles

; BEGIN:draw_paddles
draw_paddles:
addi sp, sp, -12 ; push
stw a0, 0(sp)
stw a1, 4(sp)
stw ra, 8(sp)

addi a0, zero, 0
ldw a1, PADDLES(zero)
call set_pixel
addi a1, a1, 1
call set_pixel
addi a1, a1, -2
call set_pixel

addi a0, zero, 11
ldw a1, PADDLES+4(zero)
call set_pixel
addi a1, a1, 1
call set_pixel
addi a1, a1, -2
call set_pixel


ldw a0, 0(sp)
ldw a1, 4(sp)
ldw ra, 8(sp) ;pop
addi sp, sp, 12 
ret

; END:draw_paddles



; BEGIN:display_score

display_score:

ldw t0, SCORES(zero) ; player1_score
ldw t0, font_data(t0)
stw t0, LEDS(zero)

addi t1, zero , 64 ; separator
ldw t1, font_data(t1)
stw t1, LEDS+4(zero)

ldw  t3, SCORES+4(zero)
ldw  t3, font_data(t3)
stw  t3, LEDS+8(zero)
ret

font_data:
.word 0x7E427E00 ; 0
.word 0x407E4400 ; 1
.word 0x4E4A7A00 ; 2
.word 0x7E4A4200 ; 3
.word 0x7E080E00 ; 4
.word 0x7A4A4E00 ; 5
.word 0x7A4A7E00 ; 6
.word 0x7E020600 ; 7
.word 0x7E4A7E00 ; 8
.word 0x7E4A4E00 ; 9
.word 0x7E127E00 ; A
.word 0x344A7E00 ; B
.word 0x42423C00 ; C
.word 0x3C427E00 ; D
.word 0x424A7E00 ; E
.word 0x020A7E00 ; F
.word 0x00181800 ; separator


; END:display_score




