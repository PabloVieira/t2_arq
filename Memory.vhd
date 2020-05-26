--------------------------------------------------------------------------
-- Module implementing a behavioral model of an ASYNCHRONOUS INTERFACE RAM
--------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_UNSIGNED.all;
use work.aux_functions.all;

entity RAM_mem is
	generic
	(
		START_ADDRESS: reg32:= (others => '0')
	);
	port
	(
		ce_n, we_n, oe_n, bw: in std_logic;
		address: in reg32;
		data: inout reg32
	);
end RAM_mem;

architecture RAM_mem of RAM_mem is
	signal RAM: memory;
	signal tmp_address: reg32;
	alias low_address: reg16 is tmp_address(15 downto 0);	--  baixa para 16 bits devido ao CONV_INTEGER --
begin

	tmp_address <= address - START_ADDRESS;	--  offset do endereamento  --

	-- writes in memory ASYNCHRONOUSLY  -- LITTLE ENDIAN -------------------
	process(ce_n, we_n, low_address)
	begin
		if ce_n='0' and we_n='0' then
			if CONV_INTEGER(low_address)>=0 and CONV_INTEGER(low_address+3) <= MEMORY_SIZE then
				if bw='1' then
					RAM(CONV_INTEGER(low_address+3)) <= data(31 downto 24);
					RAM(CONV_INTEGER(low_address+2)) <= data(23 downto 16);
					RAM(CONV_INTEGER(low_address+1)) <= data(15 downto  8);
				end if;
				RAM(CONV_INTEGER(low_address )) <= data(7 downto  0);
			end if;
		end if;
	end process;

	-- read from memory
	process(ce_n, oe_n, low_address)
	begin
		if ce_n='0' and oe_n='0' and CONV_INTEGER(low_address)>=0 and CONV_INTEGER(low_address+3) <= MEMORY_SIZE then
			data(31 downto 24) <= RAM(CONV_INTEGER(low_address+3));
			data(23 downto 16) <= RAM(CONV_INTEGER(low_address+2));
			data(15 downto  8) <= RAM(CONV_INTEGER(low_address+1));
			data(7 downto  0) <= RAM(CONV_INTEGER(low_address ));
		else
			data(31 downto 24) <= (others => 'Z');
			data(23 downto 16) <= (others => 'Z');
			data(15 downto  8) <= (others => 'Z');
			data(7 downto  0) <= (others => 'Z');
		end if;
	end process;

end RAM_mem;