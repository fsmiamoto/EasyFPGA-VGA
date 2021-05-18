library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;
use work.PS2Utils.all;
use work.SnakeUtils.all;

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
  constant MAX_INTEGER_VALUE : integer := 2147483647; -- 2^31 - 1 
  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output    : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync     : std_logic;
  signal hpos, vpos               : integer;
  signal trigger_random_apple_pos : std_logic := '1'; -- Initial trigger to generate a random apple position

  -- These three signals are used for the apple random position generation
  signal seed_x             : integer; -- random horizontal seed
  signal seed_y             : integer; -- random vertical seed
  signal counter_game_start : integer range 1 to MAX_INTEGER_VALUE := 1; -- measures the number of clock cycles until the game begins

  -- The horizontal random sequence generation will be done in a different pace
  -- while the horizontal one will follow the VGA clock, leading to a greater randomness feeling
  signal clk_x : std_logic;

  signal snake_speed_count : integer range 0 to SNAKE_SPEED_DIVIDER := 0;

  signal apple_x : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_QUARTER;
  signal apple_y : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_QUARTER;

  signal snake_segments_x : SQUARES_POS_ARRAY;
  signal snake_segments_y : SQUARES_POS_ARRAY;
  signal snake_size       : integer                                := 1;
  signal snake_head_x     : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SNAKE_SEGMENT_SIZE/2;
  signal snake_head_y     : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SNAKE_SEGMENT_SIZE/2;
  signal snake_colision   : boolean                                := false;

  signal clk_snake_movement : std_logic;
  signal random_x           : integer;
  signal random_y           : integer;
  signal load_seed          : std_logic;

  signal up_debounced    : std_logic;
  signal down_debounced  : std_logic;
  signal left_debounced  : std_logic;
  signal right_debounced : std_logic;

  signal move_snake_en     : std_logic;
  signal should_move_snake : boolean;

  signal should_move_up    : std_logic;
  signal should_move_down  : std_logic;
  signal should_move_left  : std_logic;
  signal should_move_right : std_logic;
  signal should_reset      : std_logic;

  -- States
  signal start   : boolean   := true;
  signal playing : std_logic := '0';
  signal is_dead : boolean   := false;

  signal should_draw_snake : boolean;
  signal should_draw_apple : boolean;

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
      seed        : in integer;
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

  component Snake is
    port (
      vga_clk            : in std_logic;
      clk_snake_movement : in std_logic;
      hcur, vcur         : inout SQUARES_POS_ARRAY;
      hpos, vpos         : in integer;
      snake_size         : in integer;
      block_size         : in integer;
      snake_colision     : out boolean;
      should_draw        : inout boolean
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

  -- Clock divider used to get a greater randomness feeling - The idea behind it is that the horizontal and the vertical sequences generation will happen in a different pace
  clk_divider_x : ClockDivider
  generic map(
    divide_by => 5
  )
  port map(
    clk_in  => vga_clk,
    clk_out => clk_x
  );

  seed_x <= UPPER_LIMIT_X - (MAX_INTEGER_VALUE - counter_game_start)/(MAX_INTEGER_VALUE - 1) * (UPPER_LIMIT_X - LOWER_LIMIT_X);
  seed_y <= UPPER_LIMIT_Y - (MAX_INTEGER_VALUE - counter_game_start)/(MAX_INTEGER_VALUE - 1) * (UPPER_LIMIT_Y - LOWER_LIMIT_Y);

  rand_x : RandInt port map(
    clk         => clk_x,
    seed        => seed_x,
    upper_limit => UPPER_LIMIT_X,
    lower_limit => LOWER_LIMIT_X,
    rand_int    => random_x
  );

  rand_y : RandInt port map(
    clk         => vga_clk,
    seed        => seed_y,
    upper_limit => UPPER_LIMIT_Y,
    lower_limit => LOWER_LIMIT_Y,
    rand_int    => random_y
  );

  snk : Snake port map(
    vga_clk            => vga_clk,
    clk_snake_movement => clk_snake_movement,
    hcur               => snake_segments_x,
    vcur               => snake_segments_y,
    hpos               => hpos,
    vpos               => vpos,
    snake_size         => snake_size,
    block_size         => SNAKE_SEGMENT_SIZE,
    snake_colision     => snake_colision,
    should_draw        => should_draw_snake
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  should_move_snake <= snake_speed_count = SNAKE_SPEED_DIVIDER;
  move_snake_en     <= should_move_down xor should_move_left xor should_move_right xor should_move_up;

  -- A square representing the apple
  Square(hpos, vpos, apple_x, apple_y, APPLE_SIZE, should_draw_apple);

  snake_segments_x(0) <= snake_head_x;
  snake_segments_y(0) <= snake_head_y;

  -- We need 25MHz for the VGA so we divide the input clock by 2
  process (clk)
  begin
    if (rising_edge(clk)) then
      vga_clk <= not vga_clk;
    end if;
  end process;

  process (vga_clk, move_snake_en, should_reset, snake_colision, snake_head_x, snake_head_y)
  begin
    if (rising_edge(vga_clk)) then
      if (move_snake_en = '1' and start = true) then
        is_dead <= false;
        playing <= '1';
        start   <= false;
      elsif ((snake_head_y <= VDATA_BEGIN or snake_head_y >= VDATA_END - SNAKE_SEGMENT_SIZE or snake_head_x <= HDATA_BEGIN or snake_head_x >= HDATA_END - SNAKE_SEGMENT_SIZE) or snake_colision) then
        is_dead <= true;
        playing <= '0';
        start   <= false;
      elsif (should_reset = '1') then
        is_dead <= false;
        playing <= '0';
        start   <= true;
      end if;
    end if;
  end process;

  process (vga_clk, start)
  begin
    if (rising_edge(vga_clk)) then
      if (start) then
        counter_game_start <= counter_game_start + 1;
      end if;
    end if;
  end process;

  process (vga_clk, should_draw_snake, should_draw_apple)
  begin
    if (should_draw_snake and should_draw_apple) then
      snake_size <= snake_size + 1;
      apple_y    <= random_y;
      apple_x    <= random_x;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (is_dead) then
        rgb_input <= COLOR_RED;
      elsif (should_draw_snake and should_draw_apple) then
        rgb_input <= COLOR_GREEN;
      elsif (should_draw_snake) then
        rgb_input <= COLOR_GREEN;
      elsif (should_draw_apple and not start) then
        rgb_input <= COLOR_RED;
      else
        rgb_input <= COLOR_BLACK;
      end if;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (move_snake_en = '1') then
        if (should_move_snake) then
          snake_speed_count <= 0;
        else
          snake_speed_count <= snake_speed_count + 1;
        end if;
      else
        snake_speed_count <= 0;
      end if;
    end if;
  end process;

  process (vga_clk, should_reset)
  begin
    if (rising_edge(clk)) then
      if (should_reset = '1') then
        snake_head_x <= HDATA_BEGIN + H_HALF - SNAKE_SEGMENT_SIZE/2;
        snake_head_y <= VDATA_BEGIN + V_HALF - SNAKE_SEGMENT_SIZE/2;
      elsif (should_move_snake) then
        if (should_move_up = '1') then
          snake_head_y <= snake_head_y - 1;
        end if;

        if (should_move_down = '1') then
          snake_head_y <= snake_head_y + 1;
        end if;

        if (should_move_left = '1') then
          snake_head_x <= snake_head_x - 1;
        end if;

        if (should_move_right = '1') then
          snake_head_x <= snake_head_x + 1;
        end if;
      end if;

    end if;
  end process;
end architecture;