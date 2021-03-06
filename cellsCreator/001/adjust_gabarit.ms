-- recup�rer les spline des fenetres, porte ... etc...
/*
 debug: le sript ne fonctionne pas sur des rep�res d�ja r�orient�s
	-- cr�ation du gabarit dans l'orientation de la normale de l'impact au mur pour avoir un gabarit � angle droit
	-- c'est l'ordre horaire des points qui pose probl�me, en fontion du sens de rotation de l'ordre des points  l'orientation de l'objet varie:
		-- dans le sens antihoraire c'est bon
		-- dans le sens horaire c'est pas bon
		-- solution: s'assurer que l'axe y du gabarit cr�� est positif?
		
	-- le reverse de spline focntionne mais pas le script  reverse spline(fianalement le script � l'air de fonctionner)
*/

-- teste si le rep�re est dans un mur
fn testImpactID l id =
(
	-- return boolean
	
	layerList = #(splinesMursExtLName, 
		splinesMursBalconLName,
		splinesMursFondLName,
		splinesMursIntName)
	
	theZ = [0,0,1]
	impact = false
	
	posI = (getKnotPoint l 1 id) - [0,0,500]
	testRay = (ray posI theZ)
	intersectTestI = intersectRayScene testRay
-- 	format "intersectTestI: %\n" intersectTestI
	if intersectTestI.count > 0 then 
	(
		-- blinder le test des murs
-- 		format "intersectTestI: %\n" intersectTestI[1][1].layer.name
		res = finditem layerList intersectTestI[1][1].layer.name
-- 		format "res: %\n" res
		if res > 0 then impact = true 
	)
		
	impact
)


-- si un rep�re est dans un mur retourne un nouvel ordre des points du rep�re
fn collectNewOrder s =
(
	newOrder = #(0,0,0,0)
	for i = 1 to (numKnots s) do 
	(
		local order
		local h, j
		local resH, resI, resJ
		
		if i == 4 then h = 1 else h = ( i + 1)
		if i == 1 then j = 4 else j = (i - 1)
	-- 		
		resH = testImpactID s h
		resI = testImpactID s i
		resJ = testImpactID s j
	-- 	
-- 		format "resH:% resI:% resJ:%\n"  resH resI resJ
		if resH and resI and not resJ then order = 2
		else if not resH and resI and resJ then order = 1
		else if not resH and not resI and resJ then order = 4
		else if resH and not resI and not resJ then order = 3
		else (order = 0)

	-- 		
		-- debug: verifier que les coordonn�es du point sont dans le systeme local de la spline ou du mone � la creation
		--  la creation des points se fait dans le coordsys world
		if order > 0 then newOrder[order] = (getKnotPoint s 1 i) else
		(
-- 			format "i fail= %\n" i
		)
	)
	format "s: % newOrder: %\n" s.name newOrder 
	newOrder
)
-- test = collectNewOrder $
-- 	point pos: test[1] wirecolor: green name: "1"
-- 	point pos: test[2] wirecolor: red name: "2"
-- 	point pos: test[3] wirecolor: blue name: "3"
-- 	point pos: test[4] wirecolor: blue name: "4"

-- retourne le mur dans lequel se trouve un rep�re
	-- fonctionne � partir du premier point du rep�re calculer (newOrder[1])
fn getMurImpacted rayStart =
(
	layerList = #(splinesMursExtLName, 
	splinesMursBalconLName,
	splinesMursFondLName,
	splinesMursIntName)
	
	local theMur
	theZ = [0,0,1]
	posI = rayStart - [0,0,500]
	
	testRay = (ray posI theZ)
	intersectTestI = intersectRayScene testRay
	format "intersectTestI: %\n" intersectTestI
	if intersectTestI.count > 0 then
	(
-- 		format "layer name: %\n" intersectTestI[1][1].layer.name		
		res = finditem layerList intersectTestI[1][1].layer.name
-- 		format "res: %\n" res
		if res > 0 then theMur = intersectTestI[1][1]
	)
	
	theMur
)

-- fn toto = format "banane toto toto\n"
-- var
-- s = $

