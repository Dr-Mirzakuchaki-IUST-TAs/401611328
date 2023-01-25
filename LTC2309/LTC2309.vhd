--AmirHosein Ahmadi_401611328
--VHDL PROJECT:
--LTC2309
--------------------------------------------------------------------   -- LIBRARY
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD.ALL;
LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;
--------------------------------------------------------------------   -- ENTITY
ENTITY LTC2309 IS
PORT(
	  CLK : IN    STD_LOGIC:='0';
	  RW  : IN    STD_LOGIC:='1';
	  AD0 : IN    STD_LOGIC:='X';
	  AD1 : IN    STD_LOGIC:='X';
	  SDA : BUFFER STD_LOGIC:='1'
	  );
	  CONSTANT TCONV    : TIME := 1300 NS; 									  -- FOR CONVERSION 
	  CONSTANT TACQ     : TIME := 240  NS; 									  -- FOR ACQUISTION
	  CONSTANT TREFWAKE : TIME := 200  mS; 								     -- FOR SLEEP MODE
END LTC2309;
--------------------------------------------------------------------	  -- ARCHITECTURE
ARCHITECTURE Behavioral OF LTC2309 IS
SIGNAL SCL_CLK     : STD_LOGIC := '1';											  -- GENERATE INTERNAL SCL CLOCK
SIGNAL SDA_CLK     : STD_LOGIC := '0';											  -- GENERATE INTERNAL SDA CLOCK
SIGNAL SDA_CLK_PRV : STD_LOGIC := '0';											  -- GENERATE INTERNAL SDA CLOCK
SIGNAL SCL         : STD_LOGIC := '1';
SIGNAL AD			 : STD_LOGIC_VECTOR(1 DOWNTO 0);							  -- USED TO COMBINE AD1&AD0 
SIGNAL ENABLE      : STD_LOGIC := '0'; 										  -- WHEN LTC2309 CALLED BY MASTER THIS BECOMES 1
--
SIGNAL ADDRESS     : STD_LOGIC_VECTOR(7  DOWNTO 0) := (OTHERS => 'Z'); -- I2C ADDRESS
SIGNAL DATA        : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => 'X'); -- ADC DATA FOR READ MODE
SIGNAL DAT         : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => 'X'); -- ADC DATA FOR WRITE MODE
SIGNAL DIN         : STD_LOGIC_VECTOR(5  DOWNTO 0) := (OTHERS => '0'); -- DIN 6BIT FOR MUX CONFIG OF ADC IN WRITE MODE
																							  -- DIN(S/D,0/S,S1,S0,UNI,,SLP)
																							  -- S/D : SINGLE-ENDED/DIFFERENTIAL BIT
																							  -- O/S : ODD/SIGN BIT
																							  -- S1  : CHANNEL SELECT BIT 1
																							  -- S0  : CHANNEL SELECT BIT 0
																							  -- UNI : UNIPOLAR/BIPOLAR BIT
																							  -- SLP : SLEEP/NAP MODE BIT
