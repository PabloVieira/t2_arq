LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.aux_functions.all;
 
ENTITY tb_t2 IS
END tb_t2;
 
ARCHITECTURE behavior OF tb_t2 IS 
signal ck, rst: std_logic;
signal A2B, B2A: reg8;
BEGIN
 
		rst <= '1', '0' after 5 ns;		-- generates the reset signal

	process						-- generates the clock signal
	begin
		ck <= '1', '0' after 5 ns;
		wait for 10 ns;
	end process;
	
SisA: Entity work.SisA port map(ck => ck, rst => rst, TX => A2B, RX => B2A);	

SisB: Entity work.SisB port map(ck => ck, rst => rst, TX => B2A, RX => A2B);

END;
