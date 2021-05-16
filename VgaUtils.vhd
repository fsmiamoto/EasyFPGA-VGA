library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package VgaUtils is
  constant COLOR_WHITE : std_logic_vector := "111";
  constant COLOR_YELLOW : std_logic_vector := "110";
  constant COLOR_PURPLE : std_logic_vector := "101";
  constant COLOR_RED : std_logic_vector := "100";
  constant COLOR_WATER : std_logic_vector := "011";
  constant COLOR_GREEN : std_logic_vector := "010";
  constant COLOR_BLUE : std_logic_vector := "001";
  constant COLOR_BLACK : std_logic_vector := "000";

  -- Values for 640x480 resolution
  constant HSYNC_END : integer := 95;
  constant HDATA_BEGIN : integer := 143;
  constant HDATA_END : integer := 783;
  constant HLINE_END : integer := 799;

  constant VSYNC_END : integer := 1;
  constant VDATA_BEGIN : integer := 34;
  constant VDATA_END : integer := 514;
  constant VLINE_END : integer := 524;

  constant H_EIGHTH : integer := 640 / 8;
  constant H_HALF : integer := 640 / 2;
  constant H_QUARTER : integer := 640 / 4;

  constant V_EIGHTH : integer := 480 / 8;
  constant V_HALF : integer := 480 / 2;
  constant V_QUARTER : integer := 480 / 4;

  constant MAX_SNAKE_SIZE : integer := 31;

  procedure Square (
    signal hcur, vcur : in integer;
    signal hpos, vpos : in integer;
    constant size : in integer;
    signal should_draw : out boolean
  );

end package;

package body VgaUtils is
  procedure Square (
    signal hcur, vcur : in integer;
    signal hpos, vpos : in integer;
    constant size : in integer;
    signal should_draw : out boolean
  ) is
  begin
    should_draw <= hcur > hpos and hcur < (hpos + size) and vcur > vpos and vcur < (vpos + size);
  end Square;

  procedure Snake (
    signal hcur, vcur : in integer;
    signal snake_size : in integer;
    signal hpos, vpos : in type array(MAX_SNAKE_SIZE downto 0) of integer;
    signal snake_size : in integer;
    constant block_size : in integer;
    signal should_draw : out boolean
  ) is
  begin
    signal counter := integer = 1;
    for counter in 1 to snake_size loop
      snakeBody = ((hcur > hpos[counter] and hcur < hpos[counter] + block_size) and (vcur > vpos[counter] and vcur < vpos[counter] + block_size));
    end loop;
  end Snake;

end VgaUtils;