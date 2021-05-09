library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;
use work.PS2Utils.all;

entity Game is
  port (
    clk      : in std_logic; -- Pin 23, 50MHz from the onboard oscilator.
    rgb      : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync    : out std_logic; -- Pin 101
    vsync    : out std_logic; -- Pin 103
    up       : in std_logic;
    down     : in std_logic;
    left     : in std_logic;
    right    : in std_logic;
    ps2_data : in std_logic;
    ps2_clk  : in std_logic
  );
end entity Game;

architecture rtl of Game is
  constant SQUARE_SIZE  : integer := 40; -- In pixels
  constant SQUARE_SPEED : integer := 100_000;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync  : std_logic;
  signal hpos, vpos            : integer;

  signal square_x           : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal square_y           : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
  signal square_speed_count : integer range 0 to SQUARE_SPEED        := 0;

  signal move_square_en     : std_logic;
  signal should_move_square : boolean;

  signal should_move_up    : std_logic;
  signal should_move_down  : std_logic;
  signal should_move_left  : std_logic;
  signal should_move_right : std_logic;
  signal should_reset      : std_logic;

  signal is_dead : boolean := false;

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

  component Controller is
    port (
      clk               : in std_logic;
      ps2_data          : in std_logic;
      ps2_clk           : in std_logic;
      up                : in std_logic;
      left              : in std_logic;
      right             : in std_logic;
      down              : in std_logic;
      should_move_left  : out std_logic;
      should_move_right : out std_logic;
      should_move_down  : out std_logic;
      should_move_up    : out std_logic;
      should_reset      : out std_logic
    );
  end component;
begin
  vga : VgaController port map(
    clk     => vga_clk,
    rgb_in  => rgb_input,
    rgb_out => rgb_output,
    hsync   => vga_hsync,
    vsync   => vga_vsync,
    hpos    => hpos,
    vpos    => vpos
  );

  c : Controller port map(
    clk               => vga_clk,
    ps2_data          => ps2_data,
    ps2_clk           => ps2_clk,
    up                => up,
    left              => left,
    right             => right,
    down              => down,
    should_move_down  => should_move_down,
    should_move_up    => should_move_up,
    should_move_left  => should_move_left,
    should_move_right => should_move_right,
    should_reset      => should_reset
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  move_square_en     <= should_move_down xor should_move_left xor should_move_right xor should_move_up;
  should_move_square <= square_speed_count = SQUARE_SPEED;

  Square(hpos, vpos, square_x, square_y, SQUARE_SIZE, should_draw_square);

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
      if (is_dead) then
        rgb_input <= COLOR_RED;
      elsif (should_draw_square) then
        rgb_input <= COLOR_GREEN;
      else
        rgb_input <= COLOR_BLACK;
      end if;
    end if;
  end process;

  process (vga_clk, should_reset)
  begin
    if (rising_edge(vga_clk)) then
      if (move_square_en = '1') then
        if should_move_square then
          square_speed_count <= 0;
        else
          square_speed_count <= square_speed_count + 1;
        end if;
      else
        square_speed_count <= 0;
      end if;

      if (should_reset = '1') then
        square_x <= HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
        square_y <= VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
        is_dead  <= false;
      elsif (should_move_square) then
        if (should_move_up = '1') then
          if (square_y <= VDATA_BEGIN) then
            is_dead      <= true;
          else
            square_y <= square_y - 1;
          end if;
        end if;

        if (should_move_down = '1') then
          if (square_y >= VDATA_END - SQUARE_SIZE) then
            is_dead <= true;
          else
            square_y <= square_y + 1;
          end if;
        end if;

        if (should_move_left = '1') then
          if (square_x <= HDATA_BEGIN) then
            is_dead      <= true;
          else
            square_x <= square_x - 1;
          end if;
        end if;

        if (should_move_right = '1') then
          if (square_x >= HDATA_END - SQUARE_SIZE) then
            is_dead <= true;
          else
            square_x <= square_x + 1;
          end if;
        end if;
      end if;

    end if;
  end process;
end architecture;