--																							  
SIGNAL TEMP        : STD_LOGIC_VECTOR(3  DOWNTO 0) := DIN(5 DOWNTO 2); -- USED FOR DATA SELECTION FROM ADC
SIGNAL TEMP1       : STD_LOGIC_VECTOR(3  DOWNTO 0) := DIN(5 DOWNTO 2); -- USED FOR DATA SELECTION FROM ADC
SIGNAL BUSS          : STD_LOGIC :='0';
--
SIGNAL SLV_ACK       : STD_LOGIC :='0';										  -- 8BITS ADDRESS&RW BIT SLAVE ACK
SIGNAL DIN_REC       : STD_LOGIC :='0';										  -- 8BITS ADDRESS&RW BIT SLAVE ACK
SIGNAL MAS_ACK       : STD_LOGIC :='0';   									  -- 8BITS MSB DATA MAS ACK
SIGNAL MAS_NACK      : STD_LOGIC :='0';                                -- 8BITS LBS DATA WITH 4 NIBBLE 0 MAS ACK
SIGNAL DATA_READY    : STD_LOGIC :='0';
SIGNAL NIBBLE_READY  : STD_LOGIC :='0';
SIGNAL STOP          : STD_LOGIC :='0';
--
SIGNAL ONCE_SLV_ACK  : STD_LOGIC :='0';
SIGNAL ONCE_MAS_ACK  : STD_LOGIC :='0';
SIGNAL ONCE_MAS_NACK : STD_LOGIC :='0';
BEGIN
--------------------------------------------------------------------  -- SET I2C ADDRESS DEPPEND ON AD1 & AD0 INPUT
I2C_ADDRESS: PROCESS(CLK)
	BEGIN
		AD <= AD1 & AD0;
		CASE AD IS
			WHEN "00"   => ADDRESS <= "0001000" & RW; ENABLE <= '1';
			WHEN "0Z"   => ADDRESS <= "0001001" & RW; ENABLE <= '1';
			WHEN "01"   => ADDRESS <= "0001010" & RW; ENABLE <= '1';
			WHEN "Z1"   => ADDRESS <= "0001011" & RW; ENABLE <= '1';
			WHEN "ZZ"   => ADDRESS <= "0011000" & RW; ENABLE <= '1';
			WHEN "Z0"   => ADDRESS <= "0011010" & RW; ENABLE <= '1'; 
			WHEN "10"   => ADDRESS <= "0011010" & RW; ENABLE <= '1';
			WHEN "1Z"   => ADDRESS <= "0011011" & RW; ENABLE <= '1';
			WHEN "11"   => ADDRESS <= "0101000" & RW; ENABLE <= '1';
			WHEN OTHERS => ADDRESS <= "ZZZZZZZZ"    ; ENABLE <= '0';
		END CASE;
END PROCESS I2C_ADDRESS;
--------------------------------------------------------------------  -- ADC DATA IS SELECTIVE BY DIN (S/D,O/S,S1,S0)
--NOTE: ADC DIDN'T SIMULATE IN THIS PROJECT AND JUST SET DEFAULT DATA FOR EVERY DIN SELECTION
ADC_DATA: PROCESS(CLK)
	BEGIN
		TEMP <= DIN(5 DOWNTO 2);
		CASE TEMP IS										               -- S/D O/S S1 S0 CH0 CH1 CH2 CH3 CH4 CH5 CH6 CH7 COM
			WHEN "0000" => DATA <= "010000001111";	    	   		--  0   0  0  0   +   - 
			WHEN "0001" => DATA <= "010000101111";						--  0   0  0  1  		     +   - 
			WHEN "0010" => DATA <= "010001001111";	        			--  0   0  1  0		             +   - 
			WHEN "0011" => DATA <= "010001101111";						--  0   0  1  1			  		            +   - 
			WHEN "0100" => DATA <= "010010001111";						--  0   1  0  0	-   + 
			WHEN "0101" => DATA <= "010010101111";						--  0   1  0  1			  -   + 
			WHEN "0110" => DATA <= "010011001111";						--  0   1  1  0 	      			 -   + 
			WHEN "0111" => DATA <= "010011101111";						--  0   1  1  1									-   +
			WHEN "1000" => DATA <= "010100001111";						--  1   0  0  0   +                               -
			WHEN "1001" => DATA <= "010100101111";						--  1   0  0  1	    +									  -
			WHEN "1010" => DATA <= "010101001111";						--  1   0  1  0			  +							  -
			WHEN "1011" => DATA <= "010101101111";						--  1   0  1  1				   +						  -
			WHEN "1100" => DATA <= "010110001111";						--  1   1  0  0						 +					  - 
			WHEN "1101" => DATA <= "010110101111";						--  1   1  0  1							  +			  -		
			WHEN "1110" => DATA <= "010111001111";						--  1   1  1  0									+	     -
			WHEN "1111" => DATA <= "010111101111";						--  1   1  1  1                               +   -
			WHEN OTHERS => NULL;
		END CASE;
