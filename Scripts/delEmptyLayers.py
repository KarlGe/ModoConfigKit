#python

"""
A python script for modo 701 that will delete any empty mesh item layers.

Original script from Philip Lawson

Modified by Bjoern Siegert aka nicelife:
Works now with hidden mesh items as well

"""

#Variables
deleteMeshList = []

# First we must select the scene and then all the mesh layers in our scene.
lx.eval('select.drop item')
lx.eval('select.layerTree all:1')
meshItemList = lx.evalN('query sceneservice selection ? mesh') # mesh item layers

# For each mesh item layer, we check to see if there are any verts in the layer...
for meshItem in meshItemList:
    lx.eval('select.drop item')
    lx.eval('select.item %s' %meshItem)
    
    # Check if the selected item is visible if not set it visible
    if lx.eval("query layerservice layer.visible ? %s" %meshItem) != "main":
        lx.eval("layer.setVisibility %s 1" %meshItem)
        madeVisible = True
    else:
        madeVisible = False

    lx.eval('query layerservice layer.index ? selected') # scene
    numOfVerts = lx.eval('query layerservice vert.N ? all')
    lx.out(meshItem, " numOfVerts: " ,numOfVerts)
    
    # If there are no verts, we delete the mesh item layer.
    if numOfVerts == 0:
        deleteMeshList.append(meshItem)
        lx.eval('!item.delete')
    
    # If restore the visibility if the mesh item is not deleted
    if madeVisible == True and meshItem not in deleteMeshList:
        lx.eval("layer.setVisibility %s 0" %meshItem)

# Drop layer selection
lx.eval('select.drop item')