fn adjustGabaritSpline s shift1: 3 shift2: 3 =
(
	converttosplineshape s

	theX
	theY
	theZ = [0,0,1]

	local oneMur 
	local murTM2
	local rayOrient 
	local impactAr = #()

	-- ################ calcul de la bonne orientation par rapport au mur
	local newOrder = collectNewOrder s
-- 	point pos: newOrder[1] wirecolor: green
-- 	point pos: newOrder[2] wirecolor: red
	
	if not newOrder[1] == 0 then
	(
		-- determination de Y
		theY = newOrder[2] -  newOrder[1]
		format "theY: %\n" theY

		-- determination de X
		theX = cross   (normalize theY)  theZ 
		-- murTM  =  (matrix3 theX (normalize theY) theZ copyS.pos)

		-- donner l'orientation � une copy de la spline 
		murTM2  =  (matrix3 theX (normalize theY) theZ s.pos)
		
		-- orientation du rep�re par rapport au mur
-- 		rayOrient = murTM2.row1
		rayOrient = theX
		
		-- retrouver le mur impacter par le repere
		oneMur = getMurImpacted  newOrder[1]
	)
	else(format "essayer de d�caler le rep�re: %\n" s.name)

	-- liste des rayon � tester sur le mur
		-- de k1 selon x
	if oneMur != undefined then
	(
		local shift =  [- 50, - 50, - 50] 

		-- de k1 selon x
		testRay1 = (ray (newOrder[1] + shift * rayOrient) rayOrient)
		impact1 = intersectRay oneMur testRay1
		
		-- de k2 selon x
		testRay2 = (ray (newOrder[2] +shift * rayOrient) rayOrient)
		impact2 = intersectRay oneMur testRay2
		
		-- de k3 selon - x
-- 		testRay3 = (ray (newOrder[3] + shift * -rayOrient) -rayOrient)
		testRay3 = (ray (newOrder[3]) -rayOrient)
		impact3 = intersectRay oneMur testRay3
		
		-- de k4 selon - x
-- 		testRay4 = (ray (newOrder[4] + shift * -rayOrient) -rayOrient)
		testRay4 = (ray (newOrder[4]) -rayOrient)
		impact4 = intersectRay oneMur testRay4
		
		/* 
		-- points temoin
		pt1 = point transform: murTM2  wirecolor: green name: "1" axistripod: on cross: false
		pt1.pos = (newOrder[1] + shift * rayOrient)
		point pos: (newOrder[2] + shift * rayOrient)  wirecolor: red name: "2"
		point pos: (newOrder[3] + shift * -rayOrient)  wirecolor: blue name: "3"
		point pos: (newOrder[4] + shift * -rayOrient)  wirecolor: blue name: "4"
		*/
		
		tripleShift1 = [shift1, shift1, shift1] * -rayOrient
		tripleShift2 = [shift2, shift2, shift2] * rayOrient
		
		if impact1 == undefined or   impact2 == undefined or  impact3 == undefined or  impact4 == undefined then
		(
			format "pas assez d'impact sur le mur\n"
			format "impact1: %\n" impact1
			format "impact2: %\n" impact2
			format "impact3: %\n" impact3
			format "impact4: %\n" impact4
		)
		else
		(
			impactAr = #((impact1.pos + tripleShift1), (impact2.pos + tripleShift1), (impact3.pos + tripleShift2), (impact4.pos + tripleShift2))
		)
		
	)else(format "pas de mur!\n")
	
	
	local done = false
	
	if impactAr.count == 4 and not oneMur == undefined then
	(		
		-- application du transform
		s.transform = murTM2
		
		-- appliquer les impact � la position de la spline
		for i = 1 to (numKnots s) do
		(
			setKnotPoint s 1 i impactAr[i]
			setKnotType  s  1 i #corner
		)
		updateShape s
		
		done = true
	)
	else(format "quelque chose a foir�\n")
	
	done
)

try(destroydialog adjustGabaritRLT)catch()
rollout adjustGabaritRLT "Ajuster les gabarit de porte et fen�tre"
(
	spinner shift1SP "decalage -x:" type: #worldunits range: [0,500, 3] across: 2
	spinner shift2SP "decalage +x:" type: #worldunits range: [0,500, 30]
	button adjustBT "ajuster les gabarits selectionn�s"
	
	on adjustBT pressed do
	(
		sel  = selection as array
		
		for s in sel do
		(
			copyS = copy s
			copyS.wirecolor = s.wirecolor
			s.layer.Addnode copyS
			local res = adjustGabaritSpline copyS shift1: shift1SP.value shift2: shift2SP.value
			if not res then delete copyS
			 
		)
		
-- 		select sel
	)
)


-- createdialog adjustGabaritRLT width: 300

