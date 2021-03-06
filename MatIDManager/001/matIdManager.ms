/*
 faire travailler au choix sur la scene, les objets visibles ou la selection d'objet ou les multimaterial
 
 travailler avec les vray effect id sur les vray mat (pour le moment, ignorer les material id, les sur materiaux vray ou les mat standard)
	- lister material id pour nettoyage
	
 x une interface pour appliquer des effect id aux materiaux
	 x un tool pour publier les multi mat
		rammasser tous les materiaux compos� et pas seulement les multimat
	 x assign id en random sur un set de vray mat 
		en respectant les ids deja affectes
		faire fonctionner sur la selection
	x assigner un id non utilis� sur une selection de materiaux
 
 x--une interface pour manager les ids(retrouver les objets par ids, publier les materiaux avec le m�me ids)
	 /une interface pour parametrer la passe material id et les passes vrayobjectselect et les multimatteelement
	  passer la liste d'id en multilist
	  cr�er les passes des id selectionn�es

*/
-- appliquer une id de materiau aux materiaux des object selectionn�s

fn sortbyname v1 v2 =
(
	-- 	vars
	local d
	
	if ( (toupper v1.name) < (toupper v2.name)) then
		d=1
	else
		d=-1
	
	--compare les numeros entre eux et les classe	
	case of
	(
		(d < 0.): 1
		(d > 0.): -1
		default: 0
	)
)

fn collectVisibleMat =
(
	-- travailler sur les materiaux des objets selectionn�s
-- 		sel = selection as array
	local oneMatAr

	-- travailler sur les materiaux des objets visibles�s
	local sel = for o in  $* where o.ishidden == false collect o

	-- collecte des materiaux du set d objet
	local matSel = #()
	for s in sel where s.material != undefined  do
	(
		appendifunique matSel s.material
	)

	-- collecte des vray mat du set
	oneMatAr = #()
	for m in matSel do
	(
		tmpMatAr = getclassinstances vrayMtl target: m
		for tmpM in tmpMatAr do appendifunique oneMatAr tmpM
-- 			format "tmpMatAr: %\n" tmpMatAr
		windows.ProcessPostedMessages()
	)

	oneMatAr
)

fn collectVisibleMultiMat =
(
-- 	local oneMatAr

	-- travailler sur les materiaux des objets visibles�s
	local sel = for o in  $* where o.ishidden == false collect o

	-- collecte des materiaux du set d objet
	local matSel = #()
	for s in sel where s.material != undefined  do
	(
		appendifunique matSel s.material
	)
	
	for m in matSel where iskindof m multimaterial collect m
)
-- collectVisibleMultiMat()

fn collectMatIDs =
(
	local idsAr = #()
	local matArTmp = getclassinstances vrayMtl target: scenematerials
	
-- 	local idsAr
	for m in matArTmp do appendifunique idsAr m.effect_id
	sort idsAr
	format "idsAr: %\n" idsAr
	idsAr
)


fn returnCleanId =
(
	-- collecter les ids de materiaux deja affecter dans la scene
	local usedIds = collectMatIDs()

	-- appliquer les ids de materiaux en evitant les ids deja attribu�es
	local j = 0
	j += 1
	local jAr = #(j)

	local turn = 0

	-- determination d'une id disponible
	for id in jAr do
	(
		-- test de l'id			
		local res = finditem usedIds id
-- 		format "id: % res:%\n" id res
		
		-- si l'id�e est d�
		if res > 0 then 
		(
			j += 1
			append jAR j
		)
		
		-- s�curit� anti boucle
		turn +=1 
		if turn > 50 then exit
	)
	format "clean id:%\n" j
	j
)
-- returnCleanId()

fn cleaneffectsChannel =
(
	for m in scenematerials do
	(
		if iskindof m VRaySky then(format "ignore:%\n" m)
		else
		(	
			 m.effectsChannel = 0
			format "m: % id: %\n" m m.effectsChannel
		)
	)
)
-- cleaneffectsChannel()

fn cleanVrayEffectsChannel =
(
	for m in scenematerials do
	(
		if iskindof m VRayMtl then
		(
			m.effect_id = 0
			format "ignore:%\n" m
		)
		else()
	)
)


-- try(destroydialog matIdManagerRLT)catch()
/*
rollout matIdManagerRLT "material ids manager" width: 200
(
	local matAr
	local multiMatAr
	local matArToDisp
	local multiMatArToDisp
	local matListSel = #()
	
	
	group "selection:"
	(
		radiobuttons typeSelBT "selection: " labels:#("scene", "visible", "selection") default: 2 enabled: false
		button refreshBT "refresh"
	)
	
	group "multimaterials:"
	(
		listbox multiMatLB "multi material list" height: 5 --enabled: true
		button editMultiMatBT "edit multi mat" enabled: false
		button selectMultiMatObjBT "select object" enabled: false
	)
	
	group "vray materials:"
	(
		multilistbox materialListMLB "vray material list:" --height: 30
		editText matCountET "material count" readonly: true
		button editMatBT "edit mat" -- enabled: false
		button selectMatObjBT "select object" -- enabled: false
		
		spinner matIdSP "material id" type: #integer
		button addFreeIdBT "add free id to sel" 
		button randomIdBT "random ids on sel" --enabled: false
	)
	
	fn refreshUI =
	(
		-- list de materiaux			
		multiMatArToDisp = multiMatAr
		qsort  multiMatArToDisp sortbyname
		multiMatLB.items = for m in multiMatArToDisp collect m.name
			
		matArToDisp = matAr
		qsort  matAr sortbyname
		matNameArToDisp = #()
		for m in matArToDisp do
		(
			if m.effect_id == 0 then
			(
				append matNameArToDisp (m.name)
			)
			else
			(
				append matNameArToDisp (m.name + "  [" +  (m.effect_id as string) + "]")
			)
		)			
		materialListMLB.items =matNameArToDisp
		
		-- material count
		matCountET.text = matAr.count as string
-- 		
		if matListSel.count > 0 then
		(
			local idAr = #()
			for m in matListSel do appendifunique idAr m.effect_id
			if idAr.count == 1 then matIdSP.value = idAr[1] else matIdSP.value = 0
		)
	)		
	
	on refreshBT pressed do
	(
		matAr = collectVisibleMat()
		multiMatAr = collectVisibleMultiMat()
		multiMatLB.selection = 0
		refreshUI()
	)
	
	on matIdManagerRLT open do
	(
		
		matAr = collectVisibleMat()
		multiMatAr = collectVisibleMultiMat()
		refreshUI1()
	)
	
	on multiMatLB selected arg do
	(
		matAr = getclassinstances vrayMtl target: multiMatAr[arg]
		refreshUI()
	)
	
	on materialListMLB selectionEnd do
	(
-- 		format "selection:% \n" materialListMLB.selection
		matListSel = for i in materialListMLB.selection collect matAr[i] 
-- 		format "matListSel:%\n" matListSel
		refreshUI()
	)
	
	on editMatBT pressed do
	(
-- 		print "youhou2"
		for i = 1 to matListSel.count do
		(
			meditMaterials[i] = matListSel[i]
		)
	)	
	
	on selectMatObjBT pressed do
	(
		local setToSel = #()
		
-- 		format "youhou\n"
		if matListSel.count > 0 then
		(
			for m in matListSel do
			(
				format "mat:%\n" m.name
				local deps = refs.dependents m
				for d in deps do
				(
-- 					format "d: % classof: % isvalinode: %\n" d (classof d) (isvalidnode d)
					if isvalidnode d then
					(
-- 						format "d: % isvalinode: % \n" d  (isvalidnode d)
						append setToSel d
					)
				)
			)
		)
		select setToSel
	)
	
	on matIdSP changed val do
	(
		if matListSel.count > 0 then
		(
			for m in matListSel do
			(
				m.override_effect_id = on
				m.effect_id = val
			)
		)
		refreshUI()
	)
	
	on addFreeIdBT pressed do
	(
		local newId = returnCleanId()
		for m in matListSel do
		(
			m.effect_id = newId
		)
		
		refreshUI()
	)
	
	on randomIdBT pressed do
	(
		-- assign de maniere incrementale des id au materiaux en evitant d'appliquer plusieurs fois des id et en evitant de changer les id deja affecter
		-- collecter les ids de materiaux deja affecter dans la scene
		local forceID = true
		
		for m in matListSel do
		(
			-- si une id est deja affect� passer
			if m.effect_id != 0 and not forceID then continue

			m.override_effect_id = on
			m.effect_id = (returnCleanId())
			format "id: % assign: %\n" i m.name
		)
		refreshUI()
	)
)
-- createdialog matIdManagerRLT
*/

