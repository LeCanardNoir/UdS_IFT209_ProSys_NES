
;Déclarations nécessaires à l'en-tête du fichier compilé en format iNes.
	
 .inesprg 1			;Nombre de banques de PRG-ROM: 1
 .ineschr 1			;Nombre de banques de CHR-ROM: 1
 .inesmir 0			;Type de miroir des tables de noms: 0 = horizontal
 .inesmap 0			;Type de MMU: 0, aucun MMU

 


;Memoire des sprites.  Le segment $700 - $7FF est entierement dédié aux sprites.
 .bss


CLOCK.DIGIT.Y	=	$700		;Premier octet: coordonnée Y
CLOCK.DIGIT.T	=	$701		;second octet: numéro de tuile
CLOCK.DIGIT.S	=	$702		;troisième octet: attributs
CLOCK.DIGIT.X	=	$703		;quatrième octet: coordonnée X




CLOCK.COUNTER = $00


 .code							;Segment de code
 .org $c000						;débutant à l'adresse $C000 (banque PRG #0)

	;Fonction main.  Appelée lors d'une interruption Reset.  Initialisations suivies d'une boucle infinie.

Main:
	sei							;Interdit les interruptions IRQ et BRK
 	cld							;Mode décimal désactivé
 	ldx #$ff					;Prépare le pointeur de pile...
	txs							;Pointeur de pile initilisé au dessus de la pile
 	inx							;place la valeur 0 dans X
	stx $2000					;Initialise le PPU temporairement: NMI désactivées
	
	stx	<CLOCK.COUNTER			;Initialise le compteur de l'horloge à 0

 	jsr InitSpriteMem			;Mise à zéro du segment de mémoire contenant les sprites
	jsr palette					;fonction qui initialise les palettes 
	
	
	lda	#1						;Initialise le no de tuile à 1
	sta	CLOCK.DIGIT.T			;...
	lda	#120					;Positionne le chiffre à (128,120)
	sta	CLOCK.DIGIT.Y			;...
	lda	#128					;...
	sta	CLOCK.DIGIT.X			;...
	lda	#0						;Les attributs sont  à 0 : palette 0 et aucune transformation
	sta	CLOCK.DIGIT.S			;....
	
	
	jsr		wait_vblank			;Attend une période de VBlank avant de faire des modifications
	
	lda		#$07				;Le segment de la mémoire choisi est $0700 à $07FF
	sta		$4014				; Mise à jour de la mémoire des sprites par DMA
	
	;Initialise le PPU:
	; ($2000)
	;-Interruptions NMI activées
	;-Grandeur des sprites: 8x8
	;-table de schémas pour l'arrière-plan: #1
	;-table de schémas pour les sprites: #0
	;-incrémentation d'index : +1
	;-numéro de table de noms affichée: 0

	;($2001)
	;-aucune modification d'intensité des couleurs
	;-sprites visibles
	;-arrière-plan invisible
	;-première colonne invisible pour les sprites et l'arrière-plan
	;-affichage couleur

	
	lda #%00010000	;place la valeur binaire 00010000 dans A
	sta $2001		;écrit dans le registre de contrôle #2
	lda #%10001000	;place la valeur binaire 10001000 dans A
	sta $2000		;écrit dans le registre de contrôle #1
	
mainEnd:
	jmp mainEnd		;Boucle infinie



	;Fonction qui attend une période de VBlank

wait_vblank:
 	bit $2002				;teste les bits du registre d'état du PPU
 	bpl wait_vblank			;tant que le bit 7 est éteint (signe = 0), on boucle
	
	rts						;fin	

	
	
	;Fonction qui met à zéro tous les 256 octets du segment réservé aux sprites

InitSpriteMem:
 	lda #0			;initialise A avec 0
	tay				;initialise Y avec 0 aussi

init00:
	sta $700,y		;écrit 0 à $700 + Y
	iny				;incrémente Y
	bne init00		;lorsque Y redevient 0 (255 + 1 = 0), fin	
	
	rts				;fin



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
	jsr wait_vblank		;attend une période de VBlank avant d'écrire

	lda #$3f			;initialise le registre d'index de la mémoire vidéo
	sta $2006			;avec l'adresse $3F00 : mémoire de palettes
	lda #0				;...
	sta $2006			;...
 
	ldx #0				;index de lecture des valeurs de palette

do_palette:
	lda paldata,x		;obtient un numéro de couleur
	sta $2007			;écrit le numéro de couleur dans le registre de données
	inx					;incrémente l'index
	cpx #32				;a-t-on écrit les 32 couleurs?
	bne do_palette		;sinon, continue
	
	rts					;fin



	;Routine d'interruption pour NMI: Met à jour le compteur et le sprite à l'écran quand une seconde s'est écoulée.
	;Aucune sauvegarde des registres n'est fait parce que le Main ne les utilise plus lorsque les interruptions ont activées.
NMI_InterruptRoutine:   

			clc							;Place le report à 0
			lda		<CLOCK.COUNTER		;Récupère le compteur
			adc		#1					;incrémente le compteur
			sta		<CLOCK.COUNTER		;met à jour la variable
			sec							;Place le report à 1 (et donc l'emprunt à 0)
			sbc		#60					;compare avec 60
			bne		NMI_fin				;si on n'a pas atteint 60, rien à faire
			
			;CLOCK.COUNTER == 60: il faut mettre à jour le chiffre affiché
			
			lda		#0					
			sta		<CLOCK.COUNTER		;replace le compteur à 0
			clc							;Place le report à 0
			lda		#1					;Acc = 1
			adc		CLOCK.DIGIT.T		;Acc += No. de tuile
			sta		CLOCK.DIGIT.T		;Met à jour le no de tuile
			sec							;emprunt = 0
			sbc		#11					;a-t-on dépassé la tuile no 10 (caractère '9') ?
			bne		NMI_10				;non, mise à jour des sprites
			
			;No de tuile plus grand que 10: il faut retourner à la tuile no 1 (caractère '0')
			
			lda		#1
			sta		CLOCK.DIGIT.T		;no de tuile = 1
			
NMI_10:		lda		#$07				;Le segment de la mémoire choisi est $0700 à $07FF
			sta		$4014				; Mise à jour de la mémoire des sprites par DMA
		
NMI_fin:	rti 						;fin de l'interruption.


      ;Routine d'interruption pour IRQ/BRK: ne fait rien

IRQ_BRK_InterruptRoutine:
			rti							;fin de l'interruption.



			
 .bank 1
 .org $fffa								;Positionne le compteur d'emplacement à $FFFA, le début des vecteurs d'interruption
 .word NMI_InterruptRoutine				;Premier segment de 16 bits, adresse de la routine NMI ($FFFA, $FFFB)
 .word Main								;Second segment de 16 bits, adresse de la routine BREAK ($FFFC, $FFFD)
 .word IRQ_BRK_InterruptRoutine;			;Dernier segment de 16 bits, adresse de la routine BREAK ($FFFE, $FFFF)
 
 .bank 2
 .org 0									;Positionne le compteur au début de la banque #2
 .incbin "smbvrom.nes"					;Remplit la banque avec le fichier contenant les schémas des tuiles
