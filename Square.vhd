library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package vga_utils is
  procedure Square (
    signal hcur, vcur  : in integer;
    signal hpos, vpos  : in integer;
    signal size        : in integer;
    signal should_draw : out boolean
  );
end package;

package body vga_utils is
  procedure Square (
    signal hcur, vcur  : in integer;
    signal hpos, vpos  : in integer;
    signal size        : in integer;
    signal should_draw : out boolean
  ) is
  begin
    should_draw <= hcur > hpos and hcur < (hpos + size) and vcur > vpos and vcur < (vpos + size);
  end Square;
end vga_utils;