library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.SnakeUtils.all;

entity Snake is
  port (
    vga_clk : in std_logic;
    clk_snake_movement : in std_logic;
    hcur, vcur : inout SQUARES_POS_ARRAY;
    hpos, vpos : in integer;
    snake_size : in integer;
    block_size : in integer;
	 snake_colision : out boolean;
    should_draw : inout boolean
  );
end Snake;

architecture rtl of Snake is
  signal snake_index : integer := 1;
  signal snake_segment : integer := 1;
  signal found : integer := 0;
begin
  process (vga_clk)
  begin
    if (rising_edge(vga_clk)) then
      for snake_index in 0 to MAX_SNAKE_SIZE-1 loop
        should_draw <= (hcur(snake_index) > hpos) and (hcur(snake_index) < hpos + block_size) and (vcur(snake_index) > vpos) and (vcur(snake_index) < vpos + block_size);
		  if(should_draw) then
		    found <= found + 1;
			 if(found > 1) then
			   snake_colision <= false;
			 end if;
		  end if;
		end loop;
    end if;
  end process;

  process (clk_snake_movement)
  begin
    if (rising_edge(clk_snake_movement)) then
      for snake_segment in 1 to MAX_SNAKE_SIZE-1 loop
        if (snake_segment <= snake_size - 1) then
          hcur(snake_segment - 1) <= hcur(snake_segment);
          vcur(snake_segment - 1) <= vcur(snake_segment);
		  end if;
      end loop;
    end if;
  end process;
end rtl;