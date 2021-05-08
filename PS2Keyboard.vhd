library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity PS2Keyboard is
  port (
    sys_clk      : in std_logic;
    clk          : in std_logic;
    data         : in std_logic;
    code         : out std_logic_vector(7 downto 0);
    has_new_code : out std_logic
  );
end entity;

architecture rtl of PS2Keyboard is
  constant MAX_COUNT : integer := 50E6/18E3;

  signal sync_clk   : std_logic;
  signal sync_data  : std_logic;
  signal word       : std_logic_vector(10 downto 0);
  signal valid      : std_logic;
  signal idle_count : integer range 0 to MAX_COUNT;
begin

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then
      sync_data <= data;
      sync_clk  <= clk;
    end if;
  end process;

  -- Shift in the `data` to `word`
  process (sync_clk)
  begin
    if (falling_edge(sync_clk)) then
      word <= data & word(10 downto 1);
    end if;
  end process;

  valid <= not
    word(0) and
    word(10) and
    (word(9) xor word(8) xor word(7) xor word(6) xor word(5) xor word(4) xor word(3) xor word(2) xor word(1));

  process (sys_clk)
  begin
    if (rising_edge(sys_clk)) then

      if (sync_clk = '0') then
        idle_count <= 0;
      elsif (idle_count /= MAX_COUNT) then
        idle_count <= idle_count + 1;
      end if;

      if (idle_count = MAX_COUNT and valid = '1') then
        code         <= word(8 downto 1);
        has_new_code <= '1';
      else
        has_new_code <= '0';
        code         <= (others => '0');
      end if;

    end if;
  end process;
end architecture;