fn collectMatByIds id =
(
	local sceneMat = getclassinstances vrayMtl target: scenematerials
	local sameIdMatAr = for m in sceneMat where m.effect_id == id collect m
	sameIdMatAr
)
-- collectMatIDs()

try(closeRolloutFloater matIdExplorerRF)catch()
matIdExplorerRF = newRolloutFloater "Materials id explorer" 250 500
-- try(destroydialog matIdExplorerRLT)catch()
rollout matIdExplorerRLT "materials id explorer"
(
	local RFPos = [0,0]
	local RFSIze = [350,800]
	
	local params = #("RFPos","RFSIze")
	
	local idSel = #()
	local idsAr = #()
	local sameIdMatAr = #()
	local matListSel = #()
	local sceneMat
		
	local matAr
	local multiMatAr
	local matArToDisp
	local multiMatArToDisp
	local matListSel = #()
	
	group "tools"
	(
		button cleanIdMatBT "clean all id mat"
-- 		button matManagerBT "materials id manager"
	)
	
	group "selection:"
	(
		radiobuttons typeSelBT "selection: " labels:#("scene", "visible", "selection") default: 2 enabled: false
		button refreshBT "refresh"
	)
	/*
	group "multimaterials:"
	(
		listbox multiMatLB "multi material list" height: 5 --enabled: true
		button editMultiMatBT "edit multi mat" enabled: false
		button selectMultiMatObjBT "select object" enabled: false
	)
	*/
	group "vray materials:"
	(
		multilistbox materialListMLB "vray material list:" --height: 30
		editText matCountET "material count" readonly: true
		button editMatBT "edit mat" -- enabled: false
		button selectMatObjBT "select object" -- enabled: false
		
		spinner matIdSP "material id" type: #integer
		button addFreeIdBT "add free id to sel" 
		button randomIdBT "random ids on sel" --enabled: false
	)
		
	-- UI
	/*
	group "material ids:"
	(
		multilistbox matIdLB "materials ids:"
		button refreshIdsBT "refresh"
		multilistbox matMLB "scene materials:"
		spinner reassignSP "reassign id:" type: #integer
		button editMat2BT "edit material" across: 2 --enabled: false
		button selObjBT "select object"  -- enabled: false
	)
	*/
	group "create render elements:"
	(
		button matIdEltBT "VRayMtlID" --across: 3
		button objSelEltBT "VRayObjectSelect selected" tooltip: "Cr�ation d'une passe 'vrayObjectSelect' pour chaque id de material selectionn�."
		button multiEltBT "all MultiMatteElement"  tooltip: "cr�ation de toutes les passes MultiElement"
		button multiElt2BT "all MultiMatteElement 2"  tooltip: "cr�ation de toutes les passes MultiElement"
	)
	
	/*
	fn refreshUI =
	(
		matIdLB.items = for id in idsAr collect (id as string)
		
-- 		if sameIdMatAr.count > 0  then matMLB.items = for m in sameIdMatAr collect m.name
			
		matNameArToDisp = #()
		for m in sameIdMatAr do
		(
			if m.effect_id == 0 then
			(
				append matNameArToDisp (m.name)
			)
			else
			(
				append matNameArToDisp (m.name + "  [" +  (m.effect_id as string) + "]")
			)
		)			
		matMLB.items =matNameArToDisp
			
		if idSel.count > 0 then  reassignSP.value = idSel[1] else  reassignSP.value = 0
	)
	*/
	
	
-- functions UI dependant
	fn refreshUI1 =
	(
		-- collecte de de la liste de multimaterial
		/*
		multiMatArToDisp = multiMatAr
		qsort  multiMatArToDisp sortbyname
		multiMatLB.items = for m in multiMatArToDisp collect m.name
		*/
		
		-- collecte de de la liste de material
		matArToDisp = matAr
		qsort  matAr sortbyname
		matNameArToDisp = #()
		for m in matArToDisp do
		(
			if m.effect_id == 0 then
			(
				append matNameArToDisp (m.name)
			)
			else
			(
				append matNameArToDisp (m.name + "  [" +  (m.effect_id as string) + "]")
			)
		)			
		materialListMLB.items =matNameArToDisp
		
		-- material count
		matCountET.text = matAr.count as string
-- 		
		if matListSel.count > 0 then
		(
			local idAr = #()
			for m in matListSel do appendifunique idAr m.effect_id
			if idAr.count == 1 then matIdSP.value = idAr[1] else matIdSP.value = 0
		)
	)		
		
	-- Actions
	on matIdExplorerRLT open do
	(
		loadRolloutParams matIdExplorerRLT params
		try(matIdExplorerRF.pos =  RFPos)catch()
		try(matIdExplorerRF.size =  RFSIze)catch()
		
		idsAr = collectMatIDs()
		
		matAr = collectVisibleMat()
		multiMatAr = collectVisibleMultiMat()

-- 		refreshUI()
		refreshUI1()
	)
	
	on matIdExplorerRLT close do
	(
		RFPos = matIdExplorerRF.pos
		RFSIze = matIdExplorerRF.size
		
		writeRolloutParams matIdExplorerRLT params
	)
	
	on cleanIdMatBT pressed do
	(
		cleaneffectsChannel()
		cleanVrayEffectsChannel()
	)
	
	
	on refreshBT pressed do
	(
		matAr = collectVisibleMat()
		multiMatAr = collectVisibleMultiMat()
		multiMatLB.selection = 0
		refreshUI1()
	)
	
	on matIdManagerRLT open do
	(
		matAr = collectVisibleMat()
		multiMatAr = collectVisibleMultiMat()
		refreshUI1()
	)
	
	on multiMatLB selected arg do
	(
		matAr = getclassinstances vrayMtl target: multiMatAr[arg]
		refreshUI1()
	)
	
	on materialListMLB selectionEnd do
	(
-- 		format "selection:% \n" materialListMLB.selection
		matListSel = for i in materialListMLB.selection collect matAr[i] 
-- 		format "matListSel:%\n" matListSel
		refreshUI1()
	)
	
	on editMatBT pressed do
	(
-- 		print "youhou2"
		for i = 1 to matListSel.count do
		(
			meditMaterials[i] = matListSel[i]
		)
	)	
	
	on selectMatObjBT pressed do
	(
		local setToSel = #()
		
-- 		format "youhou\n"
		if matListSel.count > 0 then
		(
			for m in matListSel do
			(
				format "mat:%\n" m.name
				local deps = refs.dependents m
				for d in deps do
				(
-- 					format "d: % classof: % isvalinode: %\n" d (classof d) (isvalidnode d)
					if isvalidnode d then
					(
-- 						format "d: % isvalinode: % \n" d  (isvalidnode d)
						append setToSel d
					)
				)
			)
		)
		select setToSel
	)
	
	on matIdSP changed val do
	(
		if matListSel.count > 0 then
		(
			for m in matListSel do
			(
				m.override_effect_id = on
				m.effect_id = val
			)
		)
		refreshUI1()
	)
	
	on addFreeIdBT pressed do
	(
		local newId = returnCleanId()
		for m in matListSel do
		(
			m.effect_id = newId
		)
		
		refreshUI1()
	)
	
	on randomIdBT pressed do
	(
		-- assign de maniere incrementale des id au materiaux en evitant d'appliquer plusieurs fois des id et en evitant de changer les id deja affecter
		-- collecter les ids de materiaux deja affecter dans la scene
		local forceID = true
		
		for m in matListSel do
		(
			-- si une id est deja affect� passer
			if m.effect_id != 0 and not forceID then continue

			m.override_effect_id = on
			m.effect_id = (returnCleanId())
			format "id: % assign: %\n" i m.name
		)
		refreshUI1()
	)
	--############################ stop
	/*
	on matManagerBT pressed do
	(
		global matIdManagerRF
		try(closeRolloutFloater matIdManagerRF)catch()
		matIdManagerRF = newRolloutFloater "Materials id manager" 250 500
		addrollout matIdManagerRLT matIdManagerRF
	)
	
	on refreshIdsBT pressed do
	(
		idsAr = collectMatIDs()
		refreshUI()
	)
		
	on matIdLB selectionEnd do
	(

		local idSelAr = matIdLB.selection as array
		format "idSel: %\n" idSelAr
		idSel = for id in idSelAr collect (matIdLB.items[id] as integer)
		
		format "idSel: %\n" idSel
		sceneMat = getclassinstances vrayMtl target: scenematerials
		sameIdMatAr = #()
		
		for m in sceneMat do
		(
			local res = finditem idSel m.effect_id
			if res > 0 then append sameIdMatAr m
-- 			where m.effect_id == idSel collect m
		)
		qsort sameIdMatAr sortByName
		format "sameIdMatAr: %\n" sameIdMatAr
		refreshUI()
	)
	*/
	on matMLB selectionEnd do
	(
		matListSel = for i in matMLB.selection collect sameIdMatAr[i] 
-- 		matIdLB.selected = 0
	)
	
	on editMat2BT pressed do
	(
		for i = 1 to matListSel.count do
		(
			meditMaterials[i] = matListSel[i]
		)
	)
	
	on selObjBT pressed do
	(
		local setToSel = #()
		
-- 		format "youhou\n"
		if matListSel.count > 0 then
		(
			for m in matListSel do
			(
				format "mat:%\n" m.name
				local deps = refs.dependents m
				for d in deps do
				(
-- 					format "d: % classof: % isvalinode: %\n" d (classof d) (isvalidnode d)
					if isvalidnode d then
					(
-- 						format "d: % isvalinode: % \n" d  (isvalidnode d)
						append setToSel d
					)
				)
			)
		)
		select setToSel
	)
	
	on reassignSP entered  do
	(
		-- reassignation de l'id de mat
		format "val:%\n" reassignSP.value
		if matListSel.count > 0 then
		(
			for m in matListSel do
			(
				m.override_effect_id = on
				m.effect_id = reassignSP.value
			)
		)
		
		-- recollecte apr�s assignation
		idsAr = collectMatIDs()
		format "idsAr:%\n" idsAr

		idSel = #(reassignSP.value)
-- 		idSel = matIdLB.selected as integer
		format "idSel: % %\n" idSel (classof idSel)
-- 		local sceneMat = getclassinstances vrayMtl target: scenematerials
		sameIdMatAr = for m in sceneMat where m.effect_id == idSel collect m
		format "sameIdMatAr: %\n" sameIdMatAr
		
		refreshUI()
-- 		format "idSel: % %\n" idSel (classof idSel)
-- 		print "�a passe par l�?"
		matIdLB.selection= idSel
		refreshUI()
	)
	
	on matIdEltBT pressed do
	(
		rem =MaxOps.GetCurRenderElementMgr ()
		-- suppression de la passe material id
		eltsNum = rem.NumRenderElements()
		for i = (eltsNum - 1) to 0 by -1 do
		(
			elt = rem.GetRenderElement i
			if iskindof elt VRayMtlID then rem.RemoveRenderElement elt
		)
		-- ajout de la passe material id
		vrMtlID = VRayMtlID filterOn: true output_type: 1
		rem.AddRenderElement vrMtlID	
	)
	
	on objSelEltBT pressed do
	(
		rem =MaxOps.GetCurRenderElementMgr ()
		
		-- suppression de la passe material id
		eltsNum = rem.NumRenderElements()
		for i = (eltsNum - 1) to 0 by -1 do
		(
			elt = rem.GetRenderElement i
			if iskindof elt VRayObjectSelect then rem.RemoveRenderElement elt
		)
		
		-- collecte des vray mat
		sceneMat = getclassinstances vrayMtl target: scenematerials
			
		-- creation des passes
		format "idsAr: %\n" idsAr
		format "idSel: %\n" idSel
		
-- 		for id in idsAr do
		for id in idSel do
		(
			-- creation du nom
			sameIdMatAr = for m in sceneMat where m.effect_id == id collect m
			superName = ""
			for m in sameIdMatAr do 
			(
				format "%\n" (superName += ("/" + m.name))
				superName = substring superName 1 40
			)
			
			if id > 0 then
			(
-- 				format "channel id: % mat name: %\n" m.effect_id m.name
				vrObjSelElt = VRayObjectSelect elementName: ("id_" + (id as string) + superName) mode: 1 object_id: id  use_material_id: true consider_for_antialiasing: true
				rem.AddRenderElement vrObjSelElt
			)
		)
	)
	
	on multiEltBT pressed do
	(
		rem =MaxOps.GetCurRenderElementMgr ()
		
		-- suppression des passes multimat
		eltsNum = rem.NumRenderElements()
		for i = (eltsNum - 1) to 0 by -1 do
		(
			elt = rem.GetRenderElement i
			if iskindof elt multimatteElement then rem.RemoveRenderElement elt
		)
		
		-- collecte des vray mat
		sceneMat = getclassinstances vrayMtl target: scenematerials
			
		-- creation des passes
		for i=1 to  idsAr.count by 3 do
		(
			format "idsAr[i]: %\n" idsAr[i]
			-- creation du nom
			sameIdMatAr = #()
			for m in sceneMat do
			(
				if m.effect_id == 0 then continue
				if m.effect_id == idsAr[i] then append sameIdMatAr m
				if m.effect_id == idsAr[i+1] then append sameIdMatAr m
				if m.effect_id == idsAr[i+2] then append sameIdMatAr m
			)
			
			-- 
			superName = ""
			for m in sameIdMatAr do 
			(
				superName += ("[" +(m.effect_id as string)+"]" + m.name + " ")
				format "%\n" superName
-- 				superName = substring superName 1 60
			)
			
			-- 
			local R_gbufID, G_gbufID, B_gbufID
			
			-- 
			if idsAr[i] != undefined then R_gbufID = idsAr[i] else R_gbufID = 0
			if idsAr[i+1] != undefined then G_gbufID = idsAr[i+1] else G_gbufID = 0
			if idsAr[i+2] != undefined then B_gbufID = idsAr[i+2] else B_gbufID = 0
			
-- 			if idsAr[i] > 0 then
			(
				format "%\n" superName
				local matSel = multimatteElement elementName: (superName) R_gbufID: R_gbufID G_gbufID: G_gbufID B_gbufID: B_gbufID MatID: true
				rem.AddRenderElement matSel
			)
		)
	)
	
	on multiElt2BT pressed do
	(
		rem =MaxOps.GetCurRenderElementMgr ()
		
		-- suppression des passes multimat
		eltsNum = rem.NumRenderElements()
		for i = (eltsNum - 1) to 0 by -1 do
		(
			elt = rem.GetRenderElement i
			if iskindof elt multimatteElement then rem.RemoveRenderElement elt
		)
		
		-- collecte des vray mat
		sceneMat = getclassinstances vrayMtl target: scenematerials
			
		-- creation des passes
		for i=1 to  idsAr.count do
		(
			format "idsAr[i]: %\n" idsAr[i]
			-- creation du nom
			sameIdMatAr = #()
			for m in sceneMat do
			(
				if m.effect_id == 0 then continue
				if m.effect_id == idsAr[i] then append sameIdMatAr m
-- 				if m.effect_id == idsAr[i+1] then append sameIdMatAr m
-- 				if m.effect_id == idsAr[i+2] then append sameIdMatAr m
			)
			
			-- 
			superName = ""
			for m in sameIdMatAr do 
			(
				superName += ("[" +(m.effect_id as string)+"]" + m.name + " ")
				format "%\n" superName
-- 				superName = substring superName 1 60
			)
			
			-- 
			local R_gbufID, G_gbufID, B_gbufID
			
			-- 
			if idsAr[i] != undefined then 
			(
				R_gbufID = idsAr[i] -- else R_gbufID = 0
				G_gbufID = idsAr[i] -- else G_gbufID = 0
				B_gbufID = idsAr[i] -- else B_gbufID = 0
			)
			else
			(
				R_gbufID = 0
				G_gbufID = 0
				B_gbufID = 0
			)
-- 			if idsAr[i+1] != undefined then G_gbufID = idsAr[i+1] else G_gbufID = 0
-- 			if idsAr[i+2] != undefined then B_gbufID = idsAr[i+2] else B_gbufID = 0
			
-- 			if idsAr[i] > 0 then
			(
				format "%\n" superName
				local matSel = multimatteElement elementName: (superName) R_gbufID: R_gbufID G_gbufID: G_gbufID B_gbufID: B_gbufID MatID: true
				rem.AddRenderElement matSel
			)
		)
	)
)
-- createdialog matIdExplorerRLT

addrollout  matIdExplorerRLT matIdExplorerRF

