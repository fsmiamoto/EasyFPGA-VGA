library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ClockDivider is
  generic (
    divide_by : integer := 1E6
  );
  port (
    clk_in  : in std_logic;
    clk_out : out std_logic
  );
end entity;

architecture rtl of ClockDivider is
  signal count  : integer range 0 to divide_by := 0;
  signal output : std_logic                    := '0';
begin
  process (clk_in)
  begin
    if (rising_edge(clk_in)) then
      if (count = divide_by) then
        output <= not output;
        count  <= 0;
      else
        count <= count + 1;
      end if;
    end if;
  end process;

  clk_out <= output;
end architecture;