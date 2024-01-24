/*
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
*/

#include <iostream>
#include <cstring>

// XRT includes
#include "xrt/xrt_bo.h"
#include "xrt/xrt_device.h"
#include <experimental/xrt_xclbin.h>
#include <experimental/xrt_ip.h>

#define DATA_SIZE 100
#define IP_START 0x1
#define IP_DONE 0x2
#define IP_IDLE 0x4

#define USER_OFFSET 0x10
#define Bin_OFFSET 0x1c
#define Gry_OFFSET 0x28


int main(int argc, char** argv) {
    std::cout << "======================================" << std::endl;
    std::cout << "===========START SIMULATION===========" << std::endl;
    std::cout << "======================================" << std::endl;
    std::cout << "argc = " << argc << std::endl;
	for(int i=0; i < argc; i++){
	    std::cout << "argv[" << i << "] = " << argv[i] << std::endl;
	}

    // Read settings
	std::string binaryFile = argv[1];
    auto xclbin = xrt::xclbin(binaryFile);
    int device_index = 0;

    std::cout << "Open the device " << device_index << std::endl;
    auto device = xrt::device(device_index);
    std::cout << "Load the xclbin " << binaryFile << std::endl;
    auto uuid = device.load_xclbin(binaryFile);
 
    size_t vector_size_bytes = sizeof(int) * DATA_SIZE;

    auto ip1 = xrt::ip(device, uuid, "B2G:{B2G_1}");

    std::cout << "Allocate Buffer in Global Memory\n";
    auto ip1_boA = xrt::bo(device, vector_size_bytes, 1);
    auto ip1_boB = xrt::bo(device, vector_size_bytes, 1);

    // Map the contents of the buffer object into host memory
    auto bo0_map = ip1_boA.map<int*>();
    auto bo1_map = ip1_boB.map<int*>();
 
    std::fill(bo0_map, bo0_map + DATA_SIZE, 0);
    std::fill(bo1_map, bo1_map + DATA_SIZE, 0);


    // Create the test data
    int bufReference[DATA_SIZE];
    for (int i=0 ; i<DATA_SIZE; i++) {
        bo0_map[i] = i;
    }


    //Generate gold data data for validation
    for (int i=0 ; i<DATA_SIZE; i++) {
        bufReference[i] = (bo0_map[i] >> 1) ^ bo0_map[i];
    }


    // Get the buffer physical address
    std::cout << "loaded the data" << std::endl;
    uint64_t buf_addr[2];
    buf_addr[0] = ip1_boA.address();
    buf_addr[1] = ip1_boB.address();

    // Synchronize buffer content with device side
    std::cout << "synchronize input buffer data to device global memory\n";
    ip1_boA.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    ip1_boB.sync(XCL_BO_SYNC_BO_TO_DEVICE);

    
    // start simulation
    uint32_t tmp0, tmp1, adr;
    uint32_t axi_ctrl = 0, krnl_done = 0, krnl_idle = 0;
    int j = 0;
    for (int i=0; i<DATA_SIZE; i++) {
        // Write Binary code address
        std::cout << "INFO: Setting IP Data" << std::endl;
        std::cout << "Setting Register \"Binary code\" (Input Address)" << std::endl;
        ip1.write_register(Bin_OFFSET, buf_addr[0]);
        ip1.write_register(Bin_OFFSET + 4, buf_addr[0] >> 32);
        tmp0 = ip1.read_register(Bin_OFFSET);
        tmp1 = ip1.read_register(Bin_OFFSET + 4);
        adr = buf_addr[0];
        std::cout << "Gold 0x1c: " << std::hex << adr           		<< " Your: " << std::hex << tmp0 << std::endl;
        std::cout << "Gold 0x20: " << std::hex << (buf_addr[0] >> 32)   << " Your: " << std::hex << tmp1 << std::endl;


        // Write Gray code address
        std::cout << "Setting Register \"Gray Code\" (Output Address)" << std::endl;
        ip1.write_register(Gry_OFFSET, buf_addr[1]);
        ip1.write_register(Gry_OFFSET + 4, buf_addr[1] >> 32);
        tmp0 = ip1.read_register(Gry_OFFSET);
        tmp1 = ip1.read_register(Gry_OFFSET + 4);
        adr = buf_addr[1];
        std::cout << "Gold 0x1c: " << std::hex << adr           		<< " Your: " << std::hex << tmp0 << std::endl;
        std::cout << "Gold 0x20: " << std::hex << (buf_addr[1] >> 32)   << " Your: " << std::hex << tmp1 << std::endl;


        // Start kernel
        std::cout << "INFO: IP Start" << std::endl;
        ip1.write_register(USER_OFFSET, IP_START);

        // Polling 
        while (krnl_done != IP_DONE) {
            axi_ctrl = ip1.read_register(USER_OFFSET);
            krnl_done = axi_ctrl & 0x02;
            krnl_idle = axi_ctrl & 0x04;
            j += 1;
            std::cout << "Read Loop iteration: " << j << " Kernel Done: " << krnl_done << " Kernel Idle: " << krnl_idle << "\n";
        }
        std::cout << "INFO: IP Done" << std::endl;

        buf_addr[0] += 4;
        buf_addr[1] += 4;
    }

    // Get the output;
    std::cout << std::dec;
    std::cout << "Get the output data from the device" << std::endl;
    ip1_boB.sync(XCL_BO_SYNC_BO_FROM_DEVICE);

    // Validate results
    uint32_t out[DATA_SIZE], gold[DATA_SIZE];
    int error_num = 0;

    for (int i=0; i<DATA_SIZE; i++) {
        out[i]  = bo1_map[i];
        gold[i] = bufReference[i];

        if (out[i] != gold[i])
            error_num += 1;

        std::cout << "Binary: " << bo0_map[i] << ", Gold: " << gold[i] << ", Your: " << out[i] << std::endl;
    }

    if (error_num != 0)
    	std::cout << "TEST FAILED\n";
    else
    	std::cout << "TEST PASSED\n";

    std::cout << "======================================" << std::endl;
    std::cout << "=============END SIMULATION===========" << std::endl;
    std::cout << "======================================" << std::endl;
    return 0;
}