
;D�clarations n�cessaires � l'en-t�te du fichier compil� en format iNes.
	
 .inesprg 1			;Nombre de banques de PRG-ROM: 1
 .ineschr 1			;Nombre de banques de CHR-ROM: 1
 .inesmir 0			;Type de miroir des tables de noms: 0 = horizontal
 .inesmap 0			;Type de MMU: 0, aucun MMU

 


;Memoire des sprites.  Le segment $700 - $7FF est entierement d�di� aux sprites.
 .bss


CLOCK.DIGIT.Y	=	$700		;Premier octet: coordonn�e Y
CLOCK.DIGIT.T	=	$701		;second octet: num�ro de tuile
CLOCK.DIGIT.S	=	$702		;troisi�me octet: attributs
CLOCK.DIGIT.X	=	$703		;quatri�me octet: coordonn�e X




CLOCK.COUNTER = $00


 .code							;Segment de code
 .org $c000						;d�butant � l'adresse $C000 (banque PRG #0)

	;Fonction main.  Appel�e lors d'une interruption Reset.  Initialisations suivies d'une boucle infinie.

Main:
	sei							;Interdit les interruptions IRQ et BRK
 	cld							;Mode d�cimal d�sactiv�
 	ldx #$ff					;Pr�pare le pointeur de pile...
	txs							;Pointeur de pile initilis� au dessus de la pile
 	inx							;place la valeur 0 dans X
	stx $2000					;Initialise le PPU temporairement: NMI d�sactiv�es
	
	stx	<CLOCK.COUNTER			;Initialise le compteur de l'horloge � 0

 	jsr InitSpriteMem			;Mise � z�ro du segment de m�moire contenant les sprites
	jsr palette					;fonction qui initialise les palettes 
	
	
	lda	#1						;Initialise le no de tuile � 1
	sta	CLOCK.DIGIT.T			;...
	lda	#120					;Positionne le chiffre � (128,120)
	sta	CLOCK.DIGIT.Y			;...
	lda	#128					;...
	sta	CLOCK.DIGIT.X			;...
	lda	#0						;Les attributs sont  � 0 : palette 0 et aucune transformation
	sta	CLOCK.DIGIT.S			;....
	
	
	jsr		wait_vblank			;Attend une p�riode de VBlank avant de faire des modifications
	
	lda		#$07				;Le segment de la m�moire choisi est $0700 � $07FF
	sta		$4014				; Mise � jour de la m�moire des sprites par DMA
	
	;Initialise le PPU:
	; ($2000)
	;-Interruptions NMI activ�es
	;-Grandeur des sprites: 8x8
	;-table de sch�mas pour l'arri�re-plan: #1
	;-table de sch�mas pour les sprites: #0
	;-incr�mentation d'index : +1
	;-num�ro de table de noms affich�e: 0

	;($2001)
	;-aucune modification d'intensit� des couleurs
	;-sprites visibles
	;-arri�re-plan invisible
	;-premi�re colonne invisible pour les sprites et l'arri�re-plan
	;-affichage couleur

	
	lda #%00010000	;place la valeur binaire 00010000 dans A
	sta $2001		;�crit dans le registre de contr�le #2
	lda #%10001000	;place la valeur binaire 10001000 dans A
	sta $2000		;�crit dans le registre de contr�le #1
	
mainEnd:
	jmp mainEnd		;Boucle infinie



	;Fonction qui attend une p�riode de VBlank

wait_vblank:
 	bit $2002				;teste les bits du registre d'�tat du PPU
 	bpl wait_vblank			;tant que le bit 7 est �teint (signe = 0), on boucle
	
	rts						;fin	

	
	
	;Fonction qui met � z�ro tous les 256 octets du segment r�serv� aux sprites

InitSpriteMem:
 	lda #0			;initialise A avec 0
	tay				;initialise Y avec 0 aussi

init00:
	sta $700,y		;�crit 0 � $700 + Y
	iny				;incr�mente Y
	bne init00		;lorsque Y redevient 0 (255 + 1 = 0), fin	
	
	rts				;fin



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
	lda #0				;...
	sta $2006			;...
 
	ldx #0				;index de lecture des valeurs de palette

do_palette:
	lda paldata,x		;obtient un num�ro de couleur
	sta $2007			;�crit le num�ro de couleur dans le registre de donn�es
	inx					;incr�mente l'index
	cpx #32				;a-t-on �crit les 32 couleurs?
	bne do_palette		;sinon, continue
	
	rts					;fin



	;Routine d'interruption pour NMI: Met � jour le compteur et le sprite � l'�cran quand une seconde s'est �coul�e.
	;Aucune sauvegarde des registres n'est fait parce que le Main ne les utilise plus lorsque les interruptions ont activ�es.
NMI_InterruptRoutine:   

			clc							;Place le report � 0
			lda		<CLOCK.COUNTER		;R�cup�re le compteur
			adc		#1					;incr�mente le compteur
			sta		<CLOCK.COUNTER		;met � jour la variable
			sec							;Place le report � 1 (et donc l'emprunt � 0)
			sbc		#60					;compare avec 60
			bne		NMI_fin				;si on n'a pas atteint 60, rien � faire
			
			;CLOCK.COUNTER == 60: il faut mettre � jour le chiffre affich�
			
			lda		#0					
			sta		<CLOCK.COUNTER		;replace le compteur � 0
			clc							;Place le report � 0
			lda		#1					;Acc = 1
			adc		CLOCK.DIGIT.T		;Acc += No. de tuile
			sta		CLOCK.DIGIT.T		;Met � jour le no de tuile
			sec							;emprunt = 0
			sbc		#11					;a-t-on d�pass� la tuile no 10 (caract�re '9') ?
			bne		NMI_10				;non, mise � jour des sprites
			
			;No de tuile plus grand que 10: il faut retourner � la tuile no 1 (caract�re '0')
			
			lda		#1
			sta		CLOCK.DIGIT.T		;no de tuile = 1
			
NMI_10:		lda		#$07				;Le segment de la m�moire choisi est $0700 � $07FF
			sta		$4014				; Mise � jour de la m�moire des sprites par DMA
		
NMI_fin:	rti 						;fin de l'interruption.


      ;Routine d'interruption pour IRQ/BRK: ne fait rien

IRQ_BRK_InterruptRoutine:
			rti							;fin de l'interruption.



			
 .bank 1
 .org $fffa								;Positionne le compteur d'emplacement � $FFFA, le d�but des vecteurs d'interruption
 .word NMI_InterruptRoutine				;Premier segment de 16 bits, adresse de la routine NMI ($FFFA, $FFFB)
 .word Main								;Second segment de 16 bits, adresse de la routine BREAK ($FFFC, $FFFD)
 .word IRQ_BRK_InterruptRoutine;			;Dernier segment de 16 bits, adresse de la routine BREAK ($FFFE, $FFFF)
 
 .bank 2
 .org 0									;Positionne le compteur au d�but de la banque #2
 .incbin "smbvrom.nes"					;Remplit la banque avec le fichier contenant les sch�mas des tuiles
