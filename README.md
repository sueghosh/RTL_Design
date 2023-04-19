
# VIVADO projects RTL_Design with Test Bench

1) i2c protocol: i2c master controller for eeprom: 
	i2c_eeprom_master.v i2c_tb.v

2)  CPU design and Testbench and instruction to do the following multiplication operation :

	cpu_16.v cpu_16_tb.v and instr2.mem

	0. MOV R0, #5;
	1. MOV R1, #6;
	2. MOV R2, #0;
	3. MOV R3, #6;
	4. ADD R2, R2; R0; 0+5,5+5,10+5,15+5,20+5,25+5
	5. SUB R3, R3; #1; 5,4,3,2,1,0
	6. JNZ @4;
	7. MOV R5, r2;
	8. HALT


3) UART Protocol: 

 uart.v and uart_tb.v

4) PWM updown : 
signal to increase the the brightness of the LED linearly reaching maximum brightness and then start decreasing the brightness of the LED till it reaches minimum level

pwm_updpwn.v



# RTL_Design with Test Bench to test the code at EDA PLAYground

5) AXI4 Slave Interface for RAM : https://www.edaplayground.com/x/K4kY

6) Multistage Counter : https://www.edaplayground.com/x/jMJr

7) Simple Cache Controller for Write Back Direct Mapped cache : https://www.edaplayground.com/x/8VvH

8) Asynchronous FIFO : https://www.edaplayground.com/x/HHZ8

9) Simple FIFO : https://www.edaplayground.com/x/HcWF

10) CRC gen/check Serial : https://www.edaplayground.com/x/Rxxq

11) CRC gen/check parallel bus : https://www.edaplayground.com/x/eSKC

12) Generic Priority Encoder: https://www.edaplayground.com/x/XMjg
