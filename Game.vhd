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
  constant SQUARE_SIZE        : integer := 20; -- In pixels
  constant APPLE_SIZE         : integer := 20;
  signal SQUARE_SPEED_DIVIDER : integer := 150_000;

  constant START_STATE   : integer := 0;
  constant PLAYING_STATE : integer := 1;
  constant DEAD_STATE    : integer := 2;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync  : std_logic;
  signal hpos, vpos            : integer;

  -- The horizontal random sequence generation will be done in a different pace
  -- while the horizontal one will follow the VGA clock, leading to a greater randomness feeling
  signal clk_x : std_logic;

  signal square_x           : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal square_y           : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
  signal square_speed_count : integer                                := 0;

  signal apple_x : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_QUARTER;
  signal apple_y : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_QUARTER;

  signal random_x : integer;
  signal random_y : integer;

  signal up_debounced    : std_logic;
  signal down_debounced  : std_logic;
  signal left_debounced  : std_logic;
  signal right_debounced : std_logic;

  signal is_square_out_of_bounds : boolean;
  signal should_move_square      : boolean;
  signal has_key_pressed         : std_logic;

  signal should_move_up    : std_logic;
  signal should_move_down  : std_logic;
  signal should_move_left  : std_logic;
  signal should_move_right : std_logic;
  signal should_reset      : std_logic;

  signal state : integer range 0 to 2 := START_STATE;

  signal should_draw_square : boolean;
  signal should_draw_apple  : boolean;

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

  component RandInt is
    port (
      clk         : in std_logic;
      upper_limit : in integer;
      lower_limit : in integer;
      rand_int    : out integer
    );
  end component;

  component ClockDivider is
    generic (
      divide_by : integer := 1E6
    );
    port (
      clk_in  : in std_logic;
      clk_out : out std_logic
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

  clk_divider_x : ClockDivider
  generic map(
    divide_by => 5
  )
  port map(
    clk_in  => vga_clk,
    clk_out => clk_x
  );

  rand_x : RandInt port map(
    clk         => clk_x,
    upper_limit => 700, -- TODO: Investigate why a magic number is needed
    lower_limit => HDATA_BEGIN,
    rand_int    => random_x
  );

  rand_y : RandInt port map(
    clk         => vga_clk,
    upper_limit => 400, -- TODO: Investigate why a magic number is needed
    lower_limit => VDATA_BEGIN,
    rand_int    => random_y
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  should_move_square <= square_speed_count = SQUARE_SPEED_DIVIDER;
  has_key_pressed    <= should_move_down xor should_move_left xor should_move_right xor should_move_up;
  is_square_out_of_bounds <= square_y <= VDATA_BEGIN or square_y >= VDATA_END - SQUARE_SIZE or square_x <= HDATA_BEGIN or square_x >= HDATA_END - SQUARE_SIZE;

  Square(hpos, vpos, square_x, square_y, SQUARE_SIZE, should_draw_square);
  Square(hpos, vpos, apple_x, apple_y, APPLE_SIZE, should_draw_apple);

  -- We need 25MHz for the VGA so we divide the input clock by 2
  process (clk)
  begin
    if (rising_edge(clk)) then
      vga_clk <= not vga_clk;
    end if;
  end process;

  -- Apple position
  process (vga_clk, should_draw_square, should_draw_apple, should_reset)
  begin
    if (falling_edge(vga_clk)) then
      if (should_reset = '1') then
        -- Resetting the game or collision between square and apple
        apple_y              <= random_y;
        apple_x              <= random_x;
        SQUARE_SPEED_DIVIDER <= 150_000;
      elsif (should_draw_square and should_draw_apple) then
        -- Collision between square and apple
        apple_y              <= random_y;
        apple_x              <= random_x;
        SQUARE_SPEED_DIVIDER <= SQUARE_SPEED_DIVIDER - 5000;
      end if;
    end if;
  end process;

  -- VGA Colors
  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (state = DEAD_STATE) then
        rgb_input <= COLOR_RED;
      elsif (state = START_STATE) then
        rgb_input <= COLOR_BLUE;
      elsif (state = PLAYING_STATE) then
        if (should_draw_square and should_draw_apple) then
          rgb_input <= COLOR_GREEN;
        elsif (should_draw_square) then
          rgb_input <= COLOR_GREEN;
        elsif (should_draw_apple) then
          rgb_input <= COLOR_RED;
        else
          rgb_input <= COLOR_BLACK;
        end if;
      end if;
    end if;
  end process;

  -- State machine
  process (vga_clk, is_square_out_of_bounds, has_key_pressed, should_reset)
  begin
    if (rising_edge(clk)) then
      if (state = START_STATE) then
        if (has_key_pressed = '1') then
          state <= PLAYING_STATE;
        end if;
      elsif (state = PLAYING_STATE) then
        if (is_square_out_of_bounds) then
          state <= DEAD_STATE;
        elsif (should_reset = '1') then
          state <= START_STATE;
        end if;
      elsif (state = DEAD_STATE) then
        if (should_reset = '1') then
          state <= START_STATE;
        end if;
      end if;
    end if;
  end process;

  -- Square speed divider
  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (state = PLAYING_STATE) then
        if (has_key_pressed = '1') then
          if (should_move_square) then
            square_speed_count <= 0;
          else
            square_speed_count <= square_speed_count + 1;
          end if;
        else
          square_speed_count <= 0;
        end if;
      end if;
    end if;
  end process;

  -- Square movement
  process (vga_clk, should_reset, state)
  begin
    if (rising_edge(clk)) then
      if (should_reset = '1') then
        square_x <= HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
        square_y <= VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
      elsif (should_move_square) then
        if (should_move_up = '1') then
          square_y <= square_y - 1;
        end if;

        if (should_move_down = '1') then
          square_y <= square_y + 1;
        end if;

        if (should_move_left = '1') then
          square_x <= square_x - 1;
        end if;

        if (should_move_right = '1') then
          square_x <= square_x + 1;
        end if;
      end if;
    end if;
  end process;
end architecture;