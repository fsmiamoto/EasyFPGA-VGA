library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;

entity Game is
  port (
    clk : in std_logic; -- Pin 23, 50MHz from the onboard oscilator.
    rgb : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync : out std_logic; -- Pin 101
    vsync : out std_logic; -- Pin 103
    up : in std_logic;
    down : in std_logic;
    left : in std_logic;
    right : in std_logic
  );
end entity Game;

architecture rtl of Game is
  constant SQUARE_SIZE : integer := 30; -- In pixels
  constant SQUARE_SPEED : integer := 100_000;
  constant APPLE_SIZE : integer := 30;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal vga_hsync, vga_vsync : std_logic;
  signal hpos, vpos : integer;
  signal apple_x : integer;
  signal apple_y : integer;
  signal trigger_random_apple_pos : std_logic := '1'; -- Initial trigger to generate a random apple position

  -- These three signals are used for the apple random position generation
  signal seed : integer := 1; -- random seed
  signal counter_game_start : integer := 1; -- measures the number of clock cycles until the game begins
  signal max_integer : integer := 2147483647; -- 2^31 - 1

  -- The horizontal random sequence generation will be done in a different pace
  -- while the horizontal one will follow the VGA clock, leading to a greater randomness feeling
  signal clk_x : std_logic;

  signal square_x : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal square_y : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;
  signal square_speed_count : integer range 0 to SQUARE_SPEED := 0;

  signal up_debounced : std_logic;
  signal down_debounced : std_logic;
  signal left_debounced : std_logic;
  signal right_debounced : std_logic;

  signal move_square_en : std_logic;
  signal should_move_square : boolean;

  signal should_draw_square : boolean;
  signal should_draw_apple : boolean;

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

  component Debounce is
    port (
      i_Clk : in std_logic;
      i_Switch : in std_logic;
      o_Switch : out std_logic
    );
  end component;

  component RandInt is
    port (
      clk : in std_logic;
      trigger : in std_logic;
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

begin
  controller : VgaController port map(
    clk => vga_clk,
    rgb_in => rgb_input,
    rgb_out => rgb_output,
    hsync => vga_hsync,
    vsync => vga_vsync,
    hpos => hpos,
    vpos => vpos
  );

  debounce_up_switch : Debounce port map(
    i_Clk => vga_clk,
    i_Switch => up,
    o_Switch => up_debounced
  );

  debounce_down_switch : Debounce port map(
    i_Clk => vga_clk,
    i_Switch => down,
    o_Switch => down_debounced
  );

  debounce_left_switch : Debounce port map(
    i_Clk => vga_clk,
    i_Switch => left,
    o_Switch => left_debounced
  );

  debounce_right_switch : Debounce port map(
    i_Clk => vga_clk,
    i_Switch => right,
    o_Switch => right_debounced
  );

  clk_divider_x : ClockDivider
  generic map(
    divide_by => 5
  )
  port map(
    clk_in => vga_clk,
    clk_out => clk_x
  );

  apple_rand_x : RandInt port map(
    clk => clk_x,
    trigger => trigger_random_apple_pos,
    seed => seed,
    upper_limit => HDATA_END,
    lower_limit => HDATA_BEGIN,
    rand_int => apple_x
  );

  apple_rand_y : RandInt port map(
    clk => vga_clk,
    trigger => trigger_random_apple_pos,
    seed => seed,
    upper_limit => VDATA_END,
    lower_limit => VDATA_BEGIN,
    rand_int => apple_y
  );

  rgb <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  move_square_en <= up_debounced xor down_debounced xor left_debounced xor right_debounced;
  should_move_square <= square_speed_count = SQUARE_SPEED;

  Square(hpos, vpos, square_x, square_y, SQUARE_SIZE, should_draw_square);
  Square(hpos, vpos, apple_x, apple_y, APPLE_SIZE, should_draw_apple);

  signal snake_size : integer := 1;

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
  end process;

  process (vga_clk)
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
          counter_game_start = 1;
        end if;
        seed <= upper_limit - (max_integer_value - counter_game_start)/(max_integer_value - 1) * (upper_limit - lower_limit);
        square_speed_count <= 0;
      end if;

      if (should_move_square) then
        if (up_debounced = '0') then
          if (square_y <= VDATA_BEGIN) then
            square_y <= VDATA_BEGIN;
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
            square_x <= HDATA_BEGIN;
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

        if (square_x = apple_x and square_y = apple_y) then
          trigger_random_apple_pos <= '1';
          snake_size <= snake_size + 1
            else
            trigger_random_apple_pos <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture;