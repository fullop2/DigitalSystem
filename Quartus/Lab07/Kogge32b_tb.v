module Kogge32b_tb;

reg [31:0] x,y;
reg cin;
wire cout;
wire [31:0] sum;
reg [31:0] check;
reg chk_out;

parameter iter = 100;
integer i;
integer correct_cnt;


Kogge32b iks(x,y,cin,cout,sum);

initial begin
	correct_cnt = 0;
	for(i = 0; i < iter; i=i+1) begin				
		x = $random;
		y = $random;
		cin = $random;
		{chk_out, check} = x + y + cin;
		#10 
		if({cout, sum} == {chk_out, check}) 
			correct_cnt = correct_cnt + 1;
		else
			$display($time, " : %d + %d + %d = %d, but was (%d)\n",x,y,cin,{chk_out, check},{cout,sum});						
	end
	
	$display("correct count = %d\n",correct_cnt);
end 

endmodule
