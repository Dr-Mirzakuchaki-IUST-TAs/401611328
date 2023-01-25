
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY LTC2309_TB IS
END LTC2309_TB;
 
ARCHITECTURE behavior OF LTC2309_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT LTC2309
    PORT(
         CLK : IN  std_logic;
         RW  : IN  std_logic;
         AD0 : IN  std_logic;
         AD1 : IN  std_logic;
         SDA : BUFFER  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RW  : std_logic := '0';
   signal AD0 : std_logic := 'X';
   signal AD1 : std_logic := 'X';

	--BiDirs 
   signal SDA : std_logic := '1';

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: LTC2309 PORT MAP (
          CLK => CLK,
          RW  => RW,
          AD0 => AD0,
          AD1 => AD1,
          SDA => SDA
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
		AD0 <= 'X';
		AD1 <= 'X';
		SDA <= '1';
		wait for CLK_period*2000;
		AD0 <= '0';
		AD1 <= 'Z';
		RW  <= '1';

		wait;
   end process;

END;




--		
--		RW  <= '0';
--		SDA <= '0';
--	   wait for CLK_period*1000;
--		SDA <= '0';
--	   --
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '1';
--		wait for CLK_period*1000;
--		SDA <= '1';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '1';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		--
--		wait for CLK_period*1000;
--		SDA <= '0';
--		--
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= '0';
--		wait for CLK_period*1000;
--		SDA <= 'X';
--		wait for CLK_period*1000;
--		SDA <= 'X';
--		--
--		wait for CLK_period*1000;
--		SDA <= '0';
--		--
--		wait for CLK_period*1000;
--		SDA <= '1';
--		--
