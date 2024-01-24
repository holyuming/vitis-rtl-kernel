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

## Step2: Package your rtl kernel in vivado, [similar gui procedure](https://github.com/Xilinx/Vitis-Tutorials/blob/2023.2/Hardware_Acceleration/Feature_Tutorials/01-rtl_kernel_workflow/package_ip.md).

## Step3: Build up host program in vitis, [similar gui procedure](https://github.com/Xilinx/Vitis-Tutorials/blob/2023.2/Hardware_Acceleration/Feature_Tutorials/01-rtl_kernel_workflow/using_the_rtl_kernel.md)


<br>

# Scripts
Or you can simply run the following scripts.
## Hardware Emulation
```sh
make clean
make run TARGET=hw_emu HOST=user
```

## Hardware Execution
```sh
make clean
make run TARGET=hw HOST=user
```

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
