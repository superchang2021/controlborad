# Tcl script created by Tang Dynasty 5.6.2 71036
open_project {demo_1st.al}
import_device eagle_20.db -package EG4X20BG256
# Reset all syn/phy runs by default.
reset_runs { syn_1 }
# Launch all runs by default.
# Note that runs need to be reset first before launch.
launch_runs { syn_1 phy_1 } -jobs 2
# Waiting runs to finish one by one.
# Note that all launched runs before need to call this tcl command
wait_run syn_1 -quiet
wait_run phy_1 -quiet
