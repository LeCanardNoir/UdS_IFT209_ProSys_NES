	
 .inesprg 1
 .ineschr 1
 .inesmir 0
 .inesmap 0

 


;Memoire des sprites.  Le segment $700 - $7FF est entierement dedie aux sprites.
 .bss
MARIO.HEADLEFT.Y = $700
MARIO.HEADLEFT.T = $701
MARIO.HEADLEFT.S = $702
MARIO.HEADLEFT.X = $703

MARIO.HEADRIGHT.Y = $704
MARIO.HEADRIGHT.T = $705
MARIO.HEADRIGHT.S = $706
MARIO.HEADRIGHT.X = $707

MARIO.CHESTLEFT.Y = $708
MARIO.CHESTLEFT.T = $709
MARIO.CHESTLEFT.S = $70A
MARIO.CHESTLEFT.X = $70B

MARIO.CHESTRIGHT.Y = $70C
MARIO.CHESTRIGHT.T = $70D
MARIO.CHESTRIGHT.S = $70E
MARIO.CHESTRIGHT.X = $70F


MARIO.BELLYLEFT.Y = $710
MARIO.BELLYLEFT.T = $711
MARIO.BELLYLEFT.S = $712
MARIO.BELLYLEFT.X = $713

MARIO.BELLYRIGHT.Y = $714
MARIO.BELLYRIGHT.T = $715
MARIO.BELLYRIGHT.S = $716
MARIO.BELLYRIGHT.X = $717

MARIO.FEETLEFT.Y = $718
MARIO.FEETLEFT.T = $719
MARIO.FEETLEFT.S = $71A
MARIO.FEETLEFT.X = $71B

MARIO.FEETRIGHT.Y = $71C
MARIO.FEETRIGHT.T = $71D
MARIO.FEETRIGHT.S = $71E
MARIO.FEETRIGHT.X = $71F



 .code		;Segment de code
 .org $c000		;d�butant � l'adresse $C000 (banque PRG #0)

	;Fonction main.  Appel�e lors d'une interruption Reset.

main:
	sei			;Interdit les interruptions IRQ et BRK
 	cld			;Mode d�cimal d�sactiv�
 	ldx #$ff		;Pr�pare le pointeur de pile...
	txs			;Pointeur de pile initilis� au dessus de la pile
 	inx			;place la valeur 0 dans X


	stx $2000		;Initialise le PPU temporairement: NMI d�sactiv�es

 	jsr InitSpriteMem	;fonction qui met � z�ro la m�moire des sprites
	jsr palette		;fonction qui initialise les palettes 
	jsr Dessiner	;fonction qui dessine le personnage
	jsr UpdateSprites ;fonction qui copie l'information dans la m�moire des sprites

	;Initialise le PPU:
	; ($2000)
	;-Interruptions NMI d�sactiv�es
	;-Grandeur des sprites: 8x8
	;-table de sch�mas pour l'arri�re-plan: #0
	;-table de sch�mas pour les sprites: #1
	;-incr�mentation d'index : +1
	;-num�ro de table de noms affich�e: 0

	;($2001)
	;-aucune modification d'intensit� des couleurs
	;-sprites visibles
	;-arri�re-plan invisible
	;-premi�re colonne invisible pour les sprites et l'arri�re-plan
	;-affichage couleur

	lda #%00010000	;place la valeur binaire 00010000 dans A
	sta $2000		;�crit dans le registre de contr�le #1
	lda #%00010000	;place la valeur binaire 00010000 dans A
	sta $2001		;�crit dans le registre de contr�le #2

    ldx #1
    
mainEnd:

    ldx MARIO.HEADLEFT.X
    inx
    stx MARIO.HEADLEFT.X
    
    jsr wait_vblank
    jsr UpdateSprites
    
    
    
    
    jmp mainEnd		;Boucle infinie



	;Fonction qui attend une p�riode de VBlank

wait_vblank:
 	bit $2002		;teste les bits du registre d'�tat du PPU
 	bpl wait_vblank	;tant que le bit 7 est �teint (signe = 0), on boucle
	
	rts			;fin	

	;Fonction qui met � z�ro tous les 256 octets du segment r�serv� aux sprites

InitSpriteMem:
 	lda #0		;initialise A avec 0
	tay			;initialise Y avec 0 aussi

init00:
	sta $700,y		;�crit 0 � $700 + Y
	iny			;incr�mente Y
	bne init00		;lorsque Y redevient 0 (255 + 1 = 0), fin	
	
	rts			;fin



	;segment de donn�es contenant les num�ros de couleur des palettes
paldata:

; Palette d'arri�re-plan.  Tout est noir sauf la premi�re palette
	.byte	$0f,$20,$10,$00	;Tons de gris, pratique pour voir les tuiles en debug
	.byte	$0f,$0f,$0f,$0f	;Noir
	.byte	$0f,$0f,$0f,$0f	;Noir
	.byte	$0f,$0f,$0f,$0f	;Noir

; Palette des sprites.  La couleur de fond est noir ($0f).
	.byte	$0f,$16,$27,$18	;Mario normal	
	.byte	$0f,$38,$28,$16	;Mario furieux
	.byte	$0f,$20,$28,$1a	;Luigi
	.byte	$0f,$0f,$37,$07	;Goomba, briques		

	;fonction qui initialise les palettes.
palette:
	jsr wait_vblank		;attend une p�riode de VBlank avant d'�crire

	lda #$3f			;initialise le registre d'index de la m�moire vid�o
	sta $2006			;avec l'adresse $3F00 : m�moire de palettes
	lda #0			;...
	sta $2006			;...
 
	ldx #0			;index de lecture des valeurs de palette

do_palette:
	lda paldata,x		;obtient un num�ro de couleur
	sta $2007			;�crit le num�ro de couleur dans le registre de donn�es
	inx				;incr�mente l'index
	cpx #32			;a-t-on �crit les 32 couleurs?
	bne do_palette		;sinon, continue
	
	rts				;fin






	


	;Routine d'interruption pour NMI: ne fait rien
nmi:     
 rti 

      ;Routine d'interruption pour IRQ/BRK: ne fait rien

int:
 rti

	;Mise � jour de la m�moire des sprites par DMA

UpdateSprites: 
 lda #7		;Segment de la m�moire $0700-$07FF
 sta $4014 		;d�clenche la copie DMA 
 rts			;fin


	;Fonction Dessiner.  Initialise les 8 premiers sprites et les positionne correctement.

Dessiner:
	clc
	lda	#1
	sta	MARIO.HEADLEFT.T
	lda	#0	
	sta	MARIO.HEADLEFT.S
	lda	#0
	sta	MARIO.HEADLEFT.Y
	lda	#0
	sta	MARIO.HEADLEFT.X

	lda	#2	
	sta	MARIO.HEADRIGHT.T

	lda	#0
	sta	MARIO.HEADRIGHT.S	
	lda	#0
	sta	MARIO.HEADRIGHT.Y
	lda	#8
	sta	MARIO.HEADRIGHT.X

	lda	#77
	sta	MARIO.CHESTLEFT.T
	lda	#0
	sta	MARIO.CHESTLEFT.S
	lda	#8
	sta	MARIO.CHESTLEFT.Y
	lda	#0
	sta	MARIO.CHESTLEFT.X

	lda	#78
	sta	MARIO.CHESTRIGHT.T
	lda	#0
	sta	MARIO.CHESTRIGHT.S
	lda	#8
	sta	MARIO.CHESTRIGHT.Y
	lda	#8
	sta	MARIO.CHESTRIGHT.X

	lda	#75
	sta	MARIO.BELLYLEFT.T
	sta	MARIO.BELLYRIGHT.T
	lda	#0	
	sta	MARIO.BELLYLEFT.S	
	lda	#16
	sta	MARIO.BELLYLEFT.Y
	lda	#0
	sta	MARIO.BELLYLEFT.X


	lda	#%01000000
	sta	MARIO.BELLYRIGHT.S
	lda	#16
	sta	MARIO.BELLYRIGHT.Y
	lda	#8
	sta	MARIO.BELLYRIGHT.X


	lda	#76
	sta	MARIO.FEETLEFT.T
	sta	MARIO.FEETRIGHT.T
	lda	#0
	sta	MARIO.FEETLEFT.S	

	lda	#24
	sta	MARIO.FEETLEFT.Y
	lda	#0
	sta	MARIO.FEETLEFT.X


	lda	#%01000000
	sta	MARIO.FEETRIGHT.S

	lda	#24
	sta	MARIO.FEETRIGHT.Y
	lda	#8
	sta	MARIO.FEETRIGHT.X


	ldx	#0
	
dessiner10:
	clc
	lda	#$7F
	adc	MARIO.HEADLEFT.Y,X
	sta	MARIO.HEADLEFT.Y,X
	
	clc
	lda	#$7F
	adc	MARIO.HEADLEFT.X,X
	sta	MARIO.HEADLEFT.X,X	
	inx
	inx
	inx
	inx
	cpx	#32
	bne	dessiner10
	

	rts	
	


 .bank 1
 .org $fffa
 .word nmi,main,int
 .bank 2
 .org 0
 .incbin "smbvrom.nes"
