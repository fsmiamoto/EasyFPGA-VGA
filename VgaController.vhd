-- Basic VGA Controller for the RZ EasyFPGA A2.2 board
-- Ported from Verilog using the example provided by the manufacturer.
-- Author: Francisco Miamoto

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.VgaUtils.all;

entity VgaController is
  port (
    clk     : in std_logic;
    rgb_in  : in std_logic_vector (2 downto 0);
    rgb_out : out std_logic_vector (2 downto 0);
    hsync   : out std_logic;
    vsync   : out std_logic;
    hpos    : out integer;
    vpos    : out integer
  );
end VgaController;

architecture rtl of VgaController is
  signal hcount : integer range 0 to HLINE_END := 0;
  signal vcount : integer range 0 to VLINE_END := 0;

  signal should_reset_vcount : boolean;
  signal should_reset_hcount : boolean;
  signal should_output_data  : boolean;

begin
  should_reset_vcount <= vcount = VLINE_END;
  should_reset_hcount <= hcount = HLINE_END;
  should_output_data  <= (hcount >= HDATA_BEGIN) and (hcount < HDATA_END) and (vcount >= VDATA_BEGIN) and (vcount < VDATA_END);

  hsync   <= '1' when hcount > HSYNC_END else '0';
  vsync   <= '1' when vcount > VSYNC_END else '0';
  rgb_out <= rgb_in when should_output_data else (others => '0');
  hpos    <= hcount;
  vpos    <= vcount;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (should_reset_hcount) then
        hcount <= 0;
      else
        hcount <= hcount + 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk) and should_reset_hcount) then
      if (should_reset_vcount) then
        vcount <= 0;
      else
        vcount <= vcount + 1;
      end if;
    end if;
  end process;
end architecture;