-- Basic VGA Controller for the RZ EasyFPGA A2.2 board
-- Ported from Verilog using the example provided by the manufacturer.
-- Author: Francisco Miamoto

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_utils.all;

entity VgaController is
  port (
    clk   : in std_logic; -- Pin 23, the clock provided by the board is 50Mhz
    rgb   : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync : out std_logic; -- Pin 101
    vsync : out std_logic -- Pin 103
  );
end VgaController;

architecture rtl of VgaController is
  constant COLOR_WHITE  : std_logic_vector := "111";
  constant COLOR_YELLOW : std_logic_vector := "110";
  constant COLOR_PURPLE : std_logic_vector := "101";
  constant COLOR_RED    : std_logic_vector := "100";
  constant COLOR_WATER  : std_logic_vector := "011";
  constant COLOR_GREEN  : std_logic_vector := "010";
  constant COLOR_BLUE   : std_logic_vector := "001";
  constant COLOR_BLACK  : std_logic_vector := "000";

  -- Values for 640x480 resolution
  constant HSYNC_END   : integer := 95;
  constant HDATA_BEGIN : integer := 143;
  constant HDATA_END   : integer := 783;
  constant HLINE_END   : integer := 799;

  constant VSYNC_END   : integer := 1;
  constant VDATA_BEGIN : integer := 34;
  constant VDATA_END   : integer := 514;
  constant VLINE_END   : integer := 524;

  constant H_EIGHTH  : integer := 640 / 8;
  constant H_HALF    : integer := 640 / 2;
  constant H_QUARTER : integer := 640 / 4;

  constant V_EIGHTH  : integer := 480 / 8;
  constant V_HALF    : integer := 480 / 2;
  constant V_QUARTER : integer := 480 / 4;

  -- Signals
  signal hcount : integer range 0 to HLINE_END := 0;
  signal vcount : integer range 0 to VLINE_END := 0;
  signal data   : std_logic_vector (2 downto 0);

  signal vga_clk : std_logic := '0';

  signal should_reset_vcount : boolean;
  signal should_reset_hcount : boolean;
  signal should_output_data  : boolean;

  signal square_x           : integer range 0 to HLINE_END := 0;
  signal square_y           : integer range 0 to VLINE_END := 0;
  signal square_size        : integer                      := 50;
  signal should_draw_square : boolean;

begin
  -- Middle of the screen;
  square_x <= HDATA_BEGIN + H_HALF - square_size/2;
  square_y <= VDATA_BEGIN + V_HALF - square_size/2;

  square(hcount, vcount, square_x, square_y, square_size, should_draw_square);

  should_reset_vcount <= vcount = VLINE_END;
  should_reset_hcount <= hcount = HLINE_END;
  should_output_data  <= (hcount >= HDATA_BEGIN) and (hcount < HDATA_END) and (vcount >= VDATA_BEGIN) and (vcount < VDATA_END);

  hsync <= '1' when hcount > HSYNC_END else '0';
  vsync <= '1' when vcount > VSYNC_END else '0';
  rgb   <= data when should_output_data else (others => '0');

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
      if (should_reset_hcount) then
        hcount <= 0;
      else
        hcount <= hcount + 1;
      end if;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk) and should_reset_hcount) then
      if (should_reset_vcount) then
        vcount <= 0;
      else
        vcount <= vcount + 1;
      end if;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (should_draw_square) then
        data <= COLOR_BLUE;
      else
        data <= COLOR_BLACK;
      end if;
    end if;
  end process;
end architecture;