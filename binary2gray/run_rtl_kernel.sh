#!/bin/sh


# this script should be run where the makefile resides 

############################################################
# Hardware emulation run 
############################################################
make run TARGET=hw_emu HOST=user

# # Line by line execution
# # package rtl kernel via vivado
# mkdir -p ./user-xo
# vivado -mode batch -source scripts/gen_xo.tcl -tclargs ./user-xo/B2G.xo B2G hw_emu xilinx_u200_gen3x16_xdma_2_202110_1

# # Link rtl kernel via vitis
# mkdir -p ./user-xclbin
# v++ -t hw_emu --platform xilinx_u200_gen3x16_xdma_2_202110_1 --save-temps  -l -o ./user-xclbin/B2G.hw_emu.xclbin ./user-xo/B2G.xo
# cp -rf ./user-xclbin/B2G.hw_emu.xclbin ./B2G.xclbin
# emconfigutil --platform xilinx_u200_gen3x16_xdma_2_202110_1 --od ./user-xclbin/
# cp -rf ./user-xclbin//emconfig.json .

# # Compile host program
# g++ -g -I./ -I/opt/xilinx/xrt/include -I/tools/Xilinx/Vivado/2022.1/include -Wall -O0 -g -std=c++17 -fmessage-length=0 ./src/host/user-host.cpp -o 'host' -L/opt/xilinx/xrt/lib -lxrt_coreutil -pthread -lrt -lstdc++

# # Run application
# XCL_EMULATION_MODE=hw_emu ./host ./B2G.xclbin xilinx_u200_gen3x16_xdma_2_202110_1




#############################################################
# Hardware run 
##############################################################
# make run TARGET=hw HOST=user

# # Line by line execution
# # package rtl kernel via vivado
# mkdir -p ./user-xo
# vivado -mode batch -source scripts/gen_xo.tcl -tclargs ./user-xo/B2G.xo B2G hw xilinx_u200_gen3x16_xdma_2_202110_1

# # Link rtl kernel via vitis
# mkdir -p ./user-xclbin
# v++ -t hw_emu --platform xilinx_u200_gen3x16_xdma_2_202110_1 --save-temps  -l -o ./user-xclbin/B2G.hw_emu.xclbin ./user-xo/B2G.xo
# cp -rf ./user-xclbin/B2G.hw_emu.xclbin ./B2G.xclbin
# emconfigutil --platform xilinx_u200_gen3x16_xdma_2_202110_1 --od ./user-xclbin/
# cp -rf ./user-xclbin//emconfig.json .

# # Compile host program
# g++ -g -I./ -I/opt/xilinx/xrt/include -I/tools/Xilinx/Vivado/2022.1/include -Wall -O0 -g -std=c++17 -fmessage-length=0 ./src/host/user-host.cpp -o 'host' -L/opt/xilinx/xrt/lib -lxrt_coreutil -pthread -lrt -lstdc++

# # Run application
# ./host ./B2G.xclbin xilinx_u200_gen3x16_xdma_2_202110_1