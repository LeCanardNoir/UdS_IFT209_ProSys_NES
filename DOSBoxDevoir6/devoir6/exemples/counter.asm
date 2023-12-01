	
 .inesprg 1
 .ineschr 1
 .inesmir 0
 .inesmap 0

 


;Memoire des sprites.  Le segment $700 - $7FF est entierement dedie aux sprites.
 .bss

NUMBERTILE.Y = $700
NUMBERTILE.T = $701
NUMBERTILE.S = $702
NUMBERTILE.X = $703


 .code		;Segment de code
 .org $c000		;débutant à l'adresse $C000 (banque PRG #0)

	;Fonction main.  Appelée lors d'une interruption Reset.

main:
	sei			;Interdit les interruptions IRQ et BRK
 	cld			;Mode décimal désactivé
 	ldx #$ff		;Prépare le pointeur de pile...
	txs			;Pointeur de pile initilisé au dessus de la pile
 	inx			;place la valeur 0 dans X


	stx $2000		;Initialise le PPU temporairement: NMI désactivées

 	jsr InitSpriteMem	;fonction qui met à zéro la mémoire des sprites
	jsr palette		;fonction qui initialise les palettes 
	jsr Dessiner	;fonction qui dessine le personnage
	jsr UpdateSprites ;fonction qui copie l'information dans la mémoire des sprites

	;Initialise le PPU:
	; ($2000)
	;-Interruptions NMI désactivées
	;-Grandeur des sprites: 8x8
	;-table de schémas pour l'arrière-plan: #0
	;-table de schémas pour les sprites: #1
	;-incrémentation d'index : +1
	;-numéro de table de noms affichée: 0

	;($2001)
	;-aucune modification d'intensité des couleurs
	;-sprites visibles
	;-arrière-plan invisible
	;-première colonne invisible pour les sprites et l'arrière-plan
	;-affichage couleur

	lda #%00001000	;place la valeur binaire 00010000 dans A
	sta $2000		;écrit dans le registre de contrôle #1
	lda #%00010000	;place la valeur binaire 00010000 dans A
	sta $2001		;écrit dans le registre de contrôle #2
	

main00:

	
	clc
	lda NUMBERTILE.T
	adc #1
	sta NUMBERTILE.T
	
	
	
	cmp	#10	
	bne main10
	
	lda #0
	sta NUMBERTILE.T	
	

main10:	
	jsr wait_vblank
	jsr UpdateSprites
	jmp main00		;Boucle infinie



	;Fonction qui attend une période de VBlank

wait_vblank:
 	bit $2002		;teste les bits du registre d'état du PPU
 	bpl wait_vblank	;tant que le bit 7 est éteint (signe = 0), on boucle
	
	rts			;fin	

	;Fonction qui met à zéro tous les 256 octets du segment réservé aux sprites

InitSpriteMem:
 	lda #0		;initialise A avec 0
	tay			;initialise Y avec 0 aussi

init00:
	sta $700,y		;écrit 0 à $700 + Y
	iny			;incrémente Y
	bne init00		;lorsque Y redevient 0 (255 + 1 = 0), fin	
	
	rts			;fin



	;segment de données contenant les numéros de couleur des palettes
paldata:

; Palette d'arrière-plan.  Variété de couleurs
	.byte	$0f,$16,$27,$18	;Mario normal	
	.byte	$0f,$38,$28,$16	;Mario furieux
	.byte	$0f,$20,$28,$1a	;Luigi
	.byte	$0f,$0f,$37,$07	;Goomba, briques
	
; Palette des sprites.  La couleur de fond est noir ($0f).	
	.byte	$0f,$20,$20,$20	;Noir & blanc
	.byte	$0f,$20,$20,$20	;Noir & blanc
	.byte	$0f,$20,$20,$20	;Noir & blanc
	.byte	$0f,$20,$20,$20	;Noir & blanc


		

	;fonction qui initialise les palettes.
palette:
	jsr wait_vblank		;attend une période de VBlank avant d'écrire

	lda #$3f			;initialise le registre d'index de la mémoire vidéo
	sta $2006			;avec l'adresse $3F00 : mémoire de palettes
	lda #0			;...
	sta $2006			;...
 
	ldx #0			;index de lecture des valeurs de palette

do_palette:
	lda paldata,x		;obtient un numéro de couleur
	sta $2007			;écrit le numéro de couleur dans le registre de données
	inx				;incrémente l'index
	cpx #32			;a-t-on écrit les 32 couleurs?
	bne do_palette		;sinon, continue
	
	rts				;fin






	


	;Routine d'interruption pour NMI: ne fait rien
nmi:     
 rti 

      ;Routine d'interruption pour IRQ/BRK: ne fait rien

int:
 rti

	;Mise à jour de la mémoire des sprites par DMA

UpdateSprites: 
 lda #7		;Segment de la mémoire $0700-$07FF
 sta $4014 		;déclenche la copie DMA 
 rts			;fin


	;Fonction Dessiner.  Initialise les 8 premiers sprites et les positionne correctement.

Dessiner:
	clc
	lda	#1
	sta	NUMBERTILE.T
	lda	#0	
	sta	NUMBERTILE.S
	lda	#$7F
	sta	NUMBERTILE.Y
	lda	#$7F
	sta	NUMBERTILE.X	

	rts	
	


 .bank 1
 .org $fffa
 .word nmi,main,int
 .bank 2
 .org 0
 .incbin "smbvrom.nes"