END PROCESS ADC_DATA;
--------------------------------------------------------------------   -- GENERATE SDA/SCL_CLOCK FOR STANDARD MODE 100kHZ
SDA_CLOCK: PROCESS(CLK)
	VARIABLE Count: INTEGER RANGE 0 TO 1000 :=0;
	BEGIN
		IF(RISING_EDGE(CLK)) THEN
			SDA_CLK_PRV <= SDA_CLK;
			IF(Count=999) THEN 
				Count :=0;
			Else
				Count := Count+1;
			END IF;
			CASE Count IS
				WHEN 0   TO 249 => SCL_CLK <= '0' ; SDA_CLK<= '0';
				WHEN 250 TO 499 => SCL_CLK <= '0' ; SDA_CLK<= '1';
				WHEN 500 TO 749 => SCL_CLK <= '1' ; SDA_CLK<= '1';
				WHEN OTHERS     => SCL_CLK <= '1' ; SDA_CLK<= '0';
			END CASE;
		END IF;
END PROCESS SDA_CLOCK;

--------------------------------------------------------------------  -- MAIN PROCESS OF I2C
MAIN: PROCESS(CLK)
VARIABLE ADDRESS_CNT : INTEGER  RANGE -1 TO 7  := 7;									 -- ADDRESS COUNTER
VARIABLE DATA_CNT    : INTEGER  RANGE -1 TO 11 := 11;								    -- DATA    COUNTER
VARIABLE ZERO_CNT    : INTEGER  RANGE -1 TO 3  := 3;								    -- ZERO    COUNTER
VARIABLE DIN_CNT     : INTEGER  RANGE -1 TO 7  := 7;									 -- DIN     COUNTER

BEGIN
IF(RW='1') THEN
	IF(ENABLE='0') THEN 
		SCL <='1';
	ELSIF(FALLING_EDGE(CLK)) THEN  															 -- WHEN LTC2309 CALLED BY MASTER
	   SCL <= SCL_CLK;
		--
		IF(BUSS='0' AND ENABLE='1') THEN
			SCL<='1';
		END IF;
		--
		--
		IF(((SDA_CLK='0' AND SDA_CLK_PRV='1') AND SCL_CLK='1') AND BUSS='0') THEN-- START CONDITION AND BUS GETS BUSY	 												 
			SDA         <= '0';
			ADDRESS_CNT :=  7 ;
			--
			DATA_READY  <= '0';														          -- THESE ARE FLAGS MUST TO GET RESET VALUE
			SLV_ACK     <= '0';														          -- THIS BRANCH APPLYS ON BEGINING OF START
			MAS_ACK     <= '0';
			MAS_NACK    <= '0';
			STOP        <= '0';
			BUSS   		<= '1';
		END IF;
		--
		IF((SDA_CLK='1' AND SDA_CLK_PRV='0') AND SCL_CLK='0' AND BUSS='1') THEN  -- ADDRESS SET ON RISING EDGE OF SDA_CLK AND SCL='0'  
			IF(ADDRESS_CNT >= 0) THEN												 			 -- ADDRESS SET IN SDA IN 7 CYCLES
				SDA <= ADDRESS(ADDRESS_CNT);
				ADDRESS_CNT := ADDRESS_CNT-1;
			ELSIF(ADDRESS_CNT < 0 AND SLV_ACK='0') THEN						          -- SLAVE_ACK (BYTE RECEIVED) 
				SDA     <= '0';
				SLV_ACK <= '1';
			END IF;											
			--
			IF(SLV_ACK = '1' AND DATA_READY = '0') THEN     				 			 -- SLAVE IS READY TO TRANSFER DATA
				DATA_READY <= '1';
				--																			 			 -- THIS BRANCH APPLYS BEFORE DATA TRANSFER
				DATA_CNT   := 11 ;																 -- THIS COUNTER MUST GET RESET VALUE 
			END IF;
			-----------------
			IF(DATA_READY='1' AND RW='1') THEN												 -- READ OPERATION
				ONCE_SLV_ACK <='1';
				--t conv
				--
				IF(DATA_CNT >=4) THEN	    													 -- 8BITS MSB DATA READING
					SDA      <= DATA(DATA_CNT);									
					DATA_CNT := DATA_CNT -1; 
				ELSIF((DATA_CNT <4 AND DATA_CNT>=0) AND MAS_ACK='0') THEN 			 -- MAS_ACK (MSB BYTE RECEIVED)
					SDA      <= '0';
					MAS_ACK  <= '1';
				END IF;
				IF(MAS_ACK='1' AND NIBBLE_READY='0') THEN
					ZERO_CNT     :=  3 ;
					NIBBLE_READY <= '1';
				END IF;
				--
				IF(DATA_CNT >=0 AND NIBBLE_READY='1') THEN					 			 -- 4BITS LBS DATA READING	
					ONCE_MAS_ACK <= '1';
					--
					SDA      <= DATA(DATA_CNT);
					DATA_CNT := DATA_CNT -1;
				--
				ELSIF(DATA_CNT < 0 AND ZERO_CNT >= 0) THEN					 			 -- 4BITS ZEROZS DATA READING
					SDA      <= '0';													 			 -- DON'T CARE NIBBLE FOR ADC
					ZERO_CNT := ZERO_CNT -1;
				ELSIF(DATA_CNT < 0 AND ZERO_CNT <0 AND MAS_NACK='0') THEN 			 -- MAS_NACK (LSB BYTE RECEIVED)
					SDA      <= '1';
					MAS_NACK <= '1';
				END IF;
				--
				IF(MAS_NACK='1' AND STOP='0') THEN 							    			 -- TRANSFER COMPLETE
				   STOP     <= '1';
					SDA      <= '0';
				END IF;
				--
				IF((SDA_CLK='1' AND SDA_CLK_PRV='0') AND SCL_CLK='0' AND STOP='1') THEN
					SCL  <= '1';
					ONCE_MAS_NACK <='1';
				END IF;	
			--
			END IF;
			--
		END IF;
			IF((SLV_ACK='1'    AND DATA_READY='1'  ) AND ONCE_SLV_ACK='0' ) THEN SCL <= '0'; END IF;
			IF((MAS_ACK='1'    AND NIBBLE_READY='1') AND ONCE_MAS_ACK='0' ) THEN SCL <= '0'; END IF;
		   IF(((MAS_NACK='1') AND STOP = '1'      ) AND ONCE_MAS_NACK='0') THEN SCL <= '1'; END IF;
	END IF;
	IF ONCE_MAS_NACK='1' THEN BUSS <= '0'; SDA<='1'; END IF;
