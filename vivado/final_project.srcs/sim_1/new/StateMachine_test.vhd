

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity StateMachine_test is
--  Port ( );
end StateMachine_test;

architecture Behavioral of StateMachine_test is

component ALU_Module 
	Port (
    AC_IN :  in  STD_LOGIC_VECTOR(15 downto 0);     --input AC
	 X_IN   : in  STD_LOGIC_VECTOR(15 downto 0);     --input of memory
    ALU_Sel  : in  STD_LOGIC_VECTOR(5 downto 0);    --input 6-bit for selecting function
	 E_IN : in STD_LOGIC;                            --input E
	 Enable : in STD_LOGIC;
    AC_OUT   : out  STD_LOGIC_VECTOR(15 downto 0);  --output AC
    E_OUT : out STD_LOGIC                           --output E
    );
end component;
-------------------------------------------------------------------------------RAM
component RAM_Module 
  generic (
    addr_width : integer := 10;   --total number of elements to store (put exact number)
    data_width : integer := 16    --number of bits in each elements
  );
  
  port(
    clk: in std_logic;
    we : in std_logic;                                  --write enable
    addr : in std_logic_vector(addr_width-1 downto 0);  --input port for getting address
    din : in std_logic_vector(data_width-1 downto 0);   --input data to be stored in RAM
    dout : out std_logic_vector(data_width-1 downto 0)  --output data read from RAM
    );
end component;
---------------------------------------------------------------------------------ROM
component ROM_Module 
    generic(
        addr_width : integer := 1024; --total number of elements to store (put exact number)
        addr_bits  : integer := 10;  -- bits requires to store elements specified by addr_width
        data_width : integer := 16   -- number of bits in each elements
        );
port(
    addr : in std_logic_vector(addr_bits-1 downto 0);  --input port for getting address
    data : out std_logic_vector(data_width-1 downto 0) --ouput data at location 'addr'
);
end component;
-----------------------------------------------------------------------------------PC
component Program_Counter 
	generic (
		 PC_width : integer := 10   --total number of program counter
	  );
	
	Port ( clk : in  STD_LOGIC;
           PC_in : in  STD_LOGIC_VECTOR (PC_width-1 downto 0);
           PC_opcode : in  STD_LOGIC_VECTOR (1 downto 0);
           PC_out : out  STD_LOGIC_VECTOR (PC_width-1 downto 0)
           );
end component;
----------------------------------------------------------------------------useful signals
attribute FSM_ENCODING : string;
type State is (Fetch, Decode, Read_RAM, Execute , AC_UPDATE , HLT);
signal curr_state : State := Fetch;
signal nxt_state  : State := Fetch;
--attribute FSM_ENCODING of curr_state : signal is "binary";
  
signal PC_state: std_logic_vector(1 downto 0):= "00";
signal PC_out: std_logic_vector(9 downto 0):= "0000000000";
signal PC_input: std_logic_vector(9 downto 0):= "0000000000";
signal IR: std_logic_vector(15 downto 0);
signal WriteEnable: std_logic:='0';

signal RAM_Address : std_logic_vector (9 downto 0):="0000000000";
signal RAM_Input: std_logic_vector(15 downto 0);
signal DR: std_logic_vector(15 downto 0);

signal E: std_logic;
signal AC: std_logic_vector(15 downto 0):="0000000000000000";
signal Operand: std_logic_vector(15 downto 0);
signal Opcode : std_logic_vector(5 downto 0);
signal Address : std_logic_vector(9 downto 0);

signal AC_signal: std_logic_vector(15 downto 0):="0000000000000000";
signal E_signal: std_logic:='0';
signal Enable_ALU: std_logic:= '0';

signal error: std_logic:='0';

--Inputs
signal reset : std_logic := '0';
signal clk : std_logic := '0';

-- Clock period definitions
constant clk_period : time := 20 ns;

-------------------------------------------------------------------------constant opcodes

constant op_and :std_logic_vector:= "000001";
constant op_sta :std_logic_vector:= "000010";
constant op_lda :std_logic_vector:= "000011";
constant op_add :std_logic_vector:= "000100";
constant op_inc :std_logic_vector:= "000101";
constant op_cla :std_logic_vector:= "000110";
constant op_cle :std_logic_vector:= "000111";
constant op_cil :std_logic_vector:= "001000";
constant op_cir :std_logic_vector:= "001001";
constant op_spa :std_logic_vector:= "001010";
constant op_sna :std_logic_vector:= "001011";
constant op_sze :std_logic_vector:= "001100";
constant op_sza :std_logic_vector:= "001101";
constant op_lls :std_logic_vector:= "001110";
constant op_lrs :std_logic_vector:= "001111";
constant op_mul :std_logic_vector:= "010000";
constant op_sqr :std_logic_vector:= "100000";				
		
begin


------------------------------------------------------------PORTMAP Modules
PC_Module: Program_Counter port map(
                            clk => clk,
                            PC_in => PC_input,
                            PC_opcode => PC_state,
                            PC_out => PC_out);
									
ROM: ROM_Module port map(
					 addr => PC_out,
					 data => IR
				);
				
RAM: RAM_Module port map(
						 clk => clk,
						 we => WriteEnable,                                 
						 addr => RAM_Address,
						 din => RAM_Input,
						 dout => DR
					 );
									
ALU: ALU_Module port map (
					 AC_IN => AC,
					 X_IN => Operand,
					 ALU_Sel => Opcode,
					 E_IN => E,
					 Enable => Enable_ALU,
					 AC_OUT => AC_signal,
					 E_OUT => E_signal                       
					 );


-------------------------------------------------------------process

process(clk,reset)
	begin 
	PC_state <= "00";
	if reset = '1' then 
		curr_state <= Fetch;
   elsif rising_edge(clk) then
      curr_state <= nxt_state;
   end if;
   
       case curr_state is
          when Fetch => 
              Opcode <= IR(15 downto 10);
              nxt_state <= Decode;
              
      
          when Decode => 
                case Opcode is
                  when op_and | op_sta | op_lda | op_add | op_mul | op_sqr => 
                    nxt_state <= Read_RAM;
                  when op_inc | op_cla | op_cle | op_cil | op_cir | op_spa | op_sna | op_sza | op_sze | op_lls | op_lrs => 
                    nxt_state <= Execute;                        
                  when others =>
                    nxt_state <= HLT;
                end case;
        
    
    
          when Read_RAM =>
             RAM_Address <= IR(9 downto 0);
             Operand <= DR ;
             nxt_state <= Execute;
            
            
          when Execute => 
            case Opcode is
                when op_and | op_add | op_inc | op_cla | op_cle | op_cil | op_cir | op_lls | op_lrs | op_mul | op_sqr =>
                    Operand <= DR ;
                    Enable_ALU <= '1';
                    nxt_state <= AC_UPDATE;
    --					  					 
                when op_sta =>    
                     WriteEnable <= '1';
                     RAM_Input <= AC;
                     nxt_state <= Fetch;
                     PC_state <= "01";
                     
                when op_lda =>  
                     WriteEnable <= '0';
                     AC <= DR;
                     nxt_state <= Fetch;
                     PC_state <= "01";
                     
                when op_spa =>   
                    if AC(15) = '0' then
                        PC_state <= "10";
                    else
                        PC_state <= "01";
                    end if;
                    nxt_state <= Fetch;
                    
                when op_sna =>  
                    if AC(15) = '1' then
                        PC_state <= "10";
                    else
                        PC_state <= "01";
                    end if;
                    nxt_state <= Fetch;
                    
                when op_sze =>  
                    if E = '0' then
                        PC_state <= "10";
                    else
                        PC_state <= "01";
                    end if;
                    nxt_state <= Fetch;
                    
                when op_sza =>  
                    if AC = "0000000000000000" then
                       PC_state <= "10";
                    else
                       PC_state <= "01";
                    end if;
                    nxt_state <= Fetch;
                        
                when others =>
            end case;
            
        when AC_UPDATE =>
        
            AC <= AC_signal;
            E <= E_signal;
            Enable_ALU <= '0';
            PC_state <= "01";
            nxt_state <= Fetch;
            
        when others  =>
--            nxt_state <= Fetch;
        end case;
	
end process;

-- Clock process definitions
clk_process :process
begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
end process;


-- Stimulus process
stim_proc: process
begin		
  -- hold reset state for 100 ns.
  wait for 100 ns;	

  wait for clk_period*10;

  -- insert stimulus here 

  wait; 
    
end process;


end Behavioral;

