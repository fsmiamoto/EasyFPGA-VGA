library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;

package SnakeUtils is
  constant MAX_SNAKE_SIZE      : integer := 32;
  constant SNAKE_SEGMENT_SIZE  : integer := 20; -- In pixels
  constant SNAKE_SPEED_DIVIDER : integer := 100_000;
  constant APPLE_SIZE          : integer := 20;

  -- Limits to where the apple can be generated
  constant UPPER_LIMIT_X : integer := HDATA_END - APPLE_SIZE;
  constant LOWER_LIMIT_X : integer := HDATA_BEGIN;
  constant UPPER_LIMIT_Y : integer := VDATA_END - APPLE_SIZE;
  constant LOWER_LIMIT_Y : integer := VDATA_BEGIN;

  type SQUARES_POS_ARRAY is array (0 to MAX_SNAKE_SIZE - 1) of integer;
end package;