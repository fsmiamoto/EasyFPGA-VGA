library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.PS2Utils.all;

-- Controller receives keyboard and push-button inputs and decides outputs
-- the desired direction.
entity Controller is
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
end entity;

architecture rtl of Controller is
  signal up_debounced    : std_logic;
  signal down_debounced  : std_logic;
  signal left_debounced  : std_logic;
  signal right_debounced : std_logic;

  signal ps2_has_new_code : std_logic;
  signal ps2_code         : std_logic_vector(7 downto 0);

  component Debounce is
    port (
      i_Clk    : in std_logic;
      i_Switch : in std_logic;
      o_Switch : out std_logic
    );
  end component;

  component PS2Keyboard is
    port (
      sys_clk      : in std_logic;
      clk          : in std_logic;
      data         : in std_logic;
      code         : out std_logic_vector(7 downto 0);
      has_new_code : out std_logic
    );
  end component;

begin
  keyboard : PS2Keyboard port map(
    sys_clk      => clk,
    clk          => ps2_clk,
    data         => ps2_data,
    code         => ps2_code,
    has_new_code => ps2_has_new_code
  );

  debounce_up_switch : Debounce port map(
    i_Clk    => clk,
    i_Switch => up,
    o_Switch => up_debounced
  );

  debounce_down_switch : Debounce port map(
    i_Clk    => clk,
    i_Switch => down,
    o_Switch => down_debounced
  );

  debounce_left_switch : Debounce port map(
    i_Clk    => clk,
    i_Switch => left,
    o_Switch => left_debounced
  );

  debounce_right_switch : Debounce port map(
    i_Clk    => clk,
    i_Switch => right,
    o_Switch => right_debounced
  );

  -- TODO: Review this
  -- Use WASD, HJKL or board buttons
  should_move_up    <= '1' when ps2_code = Key_W or ps2_code = Key_K else '0';
  should_move_left  <= '1' when ps2_code = Key_A or ps2_code = Key_H else '0';
  should_move_down  <= '1' when ps2_code = Key_S or ps2_code = Key_J else '0';
  should_move_right <= '1' when ps2_code = Key_D or ps2_code = Key_L else '0';
  should_reset      <= '1' when right_debounced = '0' else '0';
end architecture;