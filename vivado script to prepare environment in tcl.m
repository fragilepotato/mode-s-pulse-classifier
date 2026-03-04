# 1. Define the base path
set repo_dir "A:/hdl-2023_R2_p1"

# 2. Exhaustive list of required libraries for fmcomms2_zed
# (Video/Audio IPs are included solely to satisfy the ADI base script)
set required_libs {
    "util_cdc"
    "util_axis_fifo"
    "axi_dmac"
    "axi_clkgen"
    "axi_hdmi_tx"
    "axi_spdif_tx"
    "axi_i2s_adi"
    "axi_sysid"
    "sysid_rom"
    "util_i2c_mixer"
    "util_wfifo"
    "util_rfifo"
    "util_pack/util_cpack2"
    "util_pack/util_upack2"
    "axi_ad9361"
    "xilinx/util_clkdiv" 
}

# 3. Build each library
foreach lib $required_libs {
    puts "========================================="
    puts "Building $lib..."
    puts "========================================="
    cd $repo_dir/library/$lib
    
    # Extract the base name of the IP (e.g., util_cpack2 from util_pack/util_cpack2)
    # Also handles the xilinx/util_clkdiv subfolder cleanly
    set ip_name [lindex [split $lib "/"] end]
    
    # Source the ADI IP packaging script
    source ./$ip_name\_ip.tcl
}

# 4. Build the actual Zedboard project
puts "========================================="
puts "Libraries built. Building FMCOMMS2 ZedBoard Project..."
puts "========================================="
cd $repo_dir/projects/fmcomms2/zed
source ./system_project.tcl