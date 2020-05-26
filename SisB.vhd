-------------------------------------------------------------------------
--
-- 32 bits PROCESSOR TESTBENCH - LITTLE  ENDIAN
--
-- It must be observed that the processor is hold in reset
-- (rstCPU <= '1') at the start of simulation, being activated
-- (rstCPU <= '0') just after the end of the object file reading be the
-- testbench.
--
-- This testbench employs two memories implying a HARVARD organization
--
-------------------------------------------------------------------------

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
	

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use STD.TEXTIO.all;
use work.aux_functions.all;

entity SisB is
	port(
		ck: in std_logic;
		rst: in std_logic;
		sendIN: in std_logic;
		send: out std_logic;
		ack: in std_logic;
		ackOUT: out std_logic;
		RX: in reg8;
		TX: out reg8
	);
end SisB;

architecture SisB of SisB is

	signal Dadress, Ddata, Iadress, Idata,
			i_cpu_address, d_cpu_address, data_cpu, tb_add, tb_data: reg32:= (others => '0');
	signal Dce_n, Dwe_n, Doe_n, Ice_n, Iwe_n, Ioe_n, rstCPU,
			go_i, go_d, rw, bw: std_logic;
	signal ce: std_logic_vector(16 downto 0);
	signal intr, inta: std_logic;

	signal stx: std_logic;

	signal tx_ack: std_logic_vector(3 downto 1);
	signal external_data16: reg16;
	signal external_data: reg32;

	file ARQ: TEXT open READ_MODE is "startB.txt";

begin

	Data_mem: entity work.RAM_mem generic map(START_ADDRESS => x"10010000") port map(ce_n => Dce_n, we_n => Dwe_n, oe_n => Doe_n, bw => bw, address => Dadress, data => Ddata);

	Instr_mem: entity work.RAM_mem generic map(START_ADDRESS => x"00400000") port map(ce_n => Ice_n, we_n => Iwe_n, oe_n => Ioe_n, bw => '1', address => Iadress, data => Idata);

	-- data memory signals --------------------------------------------------------
	Dce_n    <= '0' when ce(16)='1' or go_d='1' else '1';
	Doe_n    <= '0' when ce(16)='1' and rw='1' else '1';
	Dwe_n    <= '0' when (ce(16)='1' and rw='0') or go_d='1' else '1';
	Dadress  <= tb_add  when rstCPU='1' else d_cpu_address;
	Ddata	 <= tb_data when rstCPU='1' else data_cpu when (ce(16)='1' and rw='0') else (others => 'Z');
	data_cpu <= Ddata when ce(16)='1' and rw='1' else (others => 'Z');

	-- instructions memory signals --------------------------------------------------------
	Ice_n   <= '0';
	Ioe_n   <= '1' when rstCPU='1' else '0';			-- impede leitura enquanto est escrevendo
	Iwe_n   <= '0' when go_i='1'	else '1';			-- escrita durante a leitura do arquivo
	Iadress <= tb_add  when rstCPU='1' else i_cpu_address;
	Idata   <= tb_data when rstCPU='1' else (others => 'Z');

	----------------------------------------------------------------------------
	-- this process loads the instruction memory and the data memory during reset
	--
	--
	--	O PROCESSO ABAIXO  UMA PARSER PARA LER CDIGO GERADO PELO MARS NO
	--	SEGUINTE FORMATO:
	--
	--		.CODE
	--		0x00400000  0x08100022  j 0x00400088          7            j MyMain
	--		0x00400004  0x3c010000  lui $1,0x0000         12           subu $sp, $sp, 4
	--		0x00400008  0x34210004  ori $1,$1,0x0004           
	--		0x0040000c  0x03a1e823  subu $29,$29,$1            
	--		...
	--		0x0040009c  0x01285021  addu $10,$9,$8        65           addu $t2, $t1, $t0
	--		0x004000a0  0x08100025  j 0x00400094          66           j SaltoMyMain
	--
	--		.DATA
	--		0x10010000	0x0000faaa  0x00000083  0x00000000  0x00000000
	--
	----------------------------------------------------------------------------
	process
		variable ARQ_LINE: LINE;
		variable line_arq: string(1 to 200);
		variable code	: boolean;
		variable i, address_flag: integer;
	begin
		go_i <= '0';
		go_d <= '0';
		rstCPU <= '1';			-- hold the processor during file reading
		code:=true;				-- default value of code is 1 (CODE)

		wait until rst = '1';

		while NOT (endfile(ARQ)) loop	-- INCIO DA LEITURA DO ARQUIVO CONTENDO INSTRUO E DADOS -----
			readline(ARQ, ARQ_LINE);
			read(ARQ_LINE, line_arq(1 to  ARQ_LINE'length));

			if line_arq(1 to 5)=".CODE" then code := true;							-- code
			elsif line_arq(1 to 5)=".DATA" then code := false;						-- data
			else
				i := 1;								-- LEITORA DE LINHA - analizar o loop abaixo para compreender
				address_flag := 0;					-- para INSTRUO  um para (end,inst)
													-- para DADO aceita (end, dado 0, dado 1, dado 2 ....)
				loop
					if line_arq(i) = '0' and line_arq(i+1) = 'x' then	-- encontrou indicao de nmero hexa: '0x'
						i:= i + 2;
						if address_flag=0 then
							for w in 0 to 7 loop
								tb_add((31-w*4) downto (32-(w+1)*4))  <= CONV_VECTOR(line_arq,i+w);
							end loop;
							i:= i + 8;
							address_flag:= 1;
						else
							for w in 0 to 7 loop
								tb_data((31-w*4) downto (32-(w+1)*4))  <= CONV_VECTOR(line_arq,i+w);
							end loop;
							i:= i + 8;
							wait for 0.1 ns;
							if code=true then go_i <= '1';	-- the go_i signal enables instruction memory writing
											else go_d <= '1';	-- the go_d signal enables data memory writing
							end if;
							wait for 0.1 ns;
							tb_add <= tb_add + 4;		-- *great!* consigo ler mais de uma word por linha!
							go_i <= '0';
							go_d <= '0';
							address_flag:= 2;	-- sinaliza que j leu o contedo do endereo;
						end if;
					end if;
					i:= i + 1;
					-- sai da linha quando chegou no seu final OU j leu par(endereo, instruo) no caso de cdigo
					exit when i=TAM_LINHA or (code=true and address_flag=2);
				end loop;
			end if;
		end loop;								-- FINAL DA LEITURA DO ARQUIVO CONTENDO INSTRUO E DADOS -----
		rstCPU <= '0';	-- release the processor to execute
		wait for 2 ns;	-- To activate the RST CPU signal
		wait until rst = '1';  -- to Hold again!
	end process;

	-- Port map dos subsitemas ------------------------------------------------------------
	---------------------------------------------------------------------------------------
	CPU: Entity work.MR2 port map
		(clock => ck, reset => rstCPU, i_address => i_cpu_address, instruction => Idata,
		ce => ce, rw => rw, bw => bw, d_address => d_cpu_address, data => data_cpu,
		intr => intr, inta => inta);

	SisCom: Entity work.UART_SYNC_PARALLEL port map
			(rst => rst, clk => ck, ce => ce(0), rw => rw , inta => inta, intr => intr,
			add => d_cpu_address, data => data_cpu, ackIN => ack, RX => RX
			);

end SisB;
