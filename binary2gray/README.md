# Vitis rtl kernel project: Binary code to Gray code

## Spec
Device:     ***xilinx_u200_gen3x16_xdma_2_202110_1*** <br>
Function:   `Gry_Code = Bin_Code ^ (Bin_Code >> 1)`

`s_axilite` signals:
| Name             | Description         | Offset | Size (bits) | ASSOCIATED_BUSIF |
|------------------|---------------------|--------|-------------|------------------|
| User Control     | Control Signals     | 0x010  | 32          |                  |
| Bin_Code         | Pointer argument    | 0x01c  | 64          | m00_axi          |
| Gry_Code         | Pointer argument    | 0x028  | 64          | m00_axi          |



## Step1: Setup tool environment
>   ```bash
>    #setup Xilinx Vitis tools. XILINX_VITIS and XILINX_VIVADO will be set in this step.
>    source <VITIS_install_path>/settings64.sh
>    #Setup Xilinx runtime. XILINX_XRT will be set in this step.
>    source <XRT_install_path>/setup.sh
>   ```

## Step2: Package your rtl kernel in vivado, [similar gui procedure](https://github.com/Xilinx/Vitis-Tutorials/blob/2023.2/Hardware_Acceleration/Feature_Tutorials/01-rtl_kernel_workflow/package_ip.md) from xilinx tutorial, or follow [gui-flow](./doc/gui-flow.pdf)
> ```bash
> # package rtl kernel via vivado
> mkdir -p ./user-xo
> vivado -mode batch -source scripts/gen_xo.tcl -tclargs ./user-xo/B2G.xo B2G hw xilinx_u200_gen3x16_xdma_2_202110_1
> ```

## Step3: Build up host program in vitis, [similar gui procedure](https://github.com/Xilinx/Vitis-Tutorials/blob/2023.2/Hardware_Acceleration/Feature_Tutorials/01-rtl_kernel_workflow/using_the_rtl_kernel.md) from xilinx tutorial, or follow [gui-flow](./doc/gui-flow.pdf)

<br>

> ```bash
> # Link rtl kernel via vitis (v++ -t <hw | hw_emu>)
> mkdir -p ./user-xclbin
> v++ -t hw --platform xilinx_u200_gen3x16_xdma_2_202110_1 --save-temps  -l -o ./user-xclbin/B2G.hw_emu.xclbin ./user-xo/B2G.xo
> cp -rf ./user-xclbin/B2G.hw_emu.xclbin ./B2G.xclbin
> emconfigutil --platform xilinx_u200_gen3x16_xdma_2_202110_1 --od ./user-xclbin/
> cp -rf ./user-xclbin//emconfig.json .
> 
> # Compile host program
> g++ -g -I./ -I/opt/xilinx/xrt/include -I/tools/Xilinx/Vivado/2022.1/include -Wall -O0 -g -std=c++17 -fmessage-length=0 ./src/host/user-host.cpp -o 'host' -L/opt/xilinx/xrt/lib -lxrt_coreutil -pthread -lrt -lstdc++
> 
> # Run application
> ./host ./B2G.xclbin xilinx_u200_gen3x16_xdma_2_202110_1
> ```


# Scripts
Or you can simply run the following scripts. 
<br> 

The Makefile will do <br> 
<!-- 1. Package IP from vivado to generate rtl kernel for vitis.
2. Compile host program, generate `.xclbin` for FPGA.
3. Run application -->


1. Build an AMD Vivado™ project to package the RTL design IP, and package a user-managed kernel (`.xo`).
2. Use the Vitis compiler (`v++`) to link the kernel to the target platform and generate the `.xlcbin` file.
3. Compile the XRT native API host application `./src/host/user-host.cpp`.
4. If necessary generate the emulation platform and setup the emulation environment.
5. Run the application and kernel.


all in one single command <br>
## Hardware Emulation
> ```bash
> make clean
> make run TARGET=hw_emu HOST=user
> ```

## Hardware Execution
> ```bash
> make clean
> make run TARGET=hw HOST=user
> ```

## Expected Output
```sh
======================================
===========START SIMULATION===========
======================================
argc = 3
argv[0] = ./host
argv[1] = ./B2G.xclbin
argv[2] = xilinx_u200_gen3x16_xdma_2_202110_1
Open the device 0
Load the xclbin ./B2G.xclbin
Allocate Buffer in Global Memory
Input Binary Code: 456
loaded the data
synchronize input buffer data to device global memory
INFO: Setting IP Data
Setting Register "Binary code" (Input Address)
Gold 0x1c: 0 Your: 0
Gold 0x20: 50 Your: 50
Setting Register "Gray Code" (Input Address)
Gold 0x1c: 1000 Your: 1000
Gold 0x20: 50 Your: 50
INFO: IP Start
Read Loop iteration: 1 Kernel Done: 0 Kernel Idle: 0
Read Loop iteration: 2 Kernel Done: 2 Kernel Idle: 4
INFO: IP Done
Get the output data from the device
Gold: 300
Your: 300
TEST PASSED
======================================
=============END SIMULATION===========
======================================
```

## Summary 
In this `binary2gray` folder, we implement a `B2G` rtl IP in `Verilog` **(./src/IP)**. Given the address of **binary code** we can write the corresponding **gray code** to specified address.
