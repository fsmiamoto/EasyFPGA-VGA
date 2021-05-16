library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generates a pseudo random integer
entity RandInt is
  port (
    clk : in std_logic;
    seed : in integer;
    upper_limit : in integer;
    lower_limit : in integer;
    rand_int : out integer
  );
end RandInt;

architecture rtl of RandInt is
  constant step : integer := seed;
  signal rand_int_sig : integer := lower_limit;
begin
  process (clk)
  begin
    if (rising_edge(clk)) then
      if ((rand_int_sig + step) >= upper_limit) then
        rand_int_sig <= lower_limit;
      else
        rand_int_sig <= rand_int_sig + step;
      end if;
    end if;
  end process;

  rand_int <= rand_int_sig;
end rtl;