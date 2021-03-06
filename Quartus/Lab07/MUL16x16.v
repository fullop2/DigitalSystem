`define BOOTH_m2A 3'd1
`define BOOTH_mA 3'd2
`define BOOTH_0 3'd3
`define BOOTH_pA 3'd4
`define BOOTH_p2A 3'd5


module BOOTH(data, sel);
input [2:0] data;
output [2:0] sel;
reg [2:0] sel;

always @(data)
	case(data)
		3'b000 : begin sel = `BOOTH_0; end
		3'b010 : begin sel = `BOOTH_pA; end
		3'b100 : begin sel = `BOOTH_m2A; end
		3'b110 : begin sel = `BOOTH_mA; end
		3'b001 : begin sel = `BOOTH_pA; end
		3'b011 : begin sel = `BOOTH_p2A; end
		3'b101 : begin sel = `BOOTH_mA; end
		3'b111 : begin sel = `BOOTH_0; end
		default : begin sel = 3'bX; end
	endcase
endmodule

module PPGen (din, sel, dout, sign);
	input [15:0] din;
	input [2:0] sel; // -2A -A 0 A 2A
	output [16:0] dout;
	output sign;
	reg [16:0] dout;
	reg sign;

	always @(sel or din)	begin
		casex(sel)
			`BOOTH_m2A: begin dout = ~{din, 1'b0}; sign = 1'b1; end
			`BOOTH_mA : begin dout = ~{din[15], din}; sign = 1'b1; end
			`BOOTH_0 : begin dout = 17'b0; sign = 1'b0; end
			`BOOTH_pA : begin dout = {din[15], din}; sign = 1'b0; end
			`BOOTH_p2A: begin dout = {din, 1'b0}; sign = 1'b0; end
			default : begin dout = 17'bX; sign = 1'bX; end
		endcase
	end
endmodule

module MUL16x16(x, y, z, ov);

	input [15:0] x;
	input [15:0] y;
	output [30:0] z;
	output ov;
	/* wire delarations */
	
	wire sign0, sign1, sign2, sign3, sign4, sign5, sign6, sign7, sign8;
	wire [2:0] sel0, sel1, sel2, sel3, sel4, sel5, sel6, sel7, sel8;
	wire [16:0] psum0, psum1, psum2, psum3, psum4, psum5, psum6, psum7;
	wire [20:0] sum0,sum1,sum2,sum3,sum4,sum5,sum6,
					car0,car1,car2,car3,car4,car5,car6;

	wire [17:0] csum,ccar;
	
	/* Block interconnection */
	// Booth Encoding
	BOOTH booth0(.data({y[1:0],1'b0}), .sel(sel0));
	BOOTH booth1(.data(y[3:1]), .sel(sel1));
	BOOTH booth2(.data(y[5:3]), .sel(sel2));
	BOOTH booth3(.data(y[7:5]), .sel(sel3));
	BOOTH booth4(.data(y[9:7]), .sel(sel4));
	BOOTH booth5(.data(y[11:9]), .sel(sel5));
	BOOTH booth6(.data(y[13:11]), .sel(sel6));
	BOOTH booth7(.data(y[15:13]), .sel(sel7));
	BOOTH booth8(.data({2'b0,y[15]}), .sel(sel8));
	
	// Partial Product Generation
	PPGen ppgen0(.din(x),.sel(sel0),.dout(psum0),.sign(sign0)); // 16:0
	PPGen ppgen1(.din(x),.sel(sel1),.dout(psum1),.sign(sign1)); // 18:2
	PPGen ppgen2(.din(x),.sel(sel2),.dout(psum2),.sign(sign2)); // 20:4
	PPGen ppgen3(.din(x),.sel(sel3),.dout(psum3),.sign(sign3)); // 22:6
	PPGen ppgen4(.din(x),.sel(sel4),.dout(psum4),.sign(sign4)); // 24:8
	PPGen ppgen5(.din(x),.sel(sel5),.dout(psum5),.sign(sign5)); // 26:10
	PPGen ppgen6(.din(x),.sel(sel6),.dout(psum6),.sign(sign6)); // 28:12
	PPGen ppgen7(.din(x),.sel(sel7),.dout(psum7),.sign(sign7)); // 30:28
	
	CSA CSA0(
	.a({3'b0, ~psum0[16], {2{psum0[16]}}, psum0[16:2]}),
	.b({2'b0, 1'b1, ~psum1[16], psum1[16:0]}),
	.c({1'b1, ~psum2[16], psum2[16:0], 2'b0}),
	.cout(car0),
	.sum(sum0)
	);
	
	CSA CSA1(
	.a({2'b0, sum0[20:2]}),
	.b({1'b0, car0[20:2], 1'b0}),
	.c({1'b1, ~psum3[16], psum3[16:0], 1'b0, sign2}),
	.cout(car1),
	.sum(sum1)
	);

	CSA CSA2(
	.a({2'b0, sum1[20:2]}),
	.b({1'b0, car1[20:2], 1'b0}),
	.c({1'b1, ~psum4[16], psum4[16:0], 1'b0, sign3}),
	.cout(car2),
	.sum(sum2)
	);

	CSA CSA3(
	.a({2'b0, sum2[20:2]}),
	.b({1'b0, car2[20:2], 1'b0}),
	.c({1'b1, ~psum5[16], psum5[16:0], 1'b0, sign4}),
	.cout(car3),
	.sum(sum3)
	);

	CSA CSA4(
	.a({2'b0, sum3[20:2]}),
	.b({1'b0, car3[20:2], 1'b0}),
	.c({1'b1, ~psum6[16], psum6[16:0], 1'b0, sign5}),
	.cout(car4),
	.sum(sum4)
	);

	CSA CSA5(
	.a({2'b0, sum4[20:2]}),
	.b({1'b0, car4[20:2], 1'b0}),
	.c({1'b1, ~psum7[16], psum7[16:0], 1'b0, sign6}),
	.cout(car5),
	.sum(sum5)
	);


	CSA_HA CSAHA(
	.a(sum5[19:2]),
	.b({car5[18:2],sign7}),
	.cout(ccar),
	.sum(csum)
	);
	
	Kogge32b ksa32(
	.x({csum[17:0],sum5[1:0],sum4[1:0],sum3[1:0],sum2[1:0],sum1[1:0],sum0[1:0],psum0[1:0]}),
	.y({ccar[16:0],car5[1:0],car4[1:0],car3[1:0],car2[1:0],car1[1:0],car0[1:0],sign1,1'b0,sign0}),
	.cin(0),
	.cout(ov),
	.sum(z)
	);
	
endmodule


module CSA (a, b, c, cout, sum);
	input [20:0] a;
	input [20:0] b;
	input [20:0] c;
	output [20:0] cout, sum;
	
	/* Adder Connection */
	FA fadd20(a[20],b[20],c[20],cout[20],sum[20]);
	FA fadd19(a[19],b[19],c[19],cout[19],sum[19]);
	FA fadd18(a[18],b[18],c[18],cout[18],sum[18]);
	FA fadd17(a[17],b[17],c[17],cout[17],sum[17]);
	FA fadd16(a[16],b[16],c[16],cout[16],sum[16]);
	FA fadd15(a[15],b[15],c[15],cout[15],sum[15]);
	FA fadd14(a[14],b[14],c[14],cout[14],sum[14]);
	FA fadd13(a[13],b[13],c[13],cout[13],sum[13]);
	FA fadd12(a[12],b[12],c[12],cout[12],sum[12]);
	FA fadd11(a[11],b[11],c[11],cout[11],sum[11]);
	FA fadd10(a[10],b[10],c[10],cout[10],sum[10]);
	FA fadd9(a[9],b[9],c[9],cout[9],sum[9]);
	FA fadd8(a[8],b[8],c[8],cout[8],sum[8]);
	FA fadd7(a[7],b[7],c[7],cout[7],sum[7]);
	FA fadd6(a[6],b[6],c[6],cout[6],sum[6]);
	FA fadd5(a[5],b[5],c[5],cout[5],sum[5]);
	FA fadd4(a[4],b[4],c[4],cout[4],sum[4]);
	FA fadd3(a[3],b[3],c[3],cout[3],sum[3]);
	FA fadd2(a[2],b[2],c[2],cout[2],sum[2]);
	FA fadd1(a[1],b[1],c[1],cout[1],sum[1]);
	FA fadd0(a[0],b[0],c[0],cout[0],sum[0]);
endmodule

module CSA_HA (a, b, cout, sum);
	input [17:0] a;
	input [17:0] b;
	output [17:0] cout, sum;
	
	/* Adder Connection */
	HA hadd17(a[17],b[17],cout[17],sum[17]);
	HA hadd16(a[16],b[16],cout[16],sum[16]);
	HA hadd15(a[15],b[15],cout[15],sum[15]);
	HA hadd14(a[14],b[14],cout[14],sum[14]);
	HA hadd13(a[13],b[13],cout[13],sum[13]);
	HA hadd12(a[12],b[12],cout[12],sum[12]);
	HA hadd11(a[11],b[11],cout[11],sum[11]);
	HA hadd10(a[10],b[10],cout[10],sum[10]);
	HA hadd9(a[9],b[9],cout[9],sum[9]);
	HA hadd8(a[8],b[8],cout[8],sum[8]);
	HA hadd7(a[7],b[7],cout[7],sum[7]);
	HA hadd6(a[6],b[6],cout[6],sum[6]);
	HA hadd5(a[5],b[5],cout[5],sum[5]);
	HA hadd4(a[4],b[4],cout[4],sum[4]);
	HA hadd3(a[3],b[3],cout[3],sum[3]);
	HA hadd2(a[2],b[2],cout[2],sum[2]);
	HA hadd1(a[1],b[1],cout[1],sum[1]);
	HA hadd0(a[0],b[0],cout[0],sum[0]);
endmodule

module FA(a, b, c, cout, sum);
	input a, b, c;
	output cout, sum;
	assign {cout,sum} = a + b + c;
endmodule

module HA(a, b, cout, sum);
	input a, b;
	output cout, sum;
	assign {cout,sum} = a + b;
endmodule
