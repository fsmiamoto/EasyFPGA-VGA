library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;

entity Game is
  port (
    clk   : in std_logic; -- Pin 23, 50MHz from the onboard oscilator.
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
  constant SQUARE_SIZE  : integer := 30; -- In pixels
  constant SQUARE_SPEED : integer := 100_000;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync  : std_logic;
  signal hpos, vpos            : integer;

  signal square_x           : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal square_y           : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
  signal square_speed_count : integer range 0 to SQUARE_SPEED        := 0;

  signal up_debounced    : std_logic;
  signal down_debounced  : std_logic;
  signal left_debounced  : std_logic;
  signal right_debounced : std_logic;

  signal move_square_en     : std_logic;
  signal should_move_square : boolean;

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

  component Debounce is
    port (
      i_Clk    : in std_logic;
      i_Switch : in std_logic;
      o_Switch : out std_logic
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

  debounce_up_switch : Debounce port map(
    i_Clk    => vga_clk,
    i_Switch => up,
    o_Switch => up_debounced
  );

  debounce_down_switch : Debounce port map(
    i_Clk    => vga_clk,
    i_Switch => down,
    o_Switch => down_debounced
  );

  debounce_left_switch : Debounce port map(
    i_Clk    => vga_clk,
    i_Switch => left,
    o_Switch => left_debounced
  );

  debounce_right_switch : Debounce port map(
    i_Clk    => vga_clk,
    i_Switch => right,
    o_Switch => right_debounced
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  move_square_en     <= up_debounced xor down_debounced xor left_debounced xor right_debounced;
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
      if (should_draw_square) then
        rgb_input <= COLOR_GREEN;
      else
        rgb_input <= COLOR_BLACK;
      end if;
    end if;
  end process;

  process (vga_clk)
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

      if (should_move_square) then
        if (up_debounced = '0') then
          if (square_y <= VDATA_BEGIN) then
            square_y     <= VDATA_BEGIN;
          else
            square_y <= square_y - 1;
          end if;
        end if;

        if (down_debounced = '0') then
          if (square_y >= VDATA_END - SQUARE_SIZE) then
            square_y <= VDATA_END - SQUARE_SIZE;
          else
            square_y <= square_y + 1;
          end if;
        end if;

        if (left_debounced = '0') then
          if (square_x <= HDATA_BEGIN) then
            square_x     <= HDATA_BEGIN;
          else
            square_x <= square_x - 1;
          end if;
        end if;

        if (right_debounced = '0') then
          if (square_x >= HDATA_END - SQUARE_SIZE) then
            square_x <= HDATA_END - SQUARE_SIZE;
          else
            square_x <= square_x + 1;
          end if;
        end if;
      end if;

    end if;
  end process;
end architecture;