END IF;
---------------------------------------------------------------------------------
IF(RW='0') THEN
	IF(ENABLE='0') THEN 
		SCL <='1';
	ELSIF(FALLING_EDGE(CLK)) THEN  															 -- WHEN LTC2309 CALLED BY MASTER
	   SCL <= SCL_CLK;
		--
		IF(BUSS='0' AND ENABLE='1') THEN
			SCL<='1';
		END IF;
		--
		--
		IF(((SDA_CLK='0' AND SDA_CLK_PRV='1') AND SCL_CLK='1') AND BUSS='0') THEN-- START CONDITION AND BUS GETS BUSY	 												 
			SDA         <= '0';
			ADDRESS_CNT :=  6;
			--
			DATA_READY  <= '0';														          -- THESE ARE FLAGS MUST TO GET RESET VALUE
			SLV_ACK     <= '0';														          -- THIS BRANCH APPLYS ON BEGINING OF START
			MAS_ACK     <= '0';
			MAS_NACK    <= '0';
			DIN_REC     <= '0';
			STOP        <= '0';
			BUSS   		<= '1';
		END IF;
		--
		IF((SDA_CLK='1' AND SDA_CLK_PRV='0') AND SCL_CLK='0' AND BUSS='1') THEN  -- ADDRESS SET ON RISING EDGE OF SDA_CLK AND SCL='0'  
			IF(ADDRESS_CNT >= 0) THEN												 			 -- ADDRESS SET IN SDA IN 7 CYCLES
            IF(SDA ='X' OR SDA='1') THEN 
				ADDRESS(ADDRESS_CNT)<= '1';
				ELSIF(SDA ='0') THEN
				ADDRESS(ADDRESS_CNT)<= '0';
				END IF;
				ADDRESS_CNT := ADDRESS_CNT-1;
			ELSIF(ADDRESS_CNT < 0 AND SLV_ACK='0') THEN						          -- SLAVE_ACK (BYTE RECEIVED) 
				SDA     <= '0';
				SLV_ACK <= '1';
			END IF;											
			--
			IF(SLV_ACK = '1' AND DATA_READY = '0') THEN     				 			 -- SLAVE IS READY TO TRANSFER DATA
				DATA_READY <= '1';
				--																			 			 -- THIS BRANCH APPLYS BEFORE DATA TRANSFER
				DATA_CNT   := 11 ;																 -- THIS COUNTER MUST GET RESET VALUE 
			END IF;
			------------
			IF(DATA_READY='1' AND RW='0') THEN									          -- WRITE OPERATION
				ONCE_SLV_ACK <= '1';
				DIN_CNT      :=  7 ;
				IF(DIN_CNT>=0) THEN
					IF(DIN_CNT>=2) THEN
						IF(SDA ='X' OR SDA='1') THEN 
							DIN(DIN_CNT-2)<= '1';
						ELSIF(SDA ='0') THEN
							DIN(DIN_CNT-2)<= '0';
						END IF;
					END IF;
					DIN_CNT := DIN_CNT-1;
				ELSIF(DIN_CNT<0 AND SLV_ACK='1' AND DIN_REC='0') THEN
					DIN_REC <= '1';
					SDA <= '0';
				END IF;
				-------------------------------------------------------- -- ADC DATA IS SELECTIVE BY DIN (S/D,O/S,S1,S0)
				--NOTE: ADC DIDN'T SIMULATE IN THIS PROJECT AND JUST SET DEFAULT DATA FOR EVERY DIN SELECTION				
				IF (DIN_CNT <0) THEN
					TEMP1 <= DIN(5 DOWNTO 2);
					CASE TEMP1 IS										               -- S/D O/S S1 S0 CH0 CH1 CH2 CH3 CH4 CH5 CH6 CH7 COM
						WHEN "0000" => DAT <= "010000001111";	    	   		--  0   0  0  0   +   - 
						WHEN "0001" => DAT <= "010000101111";						--  0   0  0  1  		     +   - 
						WHEN "0010" => DAT <= "010001001111";	        			--  0   0  1  0		             +   - 
						WHEN "0011" => DAT <= "010001101111";						--  0   0  1  1			  		            +   - 
						WHEN "0100" => DAT <= "010010001111";						--  0   1  0  0	-   + 
						WHEN "0101" => DAT <= "010010101111";						--  0   1  0  1			  -   + 
						WHEN "0110" => DAT <= "010011001111";						--  0   1  1  0 	      			 -   + 
						WHEN "0111" => DAT <= "010011101111";						--  0   1  1  1									-   +
						WHEN "1000" => DAT <= "010100001111";						--  1   0  0  0   +                               -
						WHEN "1001" => DAT <= "010100101111";						--  1   0  0  1	    +									  -
						WHEN "1010" => DAT <= "010101001111";						--  1   0  1  0			  +							  -
						WHEN "1011" => DAT <= "010101101111";						--  1   0  1  1				   +						  -
						WHEN "1100" => DAT <= "010110001111";						--  1   1  0  0						 +					  - 
						WHEN "1101" => DAT <= "010110101111";						--  1   1  0  1							  +			  -		
						WHEN "1110" => DAT <= "010111001111";						--  1   1  1  0									+	     -
						WHEN "1111" => DAT <= "010111101111";						--  1   1  1  1                               +   -
						WHEN OTHERS => NULL;
					END CASE;
				END IF;
				--
				IF(DIN(1)='0') THEN 													   --BIPOLAR
				DATA <= NOT(DAT(11)) & DAT(10 DOWNTO 0);
				ELSE DATA<= DAT;
				END IF;
				--
			END IF;
		END IF;
	END IF;
IF((SLV_ACK='1'    AND DATA_READY='1'  ) AND ONCE_SLV_ACK='0' ) THEN SCL <= '0'; END IF;
IF((SLV_ACK='1'    AND DIN_REC   ='1'  ) AND ONCE_SLV_ACK='1' ) THEN SCL <= '1'; END IF;
END IF;
	
--
END PROCESS MAIN;
--
END Behavioral;

			
			
