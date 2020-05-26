library IEEE;
use IEEE.std_logic_1164.all;

package aux_functions is

	subtype reg32 is std_logic_vector(31 downto 0);
	subtype reg16 is std_logic_vector(15 downto 0);
	subtype reg8 is std_logic_vector(7 downto 0);
	subtype reg4 is std_logic_vector(3 downto 0);

	-- definio do tipo 'memory', que ser utilizado para as memrias de dados/instrues
	constant MEMORY_SIZE: integer:= 2048;
	type memory is array (0 to MEMORY_SIZE) of reg8;
	constant TAM_LINHA: integer:= 200;
	function CONV_VECTOR(letra: string(1 to TAM_LINHA); pos: integer) return std_logic_vector;

end aux_functions;

package body aux_functions is

	--
	-- converte um caracter de uma dada linha em um std_logic_vector
	--
	function CONV_VECTOR(letra:string(1 to TAM_LINHA);  pos: integer) return std_logic_vector is
		variable bin: reg4;
	begin
		case (letra(pos)) is
				when '0' => bin:= "0000";
				when '1' => bin:= "0001";
				when '2' => bin:= "0010";
				when '3' => bin:= "0011";
				when '4' => bin:= "0100";
				when '5' => bin:= "0101";
				when '6' => bin:= "0110";
				when '7' => bin:= "0111";
				when '8' => bin:= "1000";
				when '9' => bin:= "1001";
				when 'A' | 'a' => bin:= "1010";
				when 'B' | 'b' => bin:= "1011";
				when 'C' | 'c' => bin:= "1100";
				when 'D' | 'd' => bin:= "1101";
				when 'E' | 'e' => bin:= "1110";
				when 'F' | 'f' => bin:= "1111";
				when others =>  bin:= "0000";
		end case;
	return bin;
	end CONV_VECTOR;

end aux_functions;

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