library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Generates a pseudo random integer between upper_limit and lower_limit when the trigger is fired
entity RandInt is
  port (
    clk : in std_logic;
    trigger : in std_logic;
    upper_limit : in integer;
    lower_limit : in integer;
    rand_int : out integer
  );
end RandInt;

architecture rtl of RandInt is
  signal rand_int_sig : integer := lower_limit;
begin
  process (clk, trigger)
  begin
    if (rising_edge(clk)) then
      if ((rand_int_sig + 19) >= upper_limit) then
        rand_int_sig <= lower_limit + (rand_int_sig - upper_limit) + 25; -- 25 can be replaced by any number
      else
        rand_int_sig <= rand_int_sig + 19; -- 19 can be replaced by any number
      end if;
      if (trigger = '1') then
        rand_int <= rand_int_sig;
      end if;
    end if;
  end process;
end rtl;