library ieee;
use ieee.std_logic_1164.all;

entity SevenSegDecoder is
  port (
    input  : in std_logic_vector (3 downto 0);
    output : out std_logic_vector (6 downto 0)
  );
end SevenSegDecoder;

architecture rtl of SevenSegDecoder is
begin
  --      0
  --     ---  
  --  5 |   | 1
  --     ---   <- 6
  --  4 |   | 2
  --     ---
  --      3

  with input select
    output <=
    "1111001" when "0001", --1
    "0100100" when "0010", --2
    "0110000" when "0011", --3
    "0011001" when "0100", --4
    "0010010" when "0101", --5
    "0000010" when "0110", --6
    "1111000" when "0111", --7
    "0000000" when "1000", --8
    "0010000" when "1001", --9
    "0001000" when "1010", --A
    "1111111" when "1011", -- 
    "1000110" when "1100", --C
    "1000111" when "1101", --L
    "1000001" when "1110", --U
    "1110111" when "1111", --_
    "1000000" when others; --0
end rtl;