library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.p_MR2.all;


entity RW is 
    port(
        clk, rst        :   in  					std_logic;
        ce              :   in  					std_logic;
        done            :   out 					std_logic;
        ack             :   in  					std_logic;
        send            :   out 					std_logic;
        ackFromCPU      :   in  					std_logic;
        data_in         :   in   std_logic_vector(7 downto 0);
        data_out        :   out  std_logic_vector(7 downto 0)
    );
end RW;
architecture main of RW is
	signal busy 	: 	std_logic := '0';
begin

    process(clk,rst,ce)
    begin
        if (rst = '1') then
            done    <=        '0';
            send    <=        '0';
        elsif (clk'event and clk ='1') then
            if (ce = '1' OR busy= '1') then
                if (ack ='0' and busy = '0') then
                    data_out    <=         data_in;
                    send        <=             '1';
                    busy        <=             '1';
                elsif (ack ='1') then
                    done     	<=             '1';
                    send     	<=             '0';
                    data_out 	<=      "ZZZZZZZZ";
                end if;
            end if;
            if ackFromCPU ='1' then
                done            <=             '0';
                busy            <=             '0';
            end if ;
        end if ;
    end process;
end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity RWO is
	port(
            clk, rst        :   in  				   std_logic;
            ce              :   in  				   std_logic;
            done            :   out 				   std_logic;
            ack             :   in  				   std_logic;
            send            :   out 				   std_logic;
            data_in         :   in  std_logic_vector(7 downto 0);
            data_out        :   out std_logic_vector(7 downto 0)
		);
end RWO;
architecture main of RWO is  
    signal busy : std_logic := '0';
begin
    process(clk, rst,ce)
    begin
        if (rst = '1') then
            done    <=        '0';
            send    <=        '0';
            busy    <=        '0';
        elsif clk'event and clk ='1' then
            if ce = '1' OR busy= '1' then
                if ack ='0' and busy = '0' then
                    data_out    <=      data_in;
                    send        <=          '1';
                    done        <=          '1';
                    busy        <=          '1';
                elsif ack ='1'then
                    send     <=          '0';
                    data_out <=   "ZZZZZZZZ";
                    busy     <=          '0';
                end if;
            end if;
            if ce ='0' then
                done <= '0';
            end if ;
        end if ;
    end process;
end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity RRI is
	port(
            clk, rst        :   in  				   std_logic;
            ce              :   in  				   std_logic;
            done            :   out 				   std_logic;
            ack             :   in  				   std_logic;
            send            :   out 				   std_logic;
            data_in         :   in  std_logic_vector(7 downto 0);
            data_out        :   out std_logic_vector(7 downto 0)
		);
end RRI;
architecture main of RRI is  
    signal busy : std_logic := '0';
begin
    process(clk, rst,ce)
    begin
        if (rst = '1') then
            done    <=        '0';
            send    <=        '0';
            busy    <=        '0';
        elsif clk'event and clk ='1' then
            if ce = '1' OR busy= '1' then
                if ack ='0' and busy = '0' then
                    data_out    <=      data_in;
                    send        <=          '1';
                    done        <=          '1';
                    busy        <=          '1';
                elsif ack ='1'then
                    send     <=          '0';
                    data_out <=   "ZZZZZZZZ";
                    busy     <=          '0';
                end if;
            end if;
            if ce ='0' then
                done <= '0';
            end if ;
        end if ;
    end process;
end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity RR is 
    port(
        clk, rst        :   in  				   std_logic;
        ce              :   in  				   std_logic;
        done            :   out 				   std_logic;
        ack             :   in  				   std_logic;
        send            :   out 				   std_logic;
        data_in         :   in  std_logic_vector(7 downto 0);
        data_out        :   out std_logic_vector(7 downto 0)
    );
end RR;
architecture main of RR is
	signal busy 	: 	std_logic := '0';
begin

    process(clk,rst,ce)
    begin
        if (rst = '1') then
            done    <=        '0';
            send    <=        '0';
        elsif clk'event and clk ='1' then
            if ce = '1' OR busy= '1' then
                if ack ='0' and busy = '0' then
                    data_out    <=      data_in;
                    send        <=          '1';
                    busy        <=          '1';
                elsif ack ='1'then
                    done        <=          '1';
                    send        <=          '0';
                    data_out    <=   "ZZZZZZZZ";
                    busy        <=          '0';
                end if;
            end if;
        end if ;
    end process;
end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity UART_SYNC_PARALLEL is 
    port(
        clk, rst        :       in     std_logic;
		rw, ce          :       in     std_logic; 

        INTA            :       in     std_logic;
        INTR            :       out    std_logic;
		
        TX              :       out    std_logic_vector(7 downto 0);
        sendTx          :       out    std_logic;
        ackTX           :       in     std_logic;
				 
        RX              :       in     std_logic_vector(7 downto 0);
        ceRX            :       in     std_logic;
        doneRX          :       out    std_logic;

        add             :       in    std_logic_vector(3 downto 0);
        
		data            :       inout std_logic_vector(7 downto 0)
    );
end entity UART_SYNC_PARALLEL;
architecture main of UART_SYNC_PARALLEL is 
    -- SINAIS DA INTERFACE RW   |  UART
    signal INTR_RW      :       std_logic := '0';
    signal INTA_RW      :       std_logic := '0';

    -- SINAIS DA INTERFACE RW 
    signal ce_rw        :       std_logic := '0';
    --signal rw_busy      :       std_logic := '0';

    -- SINAIS DA INTERFACE RW   |  RWO
    signal data2RWO     :       std_logic_vector(7 downto 0);--  :=(others=>"ZZZZZZZ");
    signal ce_rwo       :       std_logic := '0'; 
    signal doneRWO      :       std_logic := '0';
    
    -- SINAIS DA INTERFACE RRI  |  RR
    signal data2RR      :       std_logic_vector(7 downto 0);--  :=(others=>"ZZZZZZZ");
    signal send2RR      :       std_logic := '0';
    signal doneRR       :       std_logic := '0';

    -- SINAIS DA INTERFACE RR  |  UART
    signal INTR_RR      :       std_logic := '0';
    signal INTA_RR      :       std_logic := '0';
    signal data_outRR   :       std_logic_vector(7 downto 0);
	signal ce_rr			:		  std_logic;

    -- SINAIS DA INTERFACE UART
    signal reg_base     :       std_logic_vector(7 downto 0) := "00000000"; 
    signal INTR_AUX     :       std_logic := '0';
    signal int_busy     :       std_logic := '0';
	 signal ce_base      :       std_logic := '0';

begin
                        
    -- CHIP ENABLE
    ce_rw     <= '1' when (add="0100")  and (rw ='1') and (ce='1')       else '0';
    ce_rr     <= '1' when (add="1000")  and (rw ='0') and (ce='1')       else '0';
	ce_base   <= '1' when (add="0000")  and (ce='1')  and (INTR_AUX='1') else '0';
   

    -- CONTROLE DA PORTA DATA:
    data <= data_outRR when ce_rr ='1' else reg_base when ce_base='1' else "ZZZZZZZZ";
    
    -- CONTROLE DE INTERRUPÇÃO:
    INTR_AUX <= INTR_RR OR INTR_RW;
    INTR <= INTR_AUX and int_busy;
    
    process(clk,rst)
    begin
        if rst ='1' then
            TX      <=      "ZZZZZZZZ";
        elsif clk'event and clk ='1' then
            if    INTR_RR = '1'  and int_busy = '0' then
                int_busy        <='1';
                reg_base      <=x"01";
            elsif INTR_RW ='1' and int_busy = '0'then
                int_busy        <='1';
                reg_base       <=x"00";
            end if ;
             if INTA ='1' then
                if reg_base = x"01" then
                    INTA_RR <='1';
                elsif reg_base= x"00" then
                    INTA_RW <='1';
                end if ;
            elsif INTA ='0' then 
                INTA_RR <='0';
                INTA_RW <='0';
            end if ;
            
        end if;  
    end process;

    RW_UART: entity work.RW port map(
        clk         =>      clk,
        rst         =>      rst,
        ce          =>      ce_rw,
        data_in     =>      data,
        data_out    =>      data2RWO,
        done        =>      INTR_RW,
        send        =>      ce_rwo,
        ack         =>      doneRWO,
        ackFromCPU  =>      INTA_RW
    );

    RWO_UART: entity work.RWO port map(
        clk         =>      clk,
        rst         =>      rst,
        ce          =>      ce_rwo,
        data_in     =>      data2RWO,
        data_out    =>      TX,
        done        =>      doneRWO,
        send        =>      sendTX,
        ack         =>      ackTX
    );

    RRI_UART: entity work.RRI port map(
        clk         =>      clk,
        rst         =>      rst,
        ce          =>      ceRX,
        data_in     =>      RX,
        data_out    =>      data2RR,
        done        =>      doneRX,
        send        =>      send2RR,
        ack         =>      doneRR
    );

    RR_UART: entity work.RR port map(
        clk         =>      clk,
        rst         =>      rst,
        ce          =>      send2RR,
        data_in     =>      data2RR,
        data_out    =>      data_outRR,
        done        =>      doneRR,
        send        =>      INTR_RR,
        ack         =>      INTA_RR
    );

end architecture main;