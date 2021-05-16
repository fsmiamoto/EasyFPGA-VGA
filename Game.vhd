library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;
use work.PS2Utils.all;

entity Game is
  port (
    clk : in std_logic; -- Pin 23, 50MHz from the onboard oscilator.
    rgb : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync : out std_logic; -- Pin 101
    vsync : out std_logic; -- Pin 103
    up : in std_logic;
    down : in std_logic;
    left : in std_logic;
    right : in std_logic;
    ps2_data : in std_logic;
    ps2_clk : in std_logic
  );
end entity Game;

architecture rtl of Game is
  constant SQUARE_SIZE : integer := 20; -- In pixels
  constant SQUARE_SPEED : integer := 100_000;
  constant APPLE_SIZE : integer := 20;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync : std_logic;
  signal hpos, vpos : integer;
  signal trigger_random_apple_pos : std_logic := '1'; -- Initial trigger to generate a random apple position

  constant upper_limit_x : integer := HDATA_END - APPLE_SIZE;
  constant lower_limit_x : integer := HDATA_BEGIN;

  constant upper_limit_y : integer := VDATA_END - APPLE_SIZE;
  constant lower_limit_y : integer := VDATA_BEGIN;

  -- These three signals are used for the apple random position generation
  signal seed_x : integer := 1; -- random horizontal seed
  signal seed_y : integer := 1; -- random vertical seed
  signal counter_game_start : integer := 1; -- measures the number of clock cycles until the game begins
  signal max_integer_value : integer := 2147483647; -- 2^31 - 1

  -- The horizontal random sequence generation will be done in a different pace
  -- while the horizontal one will follow the VGA clock, leading to a greater randomness feeling
  signal clk_x : std_logic;

  signal snake_head_x : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal snake_head_y : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
  signal square_speed_count : integer range 0 to SQUARE_SPEED := 0;

  signal apple_x : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_QUARTER;
  signal apple_y : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_QUARTER;

  signal random_x : integer;
  signal random_y : integer;

  signal snake_size : integer := 1;

  signal up_debounced : std_logic;
  signal down_debounced : std_logic;
  signal left_debounced : std_logic;
  signal right_debounced : std_logic;

  signal move_square_en : std_logic;
  signal should_move_square : boolean;

  signal should_move_up : std_logic;
  signal should_move_down : std_logic;
  signal should_move_left : std_logic;
  signal should_move_right : std_logic;
  signal should_reset : std_logic;

  signal is_dead : boolean := false;

  signal should_draw_snake : boolean;
  signal should_draw_square : boolean;
  signal should_draw_apple : boolean;

  signal snake_size : integer := 1;

  component VgaController is
    port (
      clk : in std_logic;
      rgb_in : in std_logic_vector (2 downto 0);
      rgb_out : out std_logic_vector (2 downto 0);
      hsync : out std_logic;
      vsync : out std_logic;
      hpos : out integer;
      vpos : out integer
    );
  end component;

  component Controller is
    port (
      clk : in std_logic;
      ps2_data : in std_logic;
      ps2_clk : in std_logic;
      up : in std_logic;
      left : in std_logic;
      right : in std_logic;
      down : in std_logic;
      should_move_left : out std_logic;
      should_move_right : out std_logic;
      should_move_down : out std_logic;
      should_move_up : out std_logic;
      should_reset : out std_logic
    );
  end component;

  component RandInt is
    port (
      clk : in std_logic;
      seed : in integer;
      upper_limit : in integer;
      lower_limit : in integer;
      rand_int : out integer
    );
  end component;

  component ClockDivider is
    generic (
      divide_by : integer := 1E6
    );
    port (
      clk_in : in std_logic;
      clk_out : out std_logic
    );
  end component;

  component Snake is
    port (
      clk : in std_logic;
      hcur, vcur : in integer;
      hpos, vpos : inout INT_ARRAY (MAX_SNAKE_SIZE to 0);
      snake_size : in integer;
      block_size : in integer;
      should_draw : out boolean
    );
  end component;

begin
  vga : VgaController port map(
    clk => vga_clk,
    rgb_in => rgb_input,
    rgb_out => rgb_output,
    hsync => vga_hsync,
    vsync => vga_vsync,
    hpos => hpos,
    vpos => vpos
  );

  c : Controller port map(
    clk => vga_clk,
    ps2_data => ps2_data,
    ps2_clk => ps2_clk,
    up => up,
    left => left,
    right => right,
    down => down,
    should_move_down => should_move_down,
    should_move_up => should_move_up,
    should_move_left => should_move_left,
    should_move_right => should_move_right,
    should_reset => should_reset
  );

  clk_divider_x : ClockDivider
  generic map(
    divide_by => 5
  )
  port map(
    clk_in => vga_clk,
    clk_out => clk_x
  );

  rand_x : RandInt port map(
    clk => clk_x,
    seed => seed_x,
    upper_limit => upper_limit_x,
    lower_limit => lower_limit_x,
    rand_int => random_x
  );

  rand_y : RandInt port map(
    clk => vga_clk,
    seed => seed_y,
    upper_limit => upper_limit_y,
    lower_limit => lower_limit_y,
    rand_int => random_y
  );

  snake : Snake port map(
    clk => vga_clk,
    hcur = >,
    vcur = >,
    hpos => hpos,
    vpos => vpos,
    snake_size => snake_size,
    block_size => SQUARE_SIZE,
    should_draw => should_draw_snake
  );

  rgb <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  move_square_en <= should_move_down xor should_move_left xor should_move_right xor should_move_up;
  should_move_square <= square_speed_count = SQUARE_SPEED;

  Square(hpos, vpos, snake_head_x, snake_head_y, SQUARE_SIZE, should_draw_square);
  Square(hpos, vpos, apple_x, apple_y, APPLE_SIZE, should_draw_apple);

  -- We need 25MHz for the VGA so we divide the input clock by 2
  process (clk)
  begin
    if (rising_edge(clk)) then
      vga_clk <= not vga_clk;
    end if;
  end process;

  process (vga_clk, should_draw_square, should_draw_apple)
  begin
    if (rising_edge(vga_clk)) then
      -- Collision, update apple position
      if (should_draw_square and should_draw_apple) then
        apple_y <= random_y;
        apple_x <= random_x;
      end if;
    end if;
  end process;

  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      if (is_dead) then
        rgb_input <= COLOR_RED;
      elsif (should_draw_square and should_draw_apple) then
        rgb_input <= COLOR_GREEN;
      elsif (should_draw_square) then
        rgb_input <= COLOR_GREEN;
      elsif (should_draw_apple) then
        rgb_input <= COLOR_RED;
      else
        rgb_input <= COLOR_BLACK;
      end if;
    end if;
  end process;

  process (vga_clk, should_reset)
  begin
    if (rising_edge(vga_clk)) then
      if (move_square_en = '1') then
        if (should_move_square) then
          square_speed_count <= 0;
        else
          square_speed_count <= square_speed_count + 1;
        end if;
      else
        counter_game_start <= counter_game_start + 1;
        if (counter_game_start = max_integer_value) then
          counter_game_start <= 1;
        end if;
        seed_x <= upper_limit_x - (max_integer_value - counter_game_start)/(max_integer_value - 1) * (upper_limit_x - lower_limit_x);
        seed_y <= upper_limit_y - (max_integer_value - counter_game_start)/(max_integer_value - 1) * (upper_limit_y - lower_limit_y);
        square_speed_count <= 0;
      end if;

      if (should_reset = '1') then
        snake_head_x <= HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
        snake_head_y <= VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
        is_dead <= false;
      elsif (should_move_square) then
        if (should_move_up = '1') then
          if (snake_head_y <= VDATA_BEGIN) then
            is_dead <= true;
          else
            snake_head_y <= snake_head_y - 1;
          end if;
        end if;

        if (should_move_down = '1') then
          if (snake_head_y >= VDATA_END - SQUARE_SIZE) then
            is_dead <= true;
          else
            snake_head_y <= snake_head_y + 1;
          end if;
        end if;

        if (should_move_left = '1') then
          if (snake_head_x <= HDATA_BEGIN) then
            is_dead <= true;
          else
            snake_head_x <= snake_head_x - 1;
          end if;
        end if;

        if (should_move_right = '1') then
          if (snake_head_x >= HDATA_END - SQUARE_SIZE) then
            is_dead <= true;
          else
            snake_head_x <= snake_head_x + 1;
          end if;
        end if;

        if (snake_head_x = apple_x and snake_head_y = apple_y) then
          trigger_random_apple_pos <= '1';
          snake_size <= snake_size + 1;
        else
          trigger_random_apple_pos <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture;