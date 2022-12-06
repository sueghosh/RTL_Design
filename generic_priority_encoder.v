//parameterized generic priority encoder with valid bit

module generic_priority_encoder(In,Out,Valid);
  parameter N = 4;
  input [N-1:0] In;
  output reg [$clog2(N)-1:0] Out;
  output reg Valid;
  
  integer I;
  
  always @ (In)
    begin
      Out = 0;
      Valid = 0;
      for (I=0;I<N;I=I+1)
        if (In[I])
        begin
          Out = I;
          Valid = 1;
        end
    end
  
endmodule
