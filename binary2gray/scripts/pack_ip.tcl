create_project rtl_kernel ./rtl_kernel -part xcu200-fsgd2104-2-e
set_property board_part xilinx.com:au200:part0:1.3 [current_project]
add_files -scan_for_includes {./src/IP/B2G.v ./src/IP/graycode.sv ./src/IP/graycode_control_s_axi.sv}
import_files {./src/IP/B2G.v ./src/IP/graycode.sv ./src/IP/graycode_control_s_axi.sv}
update_compile_order -fileset sources_1
ipx::package_project -root_dir ./rtl_kernel/rtl_kernel.srcs/sources_1/imports/IP -vendor user.org -library user -taxonomy /UserIP
set_property vendor holyuming [ipx::current_core]
set_property ipi_drc {ignore_freq_hz false} [ipx::current_core]
set_property sdx_kernel true [ipx::current_core]
set_property sdx_kernel_type rtl [ipx::current_core]
set_property vitis_drc {ctrl_protocol ap_ctrl_hs} [ipx::current_core]
set_property vitis_drc {ctrl_protocol user_managed} [ipx::current_core]
set_property ipi_drc {ignore_freq_hz true} [ipx::current_core]
ipx::associate_bus_interfaces -busif m00_axi -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk [ipx::current_core]
ipx::add_register User_Control [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register Bin_Code_addr [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register Gry_Code_addr [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
set_property address_offset 0x010 [ipx::get_registers User_Control -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset 0x01c [ipx::get_registers Bin_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset 0x028 [ipx::get_registers Gry_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size 32 [ipx::get_registers User_Control -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size 64 [ipx::get_registers Bin_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size 64 [ipx::get_registers Gry_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property description {User Control} [ipx::get_registers User_Control -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property description {Pointer argument} [ipx::get_registers Bin_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property description {Pointer argument} [ipx::get_registers Gry_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers Bin_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property value m00_axi [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers Bin_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]]
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers Gry_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property value m00_axi [ipx::get_register_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_registers Gry_Code_addr -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]]
ipx::add_bus_parameter FREQ_TOLERANCE_HZ [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]
set_property value -1 [ipx::get_bus_parameters FREQ_TOLERANCE_HZ -of_objects [ipx::get_bus_interfaces ap_clk -of_objects [ipx::current_core]]]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity -kernel [ipx::current_core]
ipx::save_core [ipx::current_core]

# package xo
package_xo  -xo_path ./user-xo/B2G.xo -kernel_name B2G -ip_directory ./rtl_kernel/rtl_kernel.srcs/sources_1/imports/IP -ctrl_protocol user_managed


set_property  ip_repo_paths  ./rtl_kernel/rtl_kernel.srcs/sources_1/imports/IP [current_project]
update_ip_catalog
ipx::check_integrity -quiet -kernel [ipx::current_core]
ipx::archive_core ./rtl_kernel/rtl_kernel.srcs/sources_1/imports/IP/holyuming_user_B2G_1.0.zip [ipx::current_core]
exit