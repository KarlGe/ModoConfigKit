#python

# =============================================================================
# Script: funk_ItemIsolateToggle.py v0.02 (2013-11-14)
# Author: funk
# 
# Toggles hide.unsel/unhide commands to isolate selected items, with option
# to keep backdrop items visible.
#
# Usage: funk_ItemIsolateToggle.py <backdrop>
# =============================================================================

import lx

# =============================================================================
# Functions
# =============================================================================

# Return selection mode

def get_selection_mode():
    sel_modes = ('polygon', 'edge', 'vertex', 'ptag', 'item', 'pivot', 'center')
    for sel_mode in sel_modes:
        if lx.eval('select.typeFrom %s;polygon;edge;vertex;ptag;item;pivot;center ?' %sel_mode):
            return sel_mode

# Toggle item isolation

def toggle_isolation():
    sel_mode = get_selection_mode()
    lx.eval('select.typeFrom item')
    if lx.eval('query scriptsysservice userValue.isDefined ? funkItemIsolate') == 0:
        lx.eval('user.defNew funkItemIsolate integer temporary')
        lx.eval('user.value funkItemIsolate 0')
        hide_state = 0
    else :
        hide_state = lx.eval('user.value funkItemIsolate ?')

    if (hide_state == 0):
        if keep_backdrop:
            # add backdrop items to the selection
            lx.eval('select.itemType backdrop mode:add')
        lx.eval('hide.unsel')
        if keep_backdrop:
            # remove backdrop items to the selection
            lx.eval('select.itemType backdrop mode:remove')
        lx.eval('user.value funkItemIsolate 1')
    else:
        lx.eval('unhide')
        lx.eval('user.value funkItemIsolate 0')
    lx.eval('select.type %s' %sel_mode)
            
# =============================================================================
# Script Body
# =============================================================================

args = lx.args()
keep_backdrop = 0

if (args and args[0] == 'backdrop'):
    keep_backdrop = 1

try:
    toggle_isolation()
except:
    lx.out('Exception "%s" on line: %d' % (sys.exc_value, sys.exc_traceback.tb_lineno))
    sys.exit()
