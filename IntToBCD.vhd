library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IntToBCD is
  port (
    number : in integer range 0 to 99;
    digit0 : out std_logic_vector (3 downto 0);
    digit1 : out std_logic_vector (3 downto 0)
  );
end IntToBCD;

architecture rtl of IntToBCD is
  signal pos0, pos1 : natural range 0 to 9;
begin
  convert : process (number, pos0, pos1)
  begin
    pos1   <= number/10;
    pos0   <= number mod 10;
    digit0 <= std_logic_vector(to_unsigned(pos0, digit0'LENGTH));
    digit1 <= std_logic_vector(to_unsigned(pos1, digit1'LENGTH));
  end process convert;
end rtl;