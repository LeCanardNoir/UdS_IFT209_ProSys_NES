	
 .inesprg 1
 .ineschr 1
 .inesmir 0
 .inesmap 0

 


;Memoire des sprites.  Le segment $700 - $7FF est entierement dedie aux sprites.
 .bss
 
DEFIL =$600
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



 .code			;Segment de code
 .org $c000		;débutant à l'adresse $C000 (banque PRG #0)

	;Fonction main.  Appelée lors d'une interruption Reset.

Main:
	sei			;Interdit les interruptions IRQ et BRK
 	cld			;Mode décimal désactivé
 	ldx #$ff		;Prépare le pointeur de pile...
	txs			;Pointeur de pile initilisé au dessus de la pile
 	inx			;place la valeur 0 dans X


	stx $2000		;Initialise le PPU temporairement: NMI désactivées

 	jsr InitSpriteMem		;fonction qui met à zéro la mémoire des sprites
	jsr palette				;fonction qui initialise les palettes 
	jsr Dessiner			;fonction qui dessine le personnage
	jsr UpdateSprites 		;fonction qui copie l'information dans la mémoire des sprites
	jsr InitBackground		;Initialise l'arrière-plan 

	lda		#0				;Initialise le défilement
	sta		$2005			;... 0 en X
	sta		$2005			;... 0 en Y
	
	;Initialise le PPU:
	; ($2000)
	;-Interruptions NMI activées
	;-Grandeur des sprites: 8x8
	;-table de schémas pour l'arrière-plan: #0
	;-table de schémas pour les sprites: #1
	;-incrémentation d'index : +1
	;-numéro de table de noms affichée: 0

	;($2001)
	;-aucune modification d'intensité des couleurs
	;-sprites visibles
	;-arrière-plan visible
	;-première colonne invisible pour les sprites mais pas pour l'arrière-plan
	;-affichage couleur

	lda #%10010000	;place la valeur binaire 10010000 dans A
	sta $2000		;écrit dans le registre de contrôle #1
	lda #%00011010	;place la valeur binaire 00011010 dans A
	sta $2001		;écrit dans le registre de contrôle #2

    ldx #0
    stx DEFIL
mainEnd:
	jmp mainEnd		;Boucle infinie



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
	iny				;incrémente Y
	bne init00		;lorsque Y redevient 0 (255 + 1 = 0), fin	
	
	rts			;fin



	;segment de données contenant les numéros de couleur des palettes
paldata:

; Palette d'arrière-plan.  Tout est noir sauf la première palette
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
	jsr wait_vblank			;attend une période de VBlank avant d'écrire

	lda #$3f				;initialise le registre d'index de la mémoire vidéo
	sta $2006				;avec l'adresse $3F00 : mémoire de palettes
	lda #0					;...
	sta $2006				;...
 
	ldx #0					;index de lecture des valeurs de palette

do_palette:
	lda paldata,x			;obtient un numéro de couleur
	sta $2007				;écrit le numéro de couleur dans le registre de données
	inx						;incrémente l'index
	cpx #32					;a-t-on écrit les 32 couleurs?
	bne do_palette			;sinon, continue
	
	rts						;fin






	


	;Routine d'interruption pour NMI: met à jour les sprites
NMI_InterruptRoutine:    

            ldx DEFIL
            stx $2005            
            inx
            inx
            inx
            inx
            stx DEFIL
            ldx #0
            stx $2005


		;	lda	#$07		;Les sprites se trouvent dans le segment $0700 à $07FF
		;	sta	$4014		;Commande de copie DMA de tout le segment $0700 à $07FF dans la mémoire des sprites
		
 rti 

      ;Routine d'interruption pour IRQ/BRK: ne fait rien

IRQ_BRK_InterruptRoutine:
 rti

	;Mise à jour de la mémoire des sprites par DMA

UpdateSprites: 
 lda #7			;Segment de la mémoire $0700-$07FF
 sta $4014 		;déclenche la copie DMA 
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
	lda	#159
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
	
	
	
InitBackground:

	jsr		wait_vblank		;attend une période de VBlank avant d'écrire dans la table de noms
	
	lda		#0
	sta		$2005
	sta		$2005
	
	lda		#$20			;8 bits supérieurs de l'adresse de la table de noms #0
	sta		$2006			;écriture dans l'index
	lda		#00				;8 bits inférieurs
	sta		$2006			;écriture dans l'index
	ldx		#0				;Initialise le compteur à 0
	
	
initbg10:
	
	lda		bgdata0,X		;lit l'octet à bgdata0 + X, le no de tuile courant	
	sta		$2007			;écrit dans la table de noms
	inx						;incrémente l'index
	cpx		#0				;a-t-on passé toutes les tuiles?
	bne		initbg10		;sinon, suite 
	
	
initbg20:
	
	lda		bgdata1,X		;lit l'octet à bgdata1 + X, le no de tuile courant
	sta		$2007			;écrit dans la table de noms
	inx						;incrémente l'index
	cpx		#0				;a-t-on passé toutes les tuiles?
	bne		initbg20		;sinon, suite 
	
initbg30:
	
	lda		bgdata2,X		;lit l'octet à bgdata2 + X, le no de tuile courant
	sta		$2007			;écrit dans la table de noms
	inx						;incrémente l'index
	cpx		#0				;a-t-on passé toutes les tuiles?
	bne		initbg30		;sinon, suite 
	

initbg40:
	
	lda		bgdata3,X		;lit l'octet à bgdata3 + X, le no de tuile courant
	sta		$2007			;écrit dans la table de noms
	inx						;incrémente l'index
	cpx		#192		;a-t-on passé toutes les tuiles?
	bne		initbg40		;sinon, suite 
	
	rts						;fin du sous-programme.
	
;Données initiales se trouvant dans la table de noms.
;Matrice de 32x30 tuiles.
	
	bgdata0:	
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25	
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	bgdata1:
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25	
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	bgdata2:
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$32,$33,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$31,$35,$27,$34,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$31,$27,$27,$27,$27,$34,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$31,$27,$35,$27,$27,$35,$27,$34,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $31,$27,$27,$27,$27,$27,$27,$27,$27,$34,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	bgdata3:
	.byte $b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6
	.byte $b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6
	.byte $b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8
	.byte $b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8
	.byte $b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6
	.byte $b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6
	.byte $b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8
	.byte $b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8	
	.byte $b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6
	.byte $b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6,$b5,$b6
	.byte $b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8
	.byte $b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8,$b7,$b8
	
	

 .bank 1
 .org $fffa
 .word NMI_InterruptRoutine,Main,IRQ_BRK_InterruptRoutine
 .bank 2
 .org 0
 .incbin "smbvrom.nes"
