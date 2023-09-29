-------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ALU_TEST is
--  Port ( );
end ALU_TEST;

architecture Behavioral of ALU_TEST is
-- Temporary 
	signal ALU_Result : unsigned (16 downto 0) :="00000000000000000";
	signal MUL_Result : STD_LOGIC_VECTOR (11 downto 0);
	signal SQRT_Result : STD_LOGIC_VECTOR (7 downto 0);
    
    signal AC_IN    :  STD_LOGIC_VECTOR (15 downto 0);     --input AC
    signal X_IN     :   STD_LOGIC_VECTOR(15 downto 0);     --input of memory
    signal ALU_Sel  :   STD_LOGIC_VECTOR(5 downto 0);    --input 6-bit for selecting function
    signal E_IN     :   STD_LOGIC;                            --input E
    signal Enable   :   STD_LOGIC;                          --input enable                      
    signal AC_OUT   :   STD_LOGIC_VECTOR(15 downto 0);  --output AC
    signal E_OUT    :   STD_LOGIC;  
	-- Component of Multiplier Module
	component simple_multi
        port ( 
            x : in  STD_LOGIC_VECTOR (5 downto 0);
            y : in  STD_LOGIC_VECTOR (5 downto 0);
            p : out  STD_LOGIC_VECTOR (11 downto 0));
	end component;
	
	-- Component of Square root Module
	component main 
			port ( A : in  STD_LOGIC_VECTOR (16 downto 1);
					 q : out  STD_LOGIC_VECTOR (8 downto 1));
	end component;



begin

	Multiplier_Module: simple_multi 
		port map ( x  => AC_IN(5 downto 0),
	              y => X_IN(5 downto 0), 
	              p => MUL_Result);
					   
	Square_root_Module: main
		port map( A => X_IN(15 downto 0), 
					 q =>  SQRT_Result); 
		  
  
					  
stim_proc: process
	begin
    wait for 1 ns;
	if Enable='1' then
	case(ALU_Sel) is
	   when "000001" => -- AND
			ALU_Result(15 downto 0) <= unsigned(AC_IN) and unsigned(X_IN);
			AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			E_OUT <= '0';
					 
	   when "000100" => -- ADD
			ALU_Result <= '0' & unsigned(AC_IN) + unsigned(X_IN);
			AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			E_OUT <= ALU_Result(16);
					 
		when "000101" =>   --Increment AC
		   
			ALU_Result <= '0' & (unsigned(AC_IN) + 1);
			AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			E_OUT <= ALU_Result(16);               
                
      when "000110" =>    --clear AC
			AC_OUT <= (others => '0');
                
      when "000111" =>    -- clear E
			E_OUT <= '0';
			
		when "001000" =>     -- circular left shift
			 ALU_Result(15 downto 1) <= unsigned(AC_IN(14 downto 0));
			 ALU_Result(0) <= E_IN;
			 AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			 E_OUT <= AC_IN(15);
			 
		when "001001" =>     -- circular right shift
			 ALU_Result(14 downto 0) <= unsigned(AC_IN(15 downto 1));
			 ALU_Result(15) <= E_IN;
			 AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			 E_OUT <= AC_IN(0);
			 
			 
		when "001110" =>    -- linear left shift
			 ALU_Result(15 downto 1) <= unsigned(AC_IN(14 downto 0));
			 ALU_Result(0) <= '0';
			 AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			 E_OUT <= AC_IN(15);
			 
			 
		when "001111" =>    -- linear right shift
			 ALU_Result(14 downto 0) <= unsigned(AC_IN(15 downto 1));
			 ALU_Result(15) <= E_IN;
			 AC_OUT <= std_logic_vector(ALU_Result(15 downto 0));
			 E_OUT <= '0';
			 
					  
		when "010000" =>    -- Multiply			  
			AC_OUT(15 downto 12) <= "0000";
			AC_OUT(11 downto 0) <= std_logic_vector(MUL_Result);
			E_OUT <= '0';


		when "100000" =>    --SQR
			 AC_OUT(7 downto 0) <= SQRT_Result;
			 AC_OUT(15 downto 8) <= "00000000";  
			 E_OUT <= '0';
			 
					 
	   when others =>       --Nothing
    
	  
	end case;
	end if;
 end process;

AC_IN <= "0000000000000000";
X_IN <= "0000000000000000";
ALU_Sel <= "000101";
E_IN <= '0';
Enable <= '1';

end Behavioral;
