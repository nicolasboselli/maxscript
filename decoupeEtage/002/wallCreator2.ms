-- activeGrid.transform

/*
maj: 
	- ajouter une fonction cap, d�riv� du sel creator
	- auto active du layer batiment
	- rajouter des spline sur une spline deja commencer
	- activer l'option start new spline � la vol�e
	- cr�er une fonction pour attacher les spline ensembles en ignorant le sweep
		s1 = $s1
		s2 = $s2
		addAndWeld s1 s2 0
		updateshape s1
		
	- editer les options de sweep
	- faire la fonction d'impact des splines
	
rebuild:
	- supprimer la var backCell en ajoutant une condition if newSpline then newcell = undefined
*/


try(destroydialog newWallCreatorRLT)catch()
rollout newWallCreatorRLT "new wall Creator"
(
	global newCell
	global backCell
	local newWallState = true
	local newSpline
	local spNum = 1
	local wallmat
	
	checkbox newSplineCB "start new spline" checked: false
	checkbox autoLayerCB "auto active layer" checked: true
	edittext currentLayerET "active layer"
	
	
	checkbutton newCellCB "new wall"
	
	button attachSplineBT "attach spline"
	
	materialbutton wallMattMT "wall material"
	edittext matNamET "material:"
	
	
	
	tool splineTool
	(
		local lastPos
		local lastgridpoint
		local firstGridPoint
		local restart = false
-- 		local spNum = 1
		
		on start do
		(
			format "start splineTool\n"
		)
		
		on freeMove do
		(
-- 			print "Free Moving"
			restart = false
		)
			
		on mousePoint clickno do
		(
			restart = true
			local closed = false
			
			format "restart: %\n" restart
			
			if clickno == 1 then
			(
-- 				format "mousePoint init: %\n" clickno
				max modify mode
				
				format "backCell: % newCell: %  newSpline: %\n" backCell newCell newSpline
				if not isvalidnode backCell or newSpline then 
				(
					
					newCell= SplineShape name: (uniquename "wall_") transform: (getCPTM())
					spNum = 1
					format "create new spline:%\n" newCell
				)
				else 
				(
					newCell = backCell
					spNum += 1
				)
					
				newCell.vertexTicks = on

-- 				format "mousePoint delete: %\n" clickno
				addNewSpline newCell
				firstGridPoint = gridPoint
				addKnot newCell spNum #corner #curve (gw.mapCPToWorld firstGridPoint)
				
				lastgridpoint = gridPoint
				lastPos = gw.mapCPToWorld lastgridpoint
				addKnot newCell spNum #corner #curve lastPos
				
				updateshape newCell	
					
				select newCell
				modPanel.setCurrentObject newCell.baseobject 
				showEndResult = false
					
				format "showEndResult: %\n" showEndResult
				format "start new spline: %\n" newCell.name
				format "mousePoint init: %\n" clickno
					
			)
			else if clickno == 2 then
			(	
			)
			else
			(
				lastgridpoint = gridPoint

				if (distance firstGridPoint lastGridPoint) < 10 then 
				(
					format "close spline\n"
					close  newCell 1
					knotToDel = numKnots newCell 1
					deleteknot newCell spNum knotToDel
					closed = true
					
				)
				else
				(
					lastPos = gw.mapCPToWorld lastgridpoint
					addKnot newCell spNum #corner #curve lastPos
				)

				format "mousePoint: %\n" clickno
			)
			updateshape newCell
			
			if closed then #stop
		)
		
		on mouseMove clickno do
		(
			local knotCount = numKnots newCell spNum
			local newGridPoint = gridPoint
			
			-- contrainte en x ou y
			if shiftKey then  
			(
				local testVec =  normalize(newGridPoint - lastGridPoint)
				if testVec.x^2 > testVec.y^2 then newGridPoint.y = lastGridPoint.y		
				else	newGridPoint.x = lastGridPoint.x	
			)
				
			local curPos = gw.mapCPToWorld newGridPoint
			
			setKnotPoint newCell spNum knotCount curPos
			updateshape newCell	
		)
		
		on mouseAbort clickno do
		(
			format "rbutton: %\n" rbutton 
			format "mouseAbort: %\n" clickno
			
			if isvalidnode newCell then 
			(
				knotToDel = numKnots newCell spNum
				if KnotToDel > 2 then
				(
					deleteknot newCell spNum knotToDel
					updateshape newCell
				)
				else
				(
-- 					delete newCell
				)
			)				
			
		)			
		
		on stop do
		(
			format "stop tool\n" 
-- 			if isvalidnode newCell then updateshape newCell
			format "newCell:%\n" newcell
			if isvalidnode newCell then 
			(					
				updateshape newCell
				showEndResult = true
				newCell.vertexTicks = off
				newCell.pivot = newCell.center
				newCell.xray = on
				newCell.wirecolor = color 135 6 6
				
				try
				(
					addmodifier newCell (Sweep CurrentBuiltInShape: 2 PivotAlignment:3 SmoothPath: false)
					newCell.sweep[#Bar_Section].length = 250 
					newCell.sweep[#Bar_Section].width = 20
				)catch(format "d�ja sweeper\n")
			)
			
			backCell = newCell
			newCell = undefined
			format "restart: % backCell: % newCell: %  newSpline: % wallmat:%\n" restart backCell newCell newSpline wallmat
			
			-- application du material
			if isvalidnode backCell then 
			(
				format "bakCell:%\n" bakCell
				backCell.material = wallmat
			)
			
			if restart then 
			(
				format "restart tool\n"
				starttool splineTool

			)
		)
	)
	
	on newWallCreatorRLT open do
	(
		wallmat = scenematerials["beton_blanc"]
		if wallmat != undefined then matNamET.text = wallmat.name
	)
	
	on newOneBT pressed do
	(
		 newSpline = true
	)
	
	on newCellCB changed state do
	(
		-- active le layer wall
-- 		/*
-- 		valirep
		format "validrep: % %\n" validrep (isvalidnode valirep)
		
		
-- 		/*
		if isvalidnode validrep and autoLayerCB.state then 
		(
			oneLayer = LayerManager.getLayerFromName validRep.name
			if 	autoLayerCB.state and oneLayer != undefined then oneLayer.current = true else()
-- 			format "change layer:%\n" validrep
-- 			validrep.layer.current = true
			unHideLayerHierarchy  oneLayer
		)
-- 		*/
		currentLayerET.text = LayerManager.current.name
-- 		*/
		format "check2\n"
		if state then
		(
			local continueTool = true
			while continueTool == true do
			(
				newSpline = newSplineCB.state
				continueTool = starttool splineTool
			)
			newCellCB.state = false
		)
		else
		(
			stoptool splineTool
		)
	)
-- 	classof $.baseobject
	on attachSplineBT pressed do
	(
		local sel = selection as array
		for i = 2 to (sel.count) do
		(
			if iskindof sel[i].baseobject line or iskindof sel[i].baseobject SplineShape then
			(
				addAndWeld sel[1] sel[i]  0
				updateshape sel[1]
			)
		)
	)
	
	on wallMattMT picked mat do
	(
		wallmat = mat
		format "mat:%\n" wallmat.name
		if wallmat != undefined then matNamET.text = wallmat.name
	)
	
-- 	on testBT pressed do
-- 	(
-- 		format "mat:%\n" wallMattMT.material
-- 	)
)
createdialog newWallCreatorRLT

