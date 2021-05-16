library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;

entity Snake is
  port (
    clk : in std_logic;
    hcur, vcur : inout INT_ARRAY (MAX_SNAKE_SIZE to 0);
    hpos, vpos : in integer;
    snake_size : in integer;
    block_size : in integer;
    should_draw : out boolean
  );
end Snake;

architecture rtl of Snake is
  signal counter1 : integer := 1;
  signal counter2 : integer := 1;
begin
  process (clk)
  begin
    if (rising_edge(clk)) then
      for counter1 in 1 to snake_size loop
        should_draw <= (hcur(counter1) > hpos) and (hcur(counter1) < hpos + block_size) and (vcur(counter1) > vpos) and (vcur(counter1) < vpos + block_size);
      end loop;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      for counter2 in 1 to snake_size loop
        if (counter2 <= snake_size - 1) then
          hcur(counter2 - 1) <= hcur(counter2 - 1);
          vcur(counter2 - 1) <= vcur(counter2 - 1);
		  end if;
      end loop;
    end if;
  end process;
end rtl;