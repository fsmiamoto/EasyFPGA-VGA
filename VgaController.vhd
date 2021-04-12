-- Basic VGA Controller for the RZ EasyFPGA A2.2 board
-- Ported from Verilog using the example provided by the manufacturer.
-- Author: Francisco Miamoto

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VgaController is
  port (
    clk   : in std_logic; -- Pin 23, the clock provided by the board is 50Mhz
    rgb   : out std_logic_vector (2 downto 0); -- Pins 106,105 and 104
    hsync : out std_logic; -- Pin 101
    vsync : out std_logic -- Pin 103
  );
end VgaController;

architecture rtl of VgaController is
  constant WHITE  : std_logic_vector := "111";
  constant YELLOW : std_logic_vector := "110";
  constant PURPLE : std_logic_vector := "101";
  constant RED    : std_logic_vector := "100";
  constant WATER  : std_logic_vector := "011";
  constant GREEN  : std_logic_vector := "010";
  constant BLUE   : std_logic_vector := "001";
  constant BLACK  : std_logic_vector := "000";

  constant HSYNC_END  : integer := 95;
  constant HDAT_BEGIN : integer := 143;
  constant HDAT_END   : integer := 783;
  constant HLINE_END  : integer := 799;
  constant VSYNC_END  : integer := 1;
  constant VDAT_BEGIN : integer := 34;
  constant VDAT_END   : integer := 514;
  constant VLINE_END  : integer := 524;

  signal hcount         : integer := 0;
  signal vcount         : integer := 0;
  signal vcount_ov      : boolean;
  signal hcount_ov      : boolean;
  signal data           : std_logic_vector (2 downto 0);
  signal is_data_active : boolean;
  signal vga_clk        : std_logic := '0';

begin
  vcount_ov      <= vcount = VLINE_END;
  hcount_ov      <= hcount = HLINE_END;
  is_data_active <= (hcount >= HDAT_BEGIN) and (hcount < HDAT_END) and (vcount >= VDAT_BEGIN) and (vcount < VDAT_END);

  -- Outputs
  hsync <= '1' when hcount > HSYNC_END else '0';
  vsync <= '1' when vcount > VSYNC_END else '0';
  rgb   <= data when is_data_active else (others => '0');

  -- We need 25MHz for the VGA so we divide the input clock by 2
  process (clk)
  begin
    if (rising_edge(clk)) then
      vga_clk <= not vga_clk;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (hcount_ov) then
        hcount <= 0;
      else
        hcount <= hcount + 1;
      end if;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk) and hcount_ov) then
      if (vcount_ov) then
        vcount <= 0;
      else
        vcount <= vcount + 1;
      end if;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (hcount < 223) then
        data <= WHITE;
      elsif (hcount < 303) then
        data <= YELLOW;
      elsif (hcount < 383) then
        data <= BLUE;
      elsif (hcount < 463) then
        data <= GREEN;
      elsif (hcount < 543) then
        data <= PURPLE;
      elsif (hcount < 623) then
        data <= RED;
      elsif (hcount < 703) then
        data <= WATER;
      else
        data <= BLACK;
      end if;
    end if;
  end process;
end architecture;