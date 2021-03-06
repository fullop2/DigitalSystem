`timescale 1ns / 10ps

module register_file_tb;

reg clk;
reg nRESET;
reg write_enable;
reg [2:0] write_addr;
reg [15:0] write_data;

reg [2:0] read_addr_A;
reg [2:0] read_addr_B;
reg [2:0] read_addr_C;

wire [15:0] read_data_A;
wire [15:0] read_data_B;
wire [15:0] read_data_C;

always #2.5 clk=~clk;

register_file register_file_i(
	.clk(clk),
	.nRESET(nRESET),
	.write_enable(write_enable),
	.write_addr(write_addr),
	.write_data(write_data),
	.read_addr_A(read_addr_A),
	.read_addr_B(read_addr_B),
	.read_addr_C(read_addr_C),
	.read_data_A(read_data_A),
	.read_data_B(read_data_B),
	.read_data_C(read_data_C)
);


initial begin
	
	$dumpvars;
	clk=1'b1;
	nRESET = 1'b0;
	write_enable=1'b0;
	write_addr=3'b0;
	write_data=16'b0;
	read_addr_A=3'b0;
	read_addr_B=3'b0;
	read_addr_C=3'b0;
	#5
	// 저장안됨
	write_enable=1'b1;
	write_addr=3'b000;
	write_data=16'b1111_1111_0000_0000;
	#5
	
	write_enable=1'b1;
	write_addr=3'b010;
	write_data=16'b0000_0000_1111_1111;
	#5
	
	// 저장됨 
	nRESET = 1'b1;
	write_enable=1'b1;
	write_addr=3'b110;
	write_data=16'b0000_0001_0000_0000;
	#5
	
	write_enable=1'b1;
	write_addr=3'b111;
	write_data=16'b0000_0000_0000_0001;
	#5
	
	write_enable=1'b1;
	write_addr=3'b100;
	write_data=16'b0000_0000_1000_0000;
	#5
	
	write_enable=1'b0;
	read_addr_A=3'b000;
	read_addr_B=3'b010;
	read_addr_C=3'b110;
	#5
	
	write_enable=1'b0;
	read_addr_A=3'b010;
	read_addr_B=3'b111;
	read_addr_C=3'b100;

	#10;
	$dumpoff;
	$finish;
end

endmodule
