## uart-axi
AXI4 bus master, controlled by UART  
intended for debugging & testing on FPGA  
***important***: no comprehensive verification was carried out
## usage 
* Write 0xABCD5678 to address 0x1234  
`w⎵1234⎵abcd5678[CR]`  
* Read from address 0x1234  
`r⎵1234[CR]`  
* Burst read from address 0x1234, 4words  
`br⎵1234⎵03[CR]`  
  
⎵: space, [CR]: CR  
* note
    * Both upper and lower case characters are accepted
    * Zero padding on MSB side is not necessary
    * supports only 32bit width data, 16bit width address (so far)
    * For FPGA other than Xilinx, FIFO might have to be replaced
