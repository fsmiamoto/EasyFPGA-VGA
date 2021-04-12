library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_utils.all;

entity Game is
  port (
    clk   : in std_logic; -- Pin 23
    rgb   : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync : out std_logic; -- Pin 101
    vsync : out std_logic; -- Pin 103
    up    : in std_logic;
    down  : in std_logic;
    left  : in std_logic;
    right : in std_logic
  );
end entity Game;

architecture rtl of Game is
  constant COLOR_WHITE  : std_logic_vector := "111";
  constant COLOR_YELLOW : std_logic_vector := "110";
  constant COLOR_PURPLE : std_logic_vector := "101";
  constant COLOR_RED    : std_logic_vector := "100";
  constant COLOR_WATER  : std_logic_vector := "011";
  constant COLOR_GREEN  : std_logic_vector := "010";
  constant COLOR_BLUE   : std_logic_vector := "001";
  constant COLOR_BLACK  : std_logic_vector := "000";

  constant HDATA_BEGIN : integer := 143;
  constant H_EIGHTH    : integer := 640 / 8;
  constant H_HALF      : integer := 640 / 2;
  constant H_QUARTER   : integer := 640 / 4;

  constant VDATA_BEGIN : integer := 34;
  constant VDATA_END   : integer := 514;
  constant V_EIGHTH    : integer := 480 / 8;
  constant V_HALF      : integer := 480 / 2;
  constant V_QUARTER   : integer := 480 / 4;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync  : std_logic;
  signal hpos, vpos            : integer;

  signal square_size : integer := 50;
  signal square_x    : integer := HDATA_BEGIN + H_HALF - square_size/2;
  signal square_y    : integer := VDATA_BEGIN + V_HALF - square_size/2;

  signal should_draw_square : boolean;

  component VgaController is
    port (
      clk     : in std_logic;
      rgb_in  : in std_logic_vector (2 downto 0);
      rgb_out : out std_logic_vector (2 downto 0);
      hsync   : out std_logic;
      vsync   : out std_logic;
      hpos    : out integer;
      vpos    : out integer
    );
  end component;
begin
  controller : VgaController port map(
    clk     => vga_clk,
    rgb_in  => rgb_input,
    rgb_out => rgb_output,
    hsync   => vga_hsync,
    vsync   => vga_vsync,
    hpos    => hpos,
    vpos    => vpos
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  Square(hpos, vpos, square_x, square_y, square_size, should_draw_square);

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
      if (should_draw_square) then
        rgb_input <= COLOR_RED;
      else
        rgb_input <= COLOR_WATER;
      end if;
    end if;

    if (up = '0') then
      square_y <= VDATA_BEGIN + V_QUARTER;
    end if;
    if (down = '0') then
      square_y <= VDATA_BEGIN + V_HALF + V_QUARTER;
    end if;
    if (left = '0') then
      square_x <= HDATA_BEGIN + H_QUARTER;
    end if;
    if (right = '0') then
      square_x <= HDATA_BEGIN + H_HALF + H_QUARTER;
    end if;
  end process;
end